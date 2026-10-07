import { HttpsError } from "firebase-functions/v2/https";
import { Timestamp } from "firebase-admin/firestore";
import { db, assertRole } from "../utils/auth";
import { StudentAttendanceStatus } from "../types";

/**
 * Helper to verify that a studentId belongs to the caller parent's linked children
 */
async function verifyParentStudentOwnership(parentUid: string, studentId: string, role: string) {
  if (role === "ADMIN") return; // Admin has global view access

  const parentDoc = await db.collection("parents").doc(parentUid).get();
  if (!parentDoc.exists) {
    throw new HttpsError("permission-denied", "Parent profile not found.");
  }

  const linkedIds: string[] = parentDoc.data()?.linkedStudentIds || [];
  if (!linkedIds.includes(studentId)) {
    // Also double check students/{studentId}.parentIds
    const sDoc = await db.collection("students").doc(studentId).get();
    if (!sDoc.exists || !(sDoc.data()?.parentIds || []).includes(parentUid)) {
      throw new HttpsError("permission-denied", "Access denied: Student is not linked to your parent account.");
    }
  }
}

/**
 * Returns all linked children for the calling parent (Section 17)
 */
export async function handleParentGetChildren(authData: any) {
  const caller = await assertRole(authData, ["PARENT", "ADMIN"]);

  let studentDocs: FirebaseFirestore.DocumentSnapshot[] = [];

  if (caller.role === "ADMIN") {
    const snap = await db.collection("students").where("status", "==", "ACTIVE").get();
    studentDocs = snap.docs;
  } else {
    // Fetch parent document
    const parentDoc = await db.collection("parents").doc(caller.uid).get();
    const linkedIds: string[] = parentDoc.data()?.linkedStudentIds || [];

    if (linkedIds.length === 0) {
      // Check query by parentIds array
      const snap = await db.collection("students").where("parentIds", "array-contains", caller.uid).get();
      studentDocs = snap.docs;
    } else {
      const chunks: string[][] = [];
      for (let i = 0; i < linkedIds.length; i += 30) {
        chunks.push(linkedIds.slice(i, i + 30));
      }
      for (const chunk of chunks) {
        const snap = await db.collection("students").where("studentId", "in", chunk).get();
        studentDocs.push(...snap.docs);
      }
    }
  }

  const children: any[] = [];
  for (const doc of studentDocs) {
    const data = doc.data()!;
    let className = data.currentClassId;
    const cDoc = await db.collection("classes").doc(data.currentClassId).get();
    if (cDoc.exists) {
      className = cDoc.data()?.name || data.currentClassId;
    }

    children.push({
      studentId: doc.id,
      name: data.name,
      currentClassId: data.currentClassId,
      className,
      currentAcademicYearId: data.currentAcademicYearId,
      schoolName: data.schoolName,
      status: data.status,
    });
  }

  return children;
}

/**
 * Returns authoritative attendance dashboard metrics for ONE selected child (Section 12 & 17)
 * Formula: Attendance % = (Present Sessions + Late Sessions) / Total Eligible Confirmed Sessions * 100
 */
