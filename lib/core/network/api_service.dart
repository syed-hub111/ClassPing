import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import '../../models/user_profile.dart';
import '../../models/student.dart';
import '../../models/tutor.dart';
import '../../models/class_model.dart';
import '../../models/academic_year.dart';
import '../../models/expected_opportunity.dart';
import '../../models/parent_dashboard_data.dart';
import '../../models/attendance_history_item.dart';
import '../../models/student_comparison_result.dart';
import '../../models/tutor_info.dart';
import '../../models/parent_notification.dart';

class BackendApiService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  // ignore: unused_field
  final FirebaseFunctions _functions;

  BackendApiService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  // ==========================================
  // Auth & Profile
  // ==========================================
  Future<UserProfile> getInitialUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user session found.');
    }

    // 0. Primary Administrator Check: admin@classping.com
    if (user.email == 'admin@classping.com') {
      try {
        final adminDoc = await _firestore.collection('admins').doc(user.uid).get();
        if (!adminDoc.exists) {
          await _firestore.collection('admins').doc(user.uid).set({
            'uid': user.uid,
            'name': user.displayName ?? 'Head Administrator',
            'email': user.email,
            'status': 'ACTIVE',
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      } catch (e) {
        debugPrint('Admin bootstrap error: $e');
      }

      final profile = UserProfile(
        uid: user.uid,
        role: 'ADMIN',
        accountStatus: 'ACTIVE',
        displayName: (user.displayName != null && user.displayName!.isNotEmpty)
            ? user.displayName!
            : 'Head Administrator',
        email: user.email ?? 'admin@classping.com',
        phoneNumber: user.phoneNumber,
      );
      try {
        await _firestore.collection('users').doc(user.uid).set(profile.toJson(), SetOptions(merge: true));
      } catch (_) {}
      return profile;
    }

    // 1. Authoritative check: admins/{uid}
    // If an active document exists in admins/{uid}, the user is definitively an Administrator.
    try {
      final adminDoc = await _firestore.collection('admins').doc(user.uid).get();
      if (adminDoc.exists) {
        final adminData = adminDoc.data() ?? {};
        final status = adminData['status']?.toString() ?? 'ACTIVE';
        if (status == 'ACTIVE') {
          final profile = UserProfile(
            uid: user.uid,
            role: 'ADMIN',
            accountStatus: status,
            displayName: adminData['name']?.toString() ?? user.displayName ?? 'Administrator',
            email: adminData['email']?.toString() ?? user.email,
            phoneNumber: user.phoneNumber,
          );
          // Ensure users/{uid} is synchronized with ADMIN role
          await _firestore.collection('users').doc(user.uid).set(profile.toJson(), SetOptions(merge: true));
          return profile;
        }
      }
    } catch (e) {
      debugPrint('Admin check error: $e');
    }

    // 2. Authoritative check: tutors/{uid}
    // If an active document exists in tutors/{uid}, the user is definitively a Tutor.
    try {
      var tutorDoc = await _firestore.collection('tutors').doc(user.uid).get();
      Map<String, dynamic>? tutorData;
      String? oldDocId;

      if (tutorDoc.exists) {
        tutorData = tutorDoc.data();
      } else if (user.email != null && user.email!.isNotEmpty) {
        // Tutor document not yet keyed by auth UID; check by email registered by Admin
        final normalizedEmail = user.email!.trim().toLowerCase();
        var querySnap = await _firestore
            .collection('tutors')
            .where('email', isEqualTo: normalizedEmail)
            .limit(1)
            .get();

        if (querySnap.docs.isEmpty) {
          // Check for legacy or typo prefix 'www.' in registered email
          querySnap = await _firestore
              .collection('tutors')
              .where('email', isEqualTo: 'www.$normalizedEmail')
              .limit(1)
              .get();
        }

        if (querySnap.docs.isNotEmpty) {
          final matchedDoc = querySnap.docs.first;
          oldDocId = matchedDoc.id;
          tutorData = Map<String, dynamic>.from(matchedDoc.data());
          // Prepare migrated document data for tutors/{user.uid}
          tutorData['uid'] = user.uid;
          tutorData['tutorUid'] = user.uid;
          tutorData['email'] = normalizedEmail;
          tutorData['updatedAt'] = FieldValue.serverTimestamp();

          // Write authoritative tutor record under tutors/{user.uid}
          await _firestore.collection('tutors').doc(user.uid).set(tutorData, SetOptions(merge: true));

          // Clean up old placeholder document if different
          if (oldDocId != user.uid) {
            try {
              await _firestore.collection('tutors').doc(oldDocId).delete();
            } catch (delErr) {
              debugPrint('Note: Old tutor placeholder deletion skipped: $delErr');
            }
          }
        }
      }

      if (tutorData != null) {
        final status = tutorData['status']?.toString() ?? 'ACTIVE';
        if (status == 'ACTIVE') {
          final profile = UserProfile(
            uid: user.uid,
            role: 'TUTOR',
            accountStatus: status,
            displayName: tutorData['name']?.toString() ?? user.displayName ?? 'Tutor',
            email: tutorData['email']?.toString() ?? user.email,
            phoneNumber: tutorData['mobileNumber']?.toString() ?? user.phoneNumber,
          );
          // Ensure users/{uid} is synchronized with TUTOR role
          await _firestore.collection('users').doc(user.uid).set(profile.toJson(), SetOptions(merge: true));
          return profile;
        }
      }
    } catch (e) {
      debugPrint('Tutor check error: $e');
    }

    // 3. User document check in users/{uid}
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (doc.exists) {
      final data = Map<String, dynamic>.from(doc.data()!);
      data['uid'] = user.uid;
      // Normal users/{uid} document CANNOT grant ADMIN or TUTOR access.
      // Domain records in admins/{uid} and tutors/{uid} are authoritative.
      if (data['role'] == 'ADMIN' || data['role'] == 'TUTOR') {
        data['role'] = 'PARENT';
        await _firestore.collection('users').doc(user.uid).set({'role': 'PARENT'}, SetOptions(merge: true));
      }
      return UserProfile.fromJson(data);
    }

    // 4. Default initialization for newly authenticated users:
    // Strictly PARENT role. Absolutely no email heuristic or privilege escalation.
    final profile = UserProfile(
      uid: user.uid,
      role: 'PARENT',
      accountStatus: 'ACTIVE',
      displayName: (user.displayName != null && user.displayName!.isNotEmpty)
          ? user.displayName!
          : 'Parent',
      email: user.email,
      phoneNumber: user.phoneNumber,
    );

    await _firestore.collection('users').doc(user.uid).set(profile.toJson(), SetOptions(merge: true));
    return profile;
  }

  Future<Map<String, dynamic>> linkParentPhone() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user session found.');
    }
    final phone = user.phoneNumber;
    await _firestore.collection('users').doc(user.uid).set({
      'phoneNumber': phone,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return {'success': true, 'phoneNumber': phone};
  }

  // ==========================================
  // Authorization Guards
  // ==========================================
  Future<void> _verifyAdminAccess() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Unauthenticated: Access requires an authenticated session.');
    }
    if (user.email == 'admin@classping.com') return;

    final adminDoc = await _firestore.collection('admins').doc(user.uid).get();
    if (!adminDoc.exists) {
      throw StateError('Unauthorized: Active administrator privileges required.');
    }
    final status = adminDoc.data()?['status']?.toString() ?? 'ACTIVE';
    if (status != 'ACTIVE') {
      throw StateError('Unauthorized: Administrator account is not active.');
    }
  }

  Future<bool> _isTutorAuthorizedForClass(String tutorUid, String classId) async {
    final tutorDoc = await _firestore.collection('tutors').doc(tutorUid).get();
    if (tutorDoc.exists) {
      final rawList = tutorDoc.data()?['authorizedClassIds'];
      if (rawList is List && rawList.map((e) => e.toString()).contains(classId)) {
        return true;
      }
    }
    final classDoc = await _firestore.collection('classes').doc(classId).get();
    if (classDoc.exists) {
      final rawTutors = classDoc.data()?['authorizedTutorIds'];
      if (rawTutors is List && rawTutors.map((e) => e.toString()).contains(tutorUid)) {
        return true;
      }
    }
    return false;
  }

  Future<void> _verifyTutorClassAccess(String classId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Unauthenticated: Access requires an authenticated session.');
    }
    final isAuthorized = await _isTutorAuthorizedForClass(user.uid, classId);
    if (!isAuthorized) {
      throw StateError('Unauthorized: Tutor is not assigned to class $classId.');
    }
  }

  Future<void> _verifyParentStudentAccess(String studentId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Unauthenticated: Access requires an authenticated session.');
    }

    final studentDoc = await _firestore.collection('students').doc(studentId).get();
    if (!studentDoc.exists) {
      throw StateError('Student $studentId does not exist.');
    }

    final studentData = studentDoc.data()!;
    final parentIds = (studentData['parentIds'] as List?)?.map((e) => e.toString()).toList() ?? [];
    if (parentIds.contains(user.uid)) {
      return;
    }

    String? phone = user.phoneNumber;
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (userDoc.exists) {
      phone ??= userDoc.data()?['phoneNumber'] as String?;
    }

    final normalizedUserPhone = phone?.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final studentPhone = (studentData['parentMobileNumber'] as String?)?.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    if (normalizedUserPhone != null &&
        normalizedUserPhone.isNotEmpty &&
        studentPhone != null &&
        studentPhone.isNotEmpty) {
      if (studentPhone == normalizedUserPhone ||
          studentPhone.endsWith(normalizedUserPhone) ||
          normalizedUserPhone.endsWith(studentPhone)) {
        return;
      }
    }

    throw StateError('Unauthorized: Access denied. Student $studentId is not linked to your account.');
  }

  Future<void> _verifyParentNotificationAccess(String notificationId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Unauthenticated: Access requires an authenticated session.');
    }
    final notifDoc = await _firestore.collection('parentNotifications').doc(notificationId).get();
    if (!notifDoc.exists) {
      throw StateError('Notification $notificationId does not exist.');
    }
    final studentId = notifDoc.data()?['studentId']?.toString() ?? '';
    if (studentId.isEmpty) {
      throw StateError('Unauthorized: Invalid notification record.');
    }
    await _verifyParentStudentAccess(studentId);
  }

  // ==========================================
  // Admin
  // ==========================================
  Future<Map<String, dynamic>> adminGetDashboardStats() async {
    await _verifyAdminAccess();
    final studentsSnap = await _firestore.collection('students').get();
    final tutorsSnap = await _firestore.collection('tutors').get();
    final classesSnap = await _firestore.collection('classes').get();
    final opportunitiesSnap = await _firestore.collection('expectedAttendanceOpportunities').get();
    final academicYearsSnap = await _firestore.collection('academicYears').get();

    final activeStudents = studentsSnap.docs.where((d) => (d.data()['status'] ?? 'ACTIVE') == 'ACTIVE').length;
    final activeTutors = tutorsSnap.docs.where((d) => (d.data()['status'] ?? 'ACTIVE') == 'ACTIVE').length;
    final activeClasses = classesSnap.docs.where((d) => (d.data()['status'] ?? 'ACTIVE') == 'ACTIVE').length;
    final missedDeadlines = opportunitiesSnap.docs.where((d) => d.data()['status'] == 'MISSED_DEADLINE').length;
    final pendingSessions = opportunitiesSnap.docs.where((d) => d.data()['status'] == 'PENDING').length;

    String activeYearName = 'None';
    for (final doc in academicYearsSnap.docs) {
      if (doc.data()['status'] == 'ACTIVE') {
        activeYearName = doc.data()['name']?.toString() ?? 'Active Academic Year';
        break;
      }
    }

    return {
      'totalStudents': studentsSnap.docs.length,
      'activeStudents': activeStudents,
      'totalTutors': tutorsSnap.docs.length,
      'activeTutors': activeTutors,
      'totalClasses': classesSnap.docs.length,
      'activeClasses': activeClasses,
      'pendingOpportunities': pendingSessions,
      'pendingSessions': pendingSessions,
      'missedDeadlines': missedDeadlines,
      'activeAcademicYear': activeYearName,
    };
  }

  Future<List<Student>> adminGetStudents() async {
    await _verifyAdminAccess();
    final snap = await _firestore.collection('students').get();
    return snap.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      if (!data.containsKey('studentId') || data['studentId'] == null || (data['studentId'] as String).isEmpty) {
        data['studentId'] = doc.id;
      }
      return Student.fromJson(data);
    }).toList();
  }

  Future<Student> adminCreateStudent(Map<String, dynamic> studentData) async {
    await _verifyAdminAccess();
    final map = Map<String, dynamic>.from(studentData);
    final studentId = (map['studentId'] as String?)?.isNotEmpty == true
        ? map['studentId'] as String
        : _firestore.collection('students').doc().id;
    map['studentId'] = studentId;
    map['status'] = map['status'] ?? 'ACTIVE';
    map['createdAt'] = FieldValue.serverTimestamp();
    map['updatedAt'] = FieldValue.serverTimestamp();

    await _firestore.collection('students').doc(studentId).set(map, SetOptions(merge: true));
    return Student.fromJson(map);
  }

  Future<void> adminUpdateStudent(String studentId, Map<String, dynamic> studentData) async {
    await _verifyAdminAccess();
    await _firestore.collection('students').doc(studentId).set({
      ...studentData,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<Tutor>> adminGetTutors() async {
    await _verifyAdminAccess();
    final snap = await _firestore.collection('tutors').get();
    return snap.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      if (!data.containsKey('uid') || data['uid'] == null || (data['uid'] as String).isEmpty) {
        data['uid'] = data['tutorUid'] ?? doc.id;
      }
      return Tutor.fromJson(data);
    }).toList();
  }

  Future<Tutor> adminCreateTutor(Map<String, dynamic> tutorData) async {
    await _verifyAdminAccess();
    final map = Map<String, dynamic>.from(tutorData);
    final uid = (map['uid'] as String?)?.isNotEmpty == true
        ? map['uid'] as String
        : (map['tutorUid'] as String?)?.isNotEmpty == true
            ? map['tutorUid'] as String
            : _firestore.collection('tutors').doc().id;
    map['uid'] = uid;
    map['tutorUid'] = uid;
    map['status'] = map['status'] ?? 'ACTIVE';
    map['createdAt'] = FieldValue.serverTimestamp();
    map['updatedAt'] = FieldValue.serverTimestamp();

    await _firestore.collection('tutors').doc(uid).set(map, SetOptions(merge: true));

    // Mirror to users collection so the tutor has an active user record
    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'role': 'TUTOR',
      'accountStatus': map['status'] ?? 'ACTIVE',
      'displayName': map['name'] ?? 'Tutor',
      'email': map['email'],
      'phoneNumber': map['mobileNumber'],
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return Tutor.fromJson(map);
  }

  Future<void> adminUpdateTutorAuthorization(String tutorUid, List<String> authorizedClassIds) async {
    await _verifyAdminAccess();
    await _firestore.collection('tutors').doc(tutorUid).set({
      'authorizedClassIds': authorizedClassIds,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<ClassModel>> adminGetClasses() async {
    await _verifyAdminAccess();
    final snap = await _firestore.collection('classes').get();
    final list = snap.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      if (!data.containsKey('classId') || data['classId'] == null || (data['classId'] as String).isEmpty) {
        data['classId'] = doc.id;
      }
      return ClassModel.fromJson(data);
    }).toList();
    list.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return list;
  }

  Future<ClassModel> adminCreateClass(Map<String, dynamic> classData) async {
    await _verifyAdminAccess();
    final map = Map<String, dynamic>.from(classData);
    final classId = (map['classId'] as String?)?.isNotEmpty == true
        ? map['classId'] as String
        : _firestore.collection('classes').doc().id;
    map['classId'] = classId;
    map['status'] = map['status'] ?? 'ACTIVE';
    map['createdAt'] = FieldValue.serverTimestamp();
    map['updatedAt'] = FieldValue.serverTimestamp();

    await _firestore.collection('classes').doc(classId).set(map, SetOptions(merge: true));
    return ClassModel.fromJson(map);
  }

  Future<void> adminUpdateClass(String classId, Map<String, dynamic> classData) async {
    await _verifyAdminAccess();
    await _firestore.collection('classes').doc(classId).set({
      ...classData,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<AcademicYear>> adminGetAcademicYears() async {
    await _verifyAdminAccess();
    final snap = await _firestore.collection('academicYears').get();
    return snap.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      if (!data.containsKey('academicYearId') || data['academicYearId'] == null || (data['academicYearId'] as String).isEmpty) {
        data['academicYearId'] = doc.id;
      }
      return AcademicYear.fromJson(data);
    }).toList();
  }

  Future<AcademicYear> adminCreateAcademicYear(Map<String, dynamic> yearData) async {
    await _verifyAdminAccess();
    final map = Map<String, dynamic>.from(yearData);
    final yearId = (map['academicYearId'] as String?)?.isNotEmpty == true
        ? map['academicYearId'] as String
        : _firestore.collection('academicYears').doc().id;
    map['academicYearId'] = yearId;
    map['status'] = map['status'] ?? 'ACTIVE';
    map['createdAt'] = FieldValue.serverTimestamp();
    map['updatedAt'] = FieldValue.serverTimestamp();

    await _firestore.collection('academicYears').doc(yearId).set(map, SetOptions(merge: true));
    return AcademicYear.fromJson(map);
  }

  Future<void> adminSetActiveAcademicYear(String academicYearId) async {
    await _verifyAdminAccess();
    final batch = _firestore.batch();
    final snap = await _firestore.collection('academicYears').get();
    for (final doc in snap.docs) {
      final docYearId = doc.data()['academicYearId'] ?? doc.id;
      if (doc.id == academicYearId || docYearId == academicYearId) {
        batch.update(doc.reference, {
          'status': 'ACTIVE',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else if (doc.data()['status'] == 'ACTIVE') {
        batch.update(doc.reference, {
          'status': 'ARCHIVED',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }
    await batch.commit();
  }

  Future<void> adminPromoteStudents({
    required List<String> studentIds,
    required String action, // PROMOTE | COMPLETED | DISCONTINUED
    String? targetAcademicYearId,
    String? targetClassId,
  }) async {
    await _verifyAdminAccess();
    final batch = _firestore.batch();
    for (final id in studentIds) {
      final docRef = _firestore.collection('students').doc(id);
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (action == 'PROMOTE') {
        if (targetClassId != null) updates['currentClassId'] = targetClassId;
        if (targetAcademicYearId != null) updates['currentAcademicYearId'] = targetAcademicYearId;
        updates['status'] = 'ACTIVE';
      } else if (action == 'COMPLETED') {
        updates['status'] = 'COMPLETED';
      } else if (action == 'DISCONTINUED') {
        updates['status'] = 'DISCONTINUED';
      }
      batch.update(docRef, updates);
    }
    await batch.commit();
  }

  Future<List<ExpectedOpportunity>> adminGetPendingAndMissedOpportunities() async {
    await _verifyAdminAccess();
    final snap = await _firestore
        .collection('expectedAttendanceOpportunities')
        .where('status', whereIn: ['PENDING', 'MISSED_DEADLINE'])
        .get();
    return snap.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      if (!data.containsKey('opportunityId') || data['opportunityId'] == null || (data['opportunityId'] as String).isEmpty) {
        data['opportunityId'] = doc.id;
      }
      return ExpectedOpportunity.fromJson(data);
    }).toList();
  }

  Future<ExpectedOpportunity> adminCreateExpectedOpportunity({
    required String classId,
    required String sessionDate,
    int slotNumber = 1,
  }) async {
    await _verifyAdminAccess();
    final classDoc = await _firestore.collection('classes').doc(classId).get();
    final className = classDoc.data()?['name']?.toString() ?? 'Class';

    final aySnap = await _firestore.collection('academicYears').where('status', isEqualTo: 'ACTIVE').limit(1).get();
    final ayId = aySnap.docs.isNotEmpty ? aySnap.docs.first.id : 'ay-default';

    final docRef = _firestore.collection('expectedAttendanceOpportunities').doc();
    final now = DateTime.now();
    final data = <String, dynamic>{
      'opportunityId': docRef.id,
      'classId': classId,
      'className': className,
      'academicYearId': ayId,
      'sessionDate': sessionDate,
      'slotNumber': slotNumber,
      'status': 'PENDING',
      'createdAt': FieldValue.serverTimestamp(),
      'attendanceDeadline': now.add(const Duration(days: 1)).toIso8601String(),
      'allowedCompletionDeadline': now.add(const Duration(days: 7)).toIso8601String(),
    };
    await docRef.set(data);
    return ExpectedOpportunity.fromJson(data);
  }

  Future<void> adminCancelExpectedOpportunity(String opportunityId, String reason) async {
    await _verifyAdminAccess();
    await _firestore.collection('expectedAttendanceOpportunities').doc(opportunityId).set({
      'status': 'CANCELLED',
      'cancelReason': reason,
      'cancelledAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Manual administrative evaluation trigger for attendance deadlines.
  /// NOTE: This is an on-demand administrative maintenance action and NOT an
  /// automated background cron/daemon service. True automated background enforcement
  /// must be provided by a dedicated backend scheduler (such as Cloud Scheduler).
  Future<void> adminTriggerScheduledJobs() async {
    await _verifyAdminAccess();
    final now = DateTime.now();
    final snap = await _firestore
        .collection('expectedAttendanceOpportunities')
        .where('status', isEqualTo: 'PENDING')
        .get();
    final batch = _firestore.batch();
    int updatedCount = 0;
    for (final doc in snap.docs) {
      final rawDeadline = doc.data()['attendanceDeadline'];
      DateTime? deadline;
      if (rawDeadline is Timestamp) {
        deadline = rawDeadline.toDate();
      } else if (rawDeadline != null) {
        deadline = DateTime.tryParse(rawDeadline.toString());
      }
      if (deadline != null && now.isAfter(deadline)) {
        batch.update(doc.reference, {
          'status': 'MISSED_DEADLINE',
          'missedDeadlineAt': FieldValue.serverTimestamp(),
        });
        updatedCount++;
      }
    }
    if (updatedCount > 0) {
      await batch.commit();
    }
  }

  // ==========================================
  // Tutor
  // ==========================================
  Future<List<ClassModel>> tutorGetAuthorizedClasses() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Unauthenticated: Access requires an authenticated session.');
    }

    final tutorDoc = await _firestore.collection('tutors').doc(user.uid).get();
    List<String> authorizedIds = [];
    if (tutorDoc.exists) {
      final rawList = tutorDoc.data()?['authorizedClassIds'];
      if (rawList is List) {
        authorizedIds = rawList.map((e) => e.toString()).toList();
      }
    }

    final list = <ClassModel>[];
    for (final cid in authorizedIds) {
      final doc = await _firestore.collection('classes').doc(cid).get();
      if (doc.exists) {
        final data = Map<String, dynamic>.from(doc.data()!);
        if (!data.containsKey('classId') || data['classId'] == null || (data['classId'] as String).isEmpty) {
          data['classId'] = doc.id;
        }
        list.add(ClassModel.fromJson(data));
      }
    }

    list.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return list;
  }

  Future<List<Map<String, dynamic>>> tutorGetClassStudents(String classId) async {
    await _verifyTutorClassAccess(classId);
    final snap = await _firestore
        .collection('students')
        .where('currentClassId', isEqualTo: classId)
        .where('status', isEqualTo: 'ACTIVE')
        .get();
    return snap.docs.map((doc) {
      final data = doc.data();
      return {
        'studentId': data['studentId'] ?? doc.id,
        'name': data['name'] ?? 'Student',
        'currentClassId': data['currentClassId'] ?? classId,
        'parentName': data['parentName'] ?? '',
        'parentMobileNumber': data['parentMobileNumber'] ?? '',
      };
    }).toList();
  }

  Future<List<ExpectedOpportunity>> tutorGetPendingOpportunities(String classId) async {
    await _verifyTutorClassAccess(classId);
    final snap = await _firestore
        .collection('expectedAttendanceOpportunities')
        .where('classId', isEqualTo: classId)
        .where('status', isEqualTo: 'PENDING')
        .get();
    return snap.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      if (!data.containsKey('opportunityId') || data['opportunityId'] == null || (data['opportunityId'] as String).isEmpty) {
        data['opportunityId'] = doc.id;
      }
      return ExpectedOpportunity.fromJson(data);
    }).toList();
  }

  Future<Map<String, dynamic>> tutorConfirmAttendance({
    required String opportunityId,
    required String classId,
    required String subject,
    required List<Map<String, dynamic>> records,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Authentication required to confirm attendance.');
    }

    // 1. Authorization Validation: Verify tutor is authorized for this class
    await _verifyTutorClassAccess(classId);

    final tutorDoc = await _firestore.collection('tutors').doc(user.uid).get();
    final classDoc = await _firestore.collection('classes').doc(classId).get();
    if (!classDoc.exists) {
      throw StateError('Class $classId does not exist.');
    }

    String tutorName = user.displayName ?? 'Tutor';
    String tutorPhone = user.phoneNumber ?? '';
    if (tutorDoc.exists) {
      final tData = tutorDoc.data()!;
      tutorName = tData['name']?.toString() ?? tutorName;
      tutorPhone = tData['mobileNumber']?.toString() ?? tutorPhone;
    }

    // 2. Session Validation: Verify opportunity exists, matches class, and is not locked/cancelled
    final oppDoc = await _firestore.collection('expectedAttendanceOpportunities').doc(opportunityId).get();
    if (!oppDoc.exists) {
      throw StateError('Attendance opportunity $opportunityId does not exist.');
    }
    final oppData = oppDoc.data()!;
    final oppClassId = oppData['classId']?.toString();
    if (oppClassId != classId) {
      throw StateError('Opportunity $opportunityId belongs to class $oppClassId, not $classId.');
    }

    final currentStatus = oppData['status']?.toString();
    if (currentStatus == 'COMPLETED' || currentStatus == 'LOCKED') {
      throw StateError('This session has already been confirmed and locked.');
    }
    if (currentStatus == 'CANCELLED') {
      throw StateError('This session has been cancelled and cannot be confirmed.');
    }

    // 3. Student Validation: Verify submitted students belong to this class
    final studentsSnap = await _firestore
        .collection('students')
        .where('currentClassId', isEqualTo: classId)
        .where('status', isEqualTo: 'ACTIVE')
        .get();
    final validStudentIds = studentsSnap.docs.map((d) => d.data()['studentId']?.toString() ?? d.id).toSet();

    // 4. Duplicate Protection: Verify no duplicate students in submission payload
    final seenStudentIds = <String>{};
    for (final rec in records) {
      final sId = rec['studentId']?.toString() ?? '';
      if (sId.isEmpty) {
        throw StateError('Invalid submission: record contains empty student ID.');
      }
      if (validStudentIds.isNotEmpty && !validStudentIds.contains(sId)) {
        throw StateError('Student $sId is not an active student of class $classId.');
      }
      if (!seenStudentIds.add(sId)) {
        throw StateError('Duplicate attendance record found for student $sId.');
      }
    }

    final now = DateTime.now();
    final className = classDoc.data()?['name']?.toString() ?? 'Class';
    final sessionDate = oppData['sessionDate']?.toString() ?? now.toIso8601String().split('T').first;
    final academicYearId = oppData['academicYearId']?.toString() ?? 'ay-current';

    // 5. Safe Timestamp Evaluation for Deadline
    String deadlineStatus = 'WITHIN_DEADLINE';
    final rawDeadline = oppData['attendanceDeadline'];
    DateTime? deadline;
    if (rawDeadline is Timestamp) {
      deadline = rawDeadline.toDate();
    } else if (rawDeadline != null) {
      deadline = DateTime.tryParse(rawDeadline.toString());
    }
    if (deadline != null && now.isAfter(deadline)) {
      deadlineStatus = 'MISSED_DEADLINE';
    }

    // 6. Atomic WriteBatch Execution
    final batch = _firestore.batch();

    for (final rec in records) {
      final studentId = rec['studentId']?.toString() ?? '';
      final status = rec['status']?.toString() ?? 'PRESENT';

      // Deterministic record document ID prevents duplicate records for same student & session
      final recordId = '${opportunityId}_$studentId';
      final recordRef = _firestore.collection('attendanceRecords').doc(recordId);

      final recordMap = {
        'recordId': recordId,
        'sessionId': opportunityId,
        'opportunityId': opportunityId,
        'classId': classId,
        'className': className,
        'academicYearId': academicYearId,
        'studentId': studentId,
        'status': status,
        'sessionDate': sessionDate,
        'subject': subject,
        'tutorUid': user.uid,
        'tutorName': tutorName,
        'deadlineStatus': deadlineStatus,
        'sessionStatus': 'LOCKED',
        'createdAt': FieldValue.serverTimestamp(),
      };
      batch.set(recordRef, recordMap, SetOptions(merge: true));

      // Deterministic notification document ID prevents duplicate notification triggers
      if (status == 'ABSENT' || status == 'LATE') {
        final notifId = 'notif_${opportunityId}_$studentId';
        final notifRef = _firestore.collection('parentNotifications').doc(notifId);
        final studentDoc = await _firestore.collection('students').doc(studentId).get();
        final studentName = studentDoc.data()?['name']?.toString() ?? 'Your child';

        batch.set(notifRef, {
          'notificationId': notifId,
          'studentId': studentId,
          'studentName': studentName,
          'status': status,
          'subject': subject,
          'tutorName': tutorName,
          'tutorPhoneNumber': tutorPhone,
          'message': '$studentName was marked $status in $className ($subject) by $tutorName.',
          'createdAt': now.toIso8601String(),
          'readAt': null,
        }, SetOptions(merge: true));
      }
    }

    final oppRef = _firestore.collection('expectedAttendanceOpportunities').doc(opportunityId);
    batch.update(oppRef, {
      'status': 'COMPLETED',
      'actualSubject': subject,
      'tutorName': tutorName,
      'completedAt': FieldValue.serverTimestamp(),
      'deadlineStatus': deadlineStatus,
    });

    // Commit all records, notifications, and opportunity lock atomically
    await batch.commit();

    return {
      'success': true,
      'sessionId': opportunityId,
      'deadlineStatus': deadlineStatus,
      'sessionStatus': 'LOCKED',
    };
  }

  // ==========================================
  // Parent
  // ==========================================
  Future<List<Map<String, dynamic>>> parentGetChildren() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Unauthenticated: Access requires an authenticated session.');
    }

    var snap = await _firestore
        .collection('students')
        .where('parentIds', arrayContains: user.uid)
        .get();

    if (snap.docs.isEmpty) {
      String? phone = user.phoneNumber;
      if (phone == null || phone.isEmpty) {
        try {
          final userDoc = await _firestore.collection('users').doc(user.uid).get();
          if (userDoc.exists) {
            phone = userDoc.data()?['phoneNumber'] as String?;
          }
        } catch (_) {}
      }

      if (phone != null && phone.isNotEmpty) {
        final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
        final localPhone = cleanPhone.startsWith('+91') ? cleanPhone.substring(3) : cleanPhone;

        var phoneSnap = await _firestore
            .collection('students')
            .where('parentMobileNumber', isEqualTo: cleanPhone)
            .get();

        if (phoneSnap.docs.isEmpty && localPhone != cleanPhone) {
          phoneSnap = await _firestore
              .collection('students')
              .where('parentMobileNumber', isEqualTo: localPhone)
              .get();
        }

        if (phoneSnap.docs.isNotEmpty) {
          snap = phoneSnap;
        }
      }
    }

    return snap.docs.map((doc) {
      final data = doc.data();
      final classId = data['currentClassId']?.toString() ?? '';
      return {
        'studentId': data['studentId'] ?? doc.id,
        'name': data['name'] ?? 'Student',
        'className': classId,
        'schoolName': data['schoolName'] ?? '',
        'currentClassId': classId,
        'currentAcademicYearId': data['currentAcademicYearId'] ?? '',
      };
    }).toList();
  }

  Future<ParentDashboardData> parentGetChildDashboard(String studentId) async {
    await _verifyParentStudentAccess(studentId);
    final studentDoc = await _firestore.collection('students').doc(studentId).get();
    final studentData = studentDoc.data() ?? {};
    final studentName = studentData['name']?.toString() ?? 'Student';
    final classId = studentData['currentClassId']?.toString() ?? '';
    final academicYearId = studentData['currentAcademicYearId']?.toString() ?? '';
    final schoolName = studentData['schoolName']?.toString() ?? '';

    String className = classId;
    if (classId.isNotEmpty) {
      final classDoc = await _firestore.collection('classes').doc(classId).get();
      if (classDoc.exists) {
        className = classDoc.data()?['name']?.toString() ?? classId;
      }
    }

    final recordsSnap = await _firestore
        .collection('attendanceRecords')
        .where('studentId', isEqualTo: studentId)
        .get();

    int presentCount = 0;
    int lateCount = 0;
    int absentCount = 0;

    for (final doc in recordsSnap.docs) {
      final status = doc.data()['status']?.toString().toUpperCase();
      if (status == 'PRESENT') {
        presentCount++;
      } else if (status == 'LATE') {
        lateCount++;
      } else if (status == 'ABSENT') {
        absentCount++;
      }
    }

    final totalEligibleSessions = presentCount + lateCount + absentCount;
    final effectivePresent = presentCount + (lateCount * 0.5);
    final attendancePercentage = totalEligibleSessions > 0
        ? ((effectivePresent / totalEligibleSessions) * 1000).round() / 10.0
        : 0.0;

    return ParentDashboardData(
      studentId: studentId,
      studentName: studentName,
      classId: classId,
      className: className,
      academicYearId: academicYearId,
      schoolName: schoolName,
      attendancePercentage: attendancePercentage,
      presentCount: presentCount,
      lateCount: lateCount,
      absentCount: absentCount,
      totalEligibleSessions: totalEligibleSessions,
    );
  }

  Future<List<AttendanceHistoryItem>> parentGetChildAttendanceHistory(String studentId) async {
    await _verifyParentStudentAccess(studentId);
    final snap = await _firestore
        .collection('attendanceRecords')
        .where('studentId', isEqualTo: studentId)
        .get();

    final list = snap.docs.map((doc) {
      final data = doc.data();
      return AttendanceHistoryItem(
        sessionId: data['sessionId']?.toString() ?? data['opportunityId']?.toString() ?? doc.id,
        sessionDate: data['sessionDate']?.toString() ?? '',
        subject: data['subject']?.toString() ?? 'Session',
        status: data['status']?.toString() ?? 'PRESENT',
        tutorName: data['tutorName']?.toString() ?? 'Tutor',
        className: data['className']?.toString() ?? '',
        academicYearId: data['academicYearId']?.toString() ?? '',
        deadlineStatus: data['deadlineStatus']?.toString() ?? 'WITHIN_DEADLINE',
        sessionStatus: data['sessionStatus']?.toString() ?? 'LOCKED',
      );
    }).toList();

    list.sort((a, b) => b.sessionDate.compareTo(a.sessionDate));
    return list;
  }

  Future<List<StudentComparisonResult>> parentCompareChildrenAttendance(List<String> studentIds) async {
    for (final id in studentIds) {
      await _verifyParentStudentAccess(id);
    }
    final results = <StudentComparisonResult>[];
    for (final id in studentIds) {
      final dash = await parentGetChildDashboard(id);
      results.add(StudentComparisonResult(
        studentId: dash.studentId,
        name: dash.studentName,
        className: dash.className,
        attendancePercentage: dash.attendancePercentage,
        presentCount: dash.presentCount,
        lateCount: dash.lateCount,
        absentCount: dash.absentCount,
        totalSessions: dash.totalEligibleSessions,
      ));
    }
    return results;
  }

  Future<List<TutorInfo>> parentGetTutorInfo(String studentId) async {
    await _verifyParentStudentAccess(studentId);
    final studentDoc = await _firestore.collection('students').doc(studentId).get();
    final classId = studentDoc.data()?['currentClassId']?.toString();
    if (classId == null || classId.isEmpty) return [];

    final classDoc = await _firestore.collection('classes').doc(classId).get();
    final tutorIds = (classDoc.data()?['authorizedTutorIds'] as List?)?.map((e) => e.toString()).toList() ?? [];

    final tutors = <TutorInfo>[];
    for (final tid in tutorIds) {
      final tDoc = await _firestore.collection('tutors').doc(tid).get();
      if (tDoc.exists) {
        final tData = tDoc.data()!;
        tutors.add(TutorInfo(
          name: tData['name']?.toString() ?? 'Tutor',
          mobileNumber: tData['mobileNumber']?.toString() ?? '',
          specializedSubjects: (tData['specializedSubjects'] as List?)?.map((e) => e.toString()).toList() ?? [],
          currentSchool: tData['currentSchool']?.toString() ?? '',
          currentPosition: tData['currentPosition']?.toString() ?? '',
        ));
      }
    }

    if (tutors.isEmpty) {
      final snap = await _firestore
          .collection('tutors')
          .where('authorizedClassIds', arrayContains: classId)
          .get();
      for (final doc in snap.docs) {
        final tData = doc.data();
        tutors.add(TutorInfo(
          name: tData['name']?.toString() ?? 'Tutor',
          mobileNumber: tData['mobileNumber']?.toString() ?? '',
          specializedSubjects: (tData['specializedSubjects'] as List?)?.map((e) => e.toString()).toList() ?? [],
          currentSchool: tData['currentSchool']?.toString() ?? '',
          currentPosition: tData['currentPosition']?.toString() ?? '',
        ));
      }
    }

    return tutors;
  }

  Future<List<ParentNotification>> parentGetNotifications() async {
    final children = await parentGetChildren();
    final studentIds = children.map((c) => c['studentId'] as String).toList();
    if (studentIds.isEmpty) return [];

    final snap = await _firestore
        .collection('parentNotifications')
        .where('studentId', whereIn: studentIds.take(10).toList())
        .get();

    final list = snap.docs.map((doc) {
      final data = doc.data();
      dynamic createdAt = data['createdAt'];
      if (createdAt is Timestamp) {
        createdAt = createdAt.toDate().toIso8601String();
      }
      return ParentNotification(
        notificationId: data['notificationId']?.toString() ?? doc.id,
        studentId: data['studentId']?.toString() ?? '',
        studentName: data['studentName']?.toString() ?? '',
        status: data['status']?.toString() ?? 'PRESENT',
        subject: data['subject']?.toString() ?? '',
        tutorName: data['tutorName']?.toString() ?? '',
        tutorPhoneNumber: data['tutorPhoneNumber']?.toString() ?? '',
        message: data['message']?.toString() ?? '',
        createdAt: createdAt,
        readAt: data['readAt'],
      );
    }).toList();

    list.sort((a, b) {
      final aTime = a.createdAt?.toString() ?? '';
      final bTime = b.createdAt?.toString() ?? '';
      return bTime.compareTo(aTime);
    });
    return list;
  }

  Future<void> parentMarkNotificationRead(String notificationId) async {
    await _verifyParentNotificationAccess(notificationId);
    await _firestore.collection('parentNotifications').doc(notificationId).set({
      'readAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> parentDeleteNotification(String notificationId) async {
    await _verifyParentNotificationAccess(notificationId);
    await _firestore.collection('parentNotifications').doc(notificationId).delete();
  }
}
