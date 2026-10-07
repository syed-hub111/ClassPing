import { HttpsError } from "firebase-functions/v2/https";
import { Timestamp } from "firebase-admin/firestore";
import { db, assertRole, writeAuditLog } from "../utils/auth";
import { normalizeSubject } from "../utils/dates";
import { dispatchAttendanceNotifications } from "./notificationService";
import {
  AttendanceSessionDoc,
  AttendanceRecordDoc,
  StudentAttendanceStatus,
  DeadlineStatus,
  OpportunityStatus,
} from "../types";

/**
 * Returns classes authorized for the calling tutor (Section 9 & 30)
 */
export async function handleTutorGetAuthorizedClasses(authData: any) {
  const caller = await assertRole(authData, ["TUTOR", "ADMIN"]);

  if (caller.role === "ADMIN") {
    const snap = await db.collection("classes").where("status", "==", "ACTIVE").get();
    return snap.docs.map((d) => ({ ...d.data(), classId: d.id }));
  }

  // Caller is Tutor: get authorized class IDs from tutor doc
  const tutorDoc = await db.collection("tutors").doc(caller.uid).get();
  if (!tutorDoc.exists) {
    throw new HttpsError("not-found", "Tutor profile not found.");
  }

  const authorizedClassIds: string[] = tutorDoc.data()?.authorizedClassIds || [];
  if (authorizedClassIds.length === 0) {
    return [];
  }

  // Firestore allows up to 30 elements in where-in
  const chunks: string[][] = [];
  for (let i = 0; i < authorizedClassIds.length; i += 30) {
    chunks.push(authorizedClassIds.slice(i, i + 30));
  }

  const classes: any[] = [];
  for (const chunk of chunks) {
    const snap = await db.collection("classes").where("classId", "in", chunk).get();
    snap.docs.forEach((d) => {
      if (d.data().status === "ACTIVE") {
        classes.push({ ...d.data(), classId: d.id });
      }
    });
  }

  classes.sort((a, b) => (a.displayOrder || 0) - (b.displayOrder || 0));
  return classes;
}

/**
 * Returns active students enrolled in the specified authorized class
 */
export async function handleTutorGetClassStudents(authData: any, data: any) {
  const caller = await assertRole(authData, ["TUTOR", "ADMIN"]);
  const { classId } = data;

  if (!classId) {
    throw new HttpsError("invalid-argument", "classId is required.");
  }

  // Verify tutor authorization
  if (caller.role === "TUTOR") {
    const tutorDoc = await db.collection("tutors").doc(caller.uid).get();
    const authorizedClassIds: string[] = tutorDoc.data()?.authorizedClassIds || [];
    if (!authorizedClassIds.includes(classId)) {
      throw new HttpsError("permission-denied", "Unauthorized class: You are not authorized for this class.");
    }
  }

  const studentsSnap = await db
    .collection("students")
    .where("currentClassId", "==", classId)
    .where("status", "==", "ACTIVE")
    .get();

  return studentsSnap.docs.map((d) => ({
    studentId: d.id,
    name: d.data().name,
    parentName: d.data().parentName,
    schoolName: d.data().schoolName,
  }));
}

/**
 * Returns pending or missed opportunities for an authorized class
 */
export async function handleTutorGetPendingOpportunities(authData: any, data: any) {
  const caller = await assertRole(authData, ["TUTOR", "ADMIN"]);
  const { classId } = data;

  if (!classId) {
    throw new HttpsError("invalid-argument", "classId is required.");
  }

  // Verify tutor authorization
  if (caller.role === "TUTOR") {
    const tutorDoc = await db.collection("tutors").doc(caller.uid).get();
    const authorizedClassIds: string[] = tutorDoc.data()?.authorizedClassIds || [];
    if (!authorizedClassIds.includes(classId)) {
      throw new HttpsError("permission-denied", "Unauthorized class.");
    }
  }

  const now = Timestamp.now();

  const [pendingSnap, missedSnap] = await Promise.all([
    db
      .collection("expectedAttendanceOpportunities")
      .where("classId", "==", classId)
      .where("status", "==", "PENDING")
      .get(),
    db
      .collection("expectedAttendanceOpportunities")
      .where("classId", "==", classId)
      .where("status", "==", "MISSED_DEADLINE")
      .get(),
  ]);

  const opportunities: any[] = [];
  const appendDoc = (d: any) => {
    const opp = d.data();
    // Verify that the opportunity is still within the allowed 7-day completion window
    if (opp.allowedCompletionDeadline && opp.allowedCompletionDeadline.toMillis() >= now.toMillis()) {
      opportunities.push({ ...opp, opportunityId: d.id });
    }
  };

  pendingSnap.docs.forEach(appendDoc);
  missedSnap.docs.forEach(appendDoc);

  opportunities.sort((a, b) => b.sessionDate.localeCompare(a.sessionDate));
  return opportunities;
}