export async function handleParentGetChildDashboard(authData: any, data: any) {
  const caller = await assertRole(authData, ["PARENT", "ADMIN"]);
  const { studentId } = data;

  if (!studentId) {
    throw new HttpsError("invalid-argument", "studentId is required.");
  }

  await verifyParentStudentOwnership(caller.uid, studentId, caller.role);

  const studentDoc = await db.collection("students").doc(studentId).get();
  if (!studentDoc.exists) {
    throw new HttpsError("not-found", "Student not found.");
  }

  const sData = studentDoc.data()!;
  const classId = sData.currentClassId;
  const academicYearId = sData.currentAcademicYearId;

  // Get class display name
  let className = classId;
  const cDoc = await db.collection("classes").doc(classId).get();
  if (cDoc.exists) {
    className = cDoc.data()?.name || classId;
  }

  // Find all confirmed attendance sessions for this class and academic year
  // (Uncompleted / Missed opportunities have no student records and are strictly excluded)
  const sessionsSnap = await db
    .collection("attendanceSessions")
    .where("classId", "==", classId)
    .where("academicYearId", "==", academicYearId)
    .get();

  let presentCount = 0;
  let lateCount = 0;
  let absentCount = 0;

  for (const sessionDoc of sessionsSnap.docs) {
    const recordDoc = await sessionDoc.ref.collection("records").doc(studentId).get();
    if (recordDoc.exists) {
      const status: StudentAttendanceStatus = recordDoc.data()?.status;
      if (status === "PRESENT") presentCount++;
      else if (status === "LATE") lateCount++;
      else if (status === "ABSENT") absentCount++;
    }
  }

  const totalEligibleSessions = presentCount + lateCount + absentCount;
  let attendancePercentage = 0.0;
  if (totalEligibleSessions > 0) {
    attendancePercentage = Math.round(((presentCount + lateCount) / totalEligibleSessions) * 1000) / 10;
  }

  return {
    studentId,
    studentName: sData.name,
    classId,
    className,
    academicYearId,
    schoolName: sData.schoolName,
    attendancePercentage,
    presentCount,
    lateCount,
    absentCount,
    totalEligibleSessions,
  };
}

/**
 * Returns detailed attendance history for the selected child (Section 18)
 */
export async function handleParentGetChildAttendanceHistory(authData: any, data: any) {
  const caller = await assertRole(authData, ["PARENT", "ADMIN"]);
  const { studentId } = data;

  if (!studentId) {
    throw new HttpsError("invalid-argument", "studentId is required.");
  }

  await verifyParentStudentOwnership(caller.uid, studentId, caller.role);

  const studentDoc = await db.collection("students").doc(studentId).get();
  if (!studentDoc.exists) {
    throw new HttpsError("not-found", "Student not found.");
  }

  const sData = studentDoc.data()!;

  // Fetch all sessions for this student's class
  const sessionsSnap = await db
    .collection("attendanceSessions")
    .where("classId", "==", sData.currentClassId)
    .orderBy("sessionDate", "desc")
    .get();

  const history: any[] = [];

  for (const sessionDoc of sessionsSnap.docs) {
    const recordDoc = await sessionDoc.ref.collection("records").doc(studentId).get();
    if (recordDoc.exists) {
      const sessData = sessionDoc.data();
      history.push({
        sessionId: sessionDoc.id,
        sessionDate: sessData.sessionDate,
        subject: sessData.subject,
        status: recordDoc.data()?.status,
        tutorName: sessData.tutorName,
        className: sessData.className,
        academicYearId: sessData.academicYearId,
        deadlineStatus: sessData.deadlineStatus,
        sessionStatus: sessData.sessionStatus,
      });
    }
  }

  return history;
}

/**
 * Multi-Child Attendance Comparison (Section 19: Only between parent's linked children)
 */
export async function handleParentCompareChildrenAttendance(authData: any, data: any) {
  const caller = await assertRole(authData, ["PARENT", "ADMIN"]);
  const { studentIds } = data;

  if (!Array.isArray(studentIds) || studentIds.length < 2) {
    throw new HttpsError("invalid-argument", "studentIds array with at least 2 students is required.");
  }

  // Verify ownership for all requested student IDs
  for (const sId of studentIds) {
    await verifyParentStudentOwnership(caller.uid, sId, caller.role);
  }

  const results: any[] = [];

  for (const sId of studentIds) {
    const sDoc = await db.collection("students").doc(sId).get();
    if (!sDoc.exists) continue;

    const sData = sDoc.data()!;
    const classId = sData.currentClassId;

    let className = classId;
    const cDoc = await db.collection("classes").doc(classId).get();
    if (cDoc.exists) className = cDoc.data()?.name || classId;

    const sessionsSnap = await db
      .collection("attendanceSessions")
      .where("classId", "==", classId)
      .where("academicYearId", "==", sData.currentAcademicYearId)
      .get();

    let present = 0;
    let late = 0;
    let absent = 0;

    for (const sessionDoc of sessionsSnap.docs) {
      const recordDoc = await sessionDoc.ref.collection("records").doc(sId).get();
      if (recordDoc.exists) {
        const st: StudentAttendanceStatus = recordDoc.data()?.status;
        if (st === "PRESENT") present++;
        else if (st === "LATE") late++;
        else if (st === "ABSENT") absent++;
      }
    }

    const total = present + late + absent;
    const percentage = total > 0 ? Math.round(((present + late) / total) * 1000) / 10 : 0.0;

    results.push({
      studentId: sId,
      name: sData.name,
      className,
      attendancePercentage: percentage,
      presentCount: present,
      lateCount: late,
      absentCount: absent,
      totalSessions: total,
    });
  }

  return results;
}

