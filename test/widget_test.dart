import 'package:flutter_test/flutter_test.dart';
import 'package:classping/models/attendance_history_item.dart';
import 'package:classping/models/expected_opportunity.dart';
import 'package:classping/models/class_model.dart';
import 'package:classping/models/parent_dashboard_data.dart';

void main() {
  group('Attendance Calculation & Model Tests', () {
    test('AttendanceHistoryItem JSON deserialization handles full payload', () {
      final json = {
        'sessionId': 'session-123',
        'sessionDate': '2026-09-17',
        'subject': 'Mathematics',
        'status': 'PRESENT',
        'tutorName': 'John Doe',
        'className': 'Grade 10 - A',
        'academicYearId': 'ay-2026-2027',
        'deadlineStatus': 'WITHIN_DEADLINE',
        'sessionStatus': 'LOCKED',
      };

      final item = AttendanceHistoryItem.fromJson(json);

      expect(item.sessionId, equals('session-123'));
      expect(item.sessionDate, equals('2026-09-17'));
      expect(item.subject, equals('Mathematics'));
      expect(item.status, equals('PRESENT'));
      expect(item.tutorName, equals('John Doe'));
      expect(item.className, equals('Grade 10 - A'));
      expect(item.deadlineStatus, equals('WITHIN_DEADLINE'));
    });

    test('ParentDashboardData authoritative calculation formula', () {
      final data = ParentDashboardData(
        studentId: 'stud-1',
        studentName: 'Alice',
        classId: 'cls-1',
        className: 'Grade 10',
        academicYearId: 'ay-2026',
        schoolName: 'Central High',
        presentCount: 8,
        lateCount: 1,
        absentCount: 1,
        totalEligibleSessions: 10,
        attendancePercentage: 90.0,
      );

      // Attendance % = (Present + Late) / Total Confirmed * 100
      final computed = ((data.presentCount + data.lateCount) / data.totalEligibleSessions) * 100;
      expect(computed, equals(90.0));
      expect(data.attendancePercentage, equals(computed));
    });

    test('ClassModel defaults and operating days configuration', () {
      final json = {
        'classId': 'cls-1',
        'name': 'Physics Advanced',
        'displayOrder': 1,
        'status': 'ACTIVE',
        'authorizedTutorIds': ['tutor-1'],
        'operatingDays': ['MONDAY', 'WEDNESDAY', 'FRIDAY'],
        'expectedSessionsPerDay': 2,
      };

      final classModel = ClassModel.fromJson(json);

      expect(classModel.classId, equals('cls-1'));
      expect(classModel.operatingDays, contains('WEDNESDAY'));
      expect(classModel.expectedSessionsPerDay, equals(2));
    });

    test('ExpectedOpportunity deadline state modeling', () {
      final json = {
        'opportunityId': 'opp-99',
        'academicYearId': 'ay-1',
        'classId': 'cls-1',
        'className': 'Chemistry',
        'sessionDate': '2026-09-17',
        'slotNumber': 1,
        'status': 'PENDING',
        'attendanceDeadline': '2026-09-18T23:59:59Z',
        'allowedCompletionDeadline': '2026-09-24T23:59:59Z',
      };

      final opp = ExpectedOpportunity.fromJson(json);

      expect(opp.opportunityId, equals('opp-99'));
      expect(opp.status, equals('PENDING'));
      expect(opp.slotNumber, equals(1));
    });
  });
}