/**
 * Confirms roll call and locks the session (Section 13: MARK -> REVIEW -> CONFIRM -> LOCK)
 * Enforces:
 * - Tutor authorization for classId
 * - Flexible subject selection (Section 10)
 * - Atomic duplicate check: AcademicYear + Class + Date + Subject (Section 14)
 * - Deadline check & status: WITHIN_DEADLINE vs MISSED_DEADLINE (COMPLETED_AFTER_DEADLINE)
 * - Preserving original deadline
 * - Parent notifications generation
 */
export async function handleTutorConfirmAttendance(authData: any, data: any) {
  const caller = await assertRole(authData, ["TUTOR", "ADMIN"]);
  const { opportunityId, classId, subject, records } = data;

  if (!opportunityId || !classId || !subject || !Array.isArray(records) || records.length === 0) {
    throw new HttpsError(
      "invalid-argument",
      "opportunityId, classId, subject, and student records are required."
    );
  }

  // Verify tutor authorization
  let tutorPhoneNumber = caller.phoneNumber || "";
  if (caller.role === "TUTOR") {
    const tutorDoc = await db.collection("tutors").doc(caller.uid).get();
    if (!tutorDoc.exists || tutorDoc.data()?.status !== "ACTIVE") {
      throw new HttpsError("permission-denied", "Tutor profile is not active.");
    }
    const authorizedClassIds: string[] = tutorDoc.data()?.authorizedClassIds || [];
    if (!authorizedClassIds.includes(classId)) {
      throw new HttpsError("permission-denied", "Unauthorized class: You are not authorized to mark attendance for this class.");
    }
    tutorPhoneNumber = tutorDoc.data()?.mobileNumber || caller.phoneNumber || "";
  }

  // Validate student records statuses
  for (const r of records) {
    if (!r.studentId || !r.studentName || !["PRESENT", "LATE", "ABSENT"].includes(r.status)) {
      throw new HttpsError(
        "invalid-argument",
        `Invalid record for student '${r.studentName || r.studentId}'. Status must be PRESENT, LATE, or ABSENT.`
      );
    }
  }

  const normalizedSubj = normalizeSubject(subject);
  const oppRef = db.collection("expectedAttendanceOpportunities").doc(opportunityId);
  const now = Timestamp.now();

  let finalSessionId = "";
  let finalSessionStatus: "LOCKED" | "COMPLETED_AFTER_DEADLINE" = "LOCKED";
  let finalDeadlineStatus: DeadlineStatus = "WITHIN_DEADLINE";
  let originalDeadline: Timestamp = now;

  // Run atomic Firestore transaction
  await db.runTransaction(async (tx) => {
    const oppDoc = await tx.get(oppRef);
    if (!oppDoc.exists) {
      throw new HttpsError("not-found", "Expected attendance opportunity not found.");
    }

    const oppData = oppDoc.data()!;
    if (oppData.classId !== classId) {
      throw new HttpsError("invalid-argument", "Opportunity does not match the provided class.");
    }

    if (oppData.status === "LOCKED" || oppData.status === "COMPLETED_AFTER_DEADLINE") {
      throw new HttpsError("failed-precondition", "Attendance cannot be modified because it is already locked.");
    }

    if (oppData.status === "CANCELLED") {
      throw new HttpsError("failed-precondition", "This attendance opportunity was cancelled by an administrator.");
    }

    // Check allowed 7-day completion window
    if (oppData.allowedCompletionDeadline && oppData.allowedCompletionDeadline.toMillis() < now.toMillis()) {
      throw new HttpsError(
        "deadline-exceeded",
        "The allowed 7-day completion window for this attendance session has expired."
      );
    }

    originalDeadline = oppData.attendanceDeadline;

    // Determine deadline status
    if (now.toMillis() <= oppData.attendanceDeadline.toMillis()) {
      finalSessionStatus = "LOCKED";
      finalDeadlineStatus = "WITHIN_DEADLINE";
    } else {
      finalSessionStatus = "COMPLETED_AFTER_DEADLINE";
      finalDeadlineStatus = "MISSED_DEADLINE";
    }

    // Compute unique session key: AcademicYear + Class + Date + Subject
    const uniqueSessionKey = `${oppData.academicYearId}__${classId}__${oppData.sessionDate}__${normalizedSubj}`;
    finalSessionId = uniqueSessionKey;

    const sessionRef = db.collection("attendanceSessions").doc(uniqueSessionKey);
    const existingSession = await tx.get(sessionRef);

    if (existingSession.exists) {
      throw new HttpsError(
        "already-exists",
        `Attendance has already been recorded for this class, date, and subject ('${subject}').`
      );
    }

    // Write actual attendance session
    const sessionData: AttendanceSessionDoc = {
      sessionId: uniqueSessionKey,
      uniqueSessionKey,
      opportunityId,
      academicYearId: oppData.academicYearId,
      classId,
      className: oppData.className,
      subject: subject.trim(),
      tutorUid: caller.uid,
      tutorName: caller.displayName || "Tutor",
      sessionDate: oppData.sessionDate,
      sessionStatus: finalSessionStatus,
      deadlineStatus: finalDeadlineStatus,
      attendanceDeadline: oppData.attendanceDeadline, // Original deadline preserved!
      confirmedAt: now,
      createdAt: now,
      updatedAt: now,
    };

    tx.set(sessionRef, sessionData);

    // Write student records subcollection
    for (const r of records) {
      const recordRef = sessionRef.collection("records").doc(r.studentId);
      const recordDoc: AttendanceRecordDoc = {
        studentId: r.studentId,
        studentName: r.studentName,
        status: r.status as StudentAttendanceStatus,
        recordedAt: now,
      };
      tx.set(recordRef, recordDoc);
    }

    // Update opportunity document
    const oppStatus: OpportunityStatus = finalSessionStatus === "LOCKED" ? "LOCKED" : "COMPLETED_AFTER_DEADLINE";
    tx.update(oppRef, {
      status: oppStatus,
      linkedActualSessionId: uniqueSessionKey,
      actualSubject: subject.trim(),
      tutorUid: caller.uid,
      tutorName: caller.displayName || "Tutor",
      completedAt: now,
      updatedAt: now,
    });
  });

  // Post-transaction tasks: Audit log & Notifications
  await writeAuditLog(
    finalSessionStatus === "LOCKED" ? "ATTENDANCE_CONFIRMED" : "ATTENDANCE_COMPLETED_AFTER_DEADLINE",
    caller.uid,
    caller.role,
    finalSessionId,
    {
      opportunityId,
      classId,
      subject,
      sessionStatus: finalSessionStatus,
      deadlineStatus: finalDeadlineStatus,
      recordCount: records.length,
    }
  );

  // Dispatch parent notifications
  try {
    await dispatchAttendanceNotifications({
      attendanceSessionId: finalSessionId,
      subject: subject.trim(),
      tutorName: caller.displayName || "Tutor",
      tutorPhoneNumber,
      studentRecords: records,
    });
  } catch (notifErr) {
    console.error("Error dispatching attendance notifications:", notifErr);
  }

  return {
    success: true,
    sessionId: finalSessionId,
    sessionStatus: finalSessionStatus,
    deadlineStatus: finalDeadlineStatus,
    message: "Attendance successfully confirmed and locked.",
  };
}