/**
 * Tutor Information for student's class (Section 20: Name & Mobile only, NO contact buttons)
 */
export async function handleParentGetTutorInfo(authData: any, data: any) {
  const caller = await assertRole(authData, ["PARENT", "ADMIN"]);
  const { studentId } = data;

  if (!studentId) {
    throw new HttpsError("invalid-argument", "studentId is required.");
  }

  await verifyParentStudentOwnership(caller.uid, studentId, caller.role);

  const sDoc = await db.collection("students").doc(studentId).get();
  if (!sDoc.exists) {
    throw new HttpsError("not-found", "Student not found.");
  }

  const classId = sDoc.data()?.currentClassId;
  const cDoc = await db.collection("classes").doc(classId).get();
  if (!cDoc.exists) {
    return [];
  }

  const authorizedTutorIds: string[] = cDoc.data()?.authorizedTutorIds || [];
  if (authorizedTutorIds.length === 0) {
    return [];
  }

  const tutors: any[] = [];
  for (const tUid of authorizedTutorIds) {
    const tDoc = await db.collection("tutors").doc(tUid).get();
    if (tDoc.exists && tDoc.data()?.status === "ACTIVE") {
      const tData = tDoc.data()!;
      tutors.push({
        name: tData.name,
        mobileNumber: tData.mobileNumber,
        specializedSubjects: tData.specializedSubjects || [],
        currentSchool: tData.currentSchool || "",
        currentPosition: tData.currentPosition || "",
      });
    }
  }

  return tutors;
}

/**
 * Notifications list for parent (Section 23: Soft delete supported)
 */
export async function handleParentGetNotifications(authData: any) {
  const caller = await assertRole(authData, ["PARENT", "ADMIN"]);

  const snap = await db
    .collection("notifications")
    .where("parentUid", "==", caller.uid)
    .orderBy("createdAt", "desc")
    .get();

  return snap.docs
    .map((d) => ({ ...d.data(), notificationId: d.id }))
    .filter((n: any) => !n.deletedAt); // Filter out soft-deleted notifications
}

/**
 * Mark notification as read (Section 23)
 */
export async function handleParentMarkNotificationRead(authData: any, data: any) {
  const caller = await assertRole(authData, ["PARENT", "ADMIN"]);
  const { notificationId } = data;

  if (!notificationId) {
    throw new HttpsError("invalid-argument", "notificationId is required.");
  }

  const notifRef = db.collection("notifications").doc(notificationId);
  const notifDoc = await notifRef.get();
  if (!notifDoc.exists) {
    throw new HttpsError("not-found", "Notification not found.");
  }

  if (caller.role !== "ADMIN" && notifDoc.data()?.parentUid !== caller.uid) {
    throw new HttpsError("permission-denied", "Access denied.");
  }

  await notifRef.update({ readAt: Timestamp.now() });
  return { success: true };
}

/**
 * Soft delete notification (Section 23: deletedAt)
 */
export async function handleParentDeleteNotification(authData: any, data: any) {
  const caller = await assertRole(authData, ["PARENT", "ADMIN"]);
  const { notificationId } = data;

  if (!notificationId) {
    throw new HttpsError("invalid-argument", "notificationId is required.");
  }

  const notifRef = db.collection("notifications").doc(notificationId);
  const notifDoc = await notifRef.get();
  if (!notifDoc.exists) {
    throw new HttpsError("not-found", "Notification not found.");
  }

  if (caller.role !== "ADMIN" && notifDoc.data()?.parentUid !== caller.uid) {
    throw new HttpsError("permission-denied", "Access denied.");
  }

  await notifRef.update({ deletedAt: Timestamp.now() });
  return { success: true };
}
