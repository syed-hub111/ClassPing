import { HttpsError } from "firebase-functions/v2/https";
import { Timestamp } from "firebase-admin/firestore";
import { db, auth, assertRole, writeAuditLog } from "../utils/auth";
import { normalizePhoneNumber, computeAttendanceDeadline, computeAllowedCompletionDeadline } from "../utils/dates";
import {
  StudentDoc,
  TutorDoc,
  ClassDoc,
  AcademicYearDoc,
  ExpectedOpportunityDoc,
  StudentStatus,
  EnrollmentDoc,
} from "../types";

/**
 * Returns Admin dashboard summary statistics
 */
export async function handleAdminGetDashboardStats(authData: any) {
  const caller = await assertRole(authData, ["ADMIN"]);

  const [studentsSnap, tutorsSnap, classesSnap, pendingSnap, missedSnap] = await Promise.all([
    db.collection("students").where("status", "==", "ACTIVE").count().get(),
    db.collection("tutors").where("status", "==", "ACTIVE").count().get(),
    db.collection("classes").where("status", "==", "ACTIVE").count().get(),
    db.collection("expectedAttendanceOpportunities").where("status", "==", "PENDING").count().get(),
    db.collection("expectedAttendanceOpportunities").where("status", "==", "MISSED_DEADLINE").count().get(),
  ]);

  return {
    activeStudents: studentsSnap.data().count,
    activeTutors: tutorsSnap.data().count,
    activeClasses: classesSnap.data().count,
    pendingSessions: pendingSnap.data().count,
    missedDeadlines: missedSnap.data().count,
  };
}

/**
 * Get all students with their current class and academic year
 */
export async function handleAdminGetStudents(authData: any) {
  await assertRole(authData, ["ADMIN"]);
  const snap = await db.collection("students").orderBy("createdAt", "desc").get();
  return snap.docs.map((d) => ({ ...d.data(), studentId: d.id }));
}

/**
 * Create a new student (Section 6: Name, ID, Class, Parent Name, Parent Mobile, School)
 */
export async function handleAdminCreateStudent(authData: any, data: any) {
  const caller = await assertRole(authData, ["ADMIN"]);

  const { studentId, name, currentClassId, currentAcademicYearId, parentName, parentMobileNumber, schoolName } = data;

  if (!studentId || !name || !currentClassId || !currentAcademicYearId || !parentMobileNumber || !schoolName) {
    throw new HttpsError("invalid-argument", "All student fields are required.");
  }

  const existing = await db.collection("students").doc(studentId).get();
  if (existing.exists) {
    throw new HttpsError("already-exists", `Student with ID '${studentId}' already exists.`);
  }

  const normalizedPhone = normalizePhoneNumber(parentMobileNumber);

  // Check if a parent with this phone number is already verified in the system
  const parentQuery = await db.collection("parents").where("phoneNumber", "==", normalizedPhone).get();
  const parentIds: string[] = [];
  const parentBatch = db.batch();

  parentQuery.docs.forEach((pDoc) => {
    parentIds.push(pDoc.id);
    const linked: string[] = pDoc.data().linkedStudentIds || [];
    if (!linked.includes(studentId)) {
      parentBatch.update(pDoc.ref, {
        linkedStudentIds: [...linked, studentId],
        updatedAt: Timestamp.now(),
      });
    }
  });

  // Fetch class name
  const classDoc = await db.collection("classes").doc(currentClassId).get();
  const className = classDoc.exists ? classDoc.data()?.name : currentClassId;

  const studentDocRef = db.collection("students").doc(studentId);
  const newStudent: StudentDoc = {
    studentId,
    name,
    currentClassId,
    currentAcademicYearId,
    parentIds,
    parentName: parentName || "Parent",
    parentMobileNumber: normalizedPhone,
    schoolName,
    status: "ACTIVE",
    createdAt: Timestamp.now(),
    updatedAt: Timestamp.now(),
  };

  parentBatch.set(studentDocRef, newStudent);

  // Create initial enrollment in subcollection
  const enrollmentRef = studentDocRef.collection("enrollments").doc();
  const enrollment: EnrollmentDoc = {
    enrollmentId: enrollmentRef.id,
    academicYearId: currentAcademicYearId,
    classId: currentClassId,
    className,
    status: "ACTIVE",
    startDate: Timestamp.now(),
  };
  parentBatch.set(enrollmentRef, enrollment);

  await parentBatch.commit();

  await writeAuditLog("STUDENT_CREATED", caller.uid, caller.role, studentId, {
    studentName: name,
    classId: currentClassId,
    academicYearId: currentAcademicYearId,
  });

  return newStudent;
}

/**
 * Get all tutors
 */
export async function handleAdminGetTutors(authData: any) {
  await assertRole(authData, ["ADMIN"]);
  const snap = await db.collection("tutors").orderBy("createdAt", "desc").get();
  return snap.docs.map((d) => ({ ...d.data(), uid: d.id }));
}

/**
 * Create a new tutor (Section 7: Name, Mobile, Email, Specialized Subjects, School, Position, Employment Type)
 */
export async function handleAdminCreateTutor(authData: any, data: any) {
  const caller = await assertRole(authData, ["ADMIN"]);

  const {
    name,
    mobileNumber,
    email,
    password,
    specializedSubjects,
    currentSchool,
    currentPosition,
    employmentType,
    authorizedClassIds,
  } = data;

  if (!name || !mobileNumber || !email) {
    throw new HttpsError("invalid-argument", "Name, mobile number, and email are required for tutor creation.");
  }

  const normalizedPhone = normalizePhoneNumber(mobileNumber);

  // Check or create Firebase Auth user
  let userRecord;
  try {
    userRecord = await auth.getUserByEmail(email);
  } catch (err: any) {
    if (err.code === "auth/user-not-found") {
      userRecord = await auth.createUser({
        email,
        password: password || "Tuition@2026",
        displayName: name,
        phoneNumber: normalizedPhone,
      });
    } else {
      throw err;
    }
  }

  const tutorUid = userRecord.uid;

  const tutorDocRef = db.collection("tutors").doc(tutorUid);
  const tutorData: TutorDoc = {
    uid: tutorUid,
    name,
    mobileNumber: normalizedPhone,
    email,
    specializedSubjects: specializedSubjects || [],
    currentSchool: currentSchool || "",
    currentPosition: currentPosition || "",
    employmentType: employmentType || "School Teacher",
    authorizedClassIds: authorizedClassIds || [],
    status: "ACTIVE",
    createdAt: Timestamp.now(),
    updatedAt: Timestamp.now(),
  };

  const userDocRef = db.collection("users").doc(tutorUid);
  const batch = db.batch();
  batch.set(tutorDocRef, tutorData, { merge: true });
  batch.set(
    userDocRef,
    {
      uid: tutorUid,
      role: "TUTOR",
      accountStatus: "ACTIVE",
      displayName: name,
      email,
      phoneNumber: normalizedPhone,
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    },
    { merge: true }
  );

  // If authorizedClassIds were provided, also update authorizedTutorIds on those classes
  if (authorizedClassIds && Array.isArray(authorizedClassIds)) {
    for (const classId of authorizedClassIds) {
      const cRef = db.collection("classes").doc(classId);
      const cDoc = await cRef.get();
      if (cDoc.exists) {
        const tutorsList: string[] = cDoc.data()?.authorizedTutorIds || [];
        if (!tutorsList.includes(tutorUid)) {
          batch.update(cRef, {
            authorizedTutorIds: [...tutorsList, tutorUid],
            updatedAt: Timestamp.now(),
          });
        }
      }
    }
  }

  await batch.commit();
  await auth.setCustomUserClaims(tutorUid, { role: "TUTOR" });

  await writeAuditLog("TUTOR_CREATED", caller.uid, caller.role, tutorUid, {
    tutorName: name,
    email,
    authorizedClassIds,
  });

  return tutorData;
}

/**
 * Update tutor class authorizations (Section 9)
 */
export async function handleAdminUpdateTutorAuthorization(authData: any, data: any) {
  const caller = await assertRole(authData, ["ADMIN"]);
  const { tutorUid, authorizedClassIds } = data;

  if (!tutorUid || !Array.isArray(authorizedClassIds)) {
    throw new HttpsError("invalid-argument", "tutorUid and authorizedClassIds array are required.");
  }

  const tutorRef = db.collection("tutors").doc(tutorUid);
  const tutorDoc = await tutorRef.get();
  if (!tutorDoc.exists) {
    throw new HttpsError("not-found", "Tutor profile not found.");
  }

  const previousClassIds: string[] = tutorDoc.data()?.authorizedClassIds || [];

  const batch = db.batch();
  batch.update(tutorRef, {
    authorizedClassIds,
    updatedAt: Timestamp.now(),
  });

  // Remove tutor from previously authorized classes that are no longer assigned
  for (const oldClassId of previousClassIds) {
    if (!authorizedClassIds.includes(oldClassId)) {
      const cRef = db.collection("classes").doc(oldClassId);
      const cDoc = await cRef.get();
      if (cDoc.exists) {
        const tutorsList: string[] = cDoc.data()?.authorizedTutorIds || [];
        batch.update(cRef, {
          authorizedTutorIds: tutorsList.filter((id) => id !== tutorUid),
          updatedAt: Timestamp.now(),
        });
      }
    }
  }

  // Add tutor to new classes
  for (const newClassId of authorizedClassIds) {
    if (!previousClassIds.includes(newClassId)) {
      const cRef = db.collection("classes").doc(newClassId);
      const cDoc = await cRef.get();
      if (cDoc.exists) {
        const tutorsList: string[] = cDoc.data()?.authorizedTutorIds || [];
        if (!tutorsList.includes(tutorUid)) {
          batch.update(cRef, {
            authorizedTutorIds: [...tutorsList, tutorUid],
            updatedAt: Timestamp.now(),
          });
        }
      }
    }
  }

  await batch.commit();

  await writeAuditLog("TUTOR_AUTHORIZATION_CHANGED", caller.uid, caller.role, tutorUid, {
    previousClassIds,
    newClassIds: authorizedClassIds,
  });

  return { success: true, authorizedClassIds };
}

/**
 * Classes management (Section 8: Classes not hardcoded)
 */
export async function handleAdminGetClasses(authData: any) {
  await assertRole(authData, ["ADMIN"]);
  const snap = await db.collection("classes").orderBy("displayOrder", "asc").get();
  return snap.docs.map((d) => ({ ...d.data(), classId: d.id }));
}

export async function handleAdminCreateClass(authData: any, data: any) {
  const caller = await assertRole(authData, ["ADMIN"]);
  const { name, displayOrder, operatingDays, expectedSessionsPerDay } = data;

  if (!name) {
    throw new HttpsError("invalid-argument", "Class name is required.");
  }

  const classRef = db.collection("classes").doc();
  const newClass: ClassDoc = {
    classId: classRef.id,
    name,
    displayOrder: typeof displayOrder === "number" ? displayOrder : 1,
    status: "ACTIVE",
    authorizedTutorIds: [],
    operatingDays: operatingDays || ["MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY"],
    expectedSessionsPerDay: typeof expectedSessionsPerDay === "number" ? expectedSessionsPerDay : 1,
    createdAt: Timestamp.now(),
    updatedAt: Timestamp.now(),
  };

  await classRef.set(newClass);
  await writeAuditLog("CLASS_CREATED", caller.uid, caller.role, classRef.id, { name });
  return newClass;
}

export async function handleAdminUpdateClass(authData: any, data: any) {
  const caller = await assertRole(authData, ["ADMIN"]);
  const { classId, name, displayOrder, status, operatingDays, expectedSessionsPerDay } = data;

  if (!classId) {
    throw new HttpsError("invalid-argument", "classId is required.");
  }

  const classRef = db.collection("classes").doc(classId);
  const updateData: any = { updatedAt: Timestamp.now() };
  if (name !== undefined) updateData.name = name;
  if (displayOrder !== undefined) updateData.displayOrder = displayOrder;
  if (status !== undefined) updateData.status = status;
  if (operatingDays !== undefined) updateData.operatingDays = operatingDays;
  if (expectedSessionsPerDay !== undefined) updateData.expectedSessionsPerDay = expectedSessionsPerDay;

  await classRef.update(updateData);
  await writeAuditLog("CLASS_UPDATED", caller.uid, caller.role, classId, updateData);
  return { success: true };
}

/**
 * Academic Years Management (Section 16)
 */
export async function handleAdminGetAcademicYears(authData: any) {
  await assertRole(authData, ["ADMIN"]);
  const snap = await db.collection("academicYears").orderBy("startDate", "desc").get();
  return snap.docs.map((d) => ({ ...d.data(), academicYearId: d.id }));
}

export async function handleAdminCreateAcademicYear(authData: any, data: any) {
  const caller = await assertRole(authData, ["ADMIN"]);
  const { name, startDate, endDate } = data;

  if (!name || !startDate || !endDate) {
    throw new HttpsError("invalid-argument", "Name, start date, and end date are required.");
  }

  const ayRef = db.collection("academicYears").doc();
  const newYear: AcademicYearDoc = {
    academicYearId: ayRef.id,
    name,
    startDate: Timestamp.fromDate(new Date(startDate)),
    endDate: Timestamp.fromDate(new Date(endDate)),
    status: "ACTIVE",
    createdAt: Timestamp.now(),
    updatedAt: Timestamp.now(),
  };

  await ayRef.set(newYear);
  await writeAuditLog("ACADEMIC_YEAR_CREATED", caller.uid, caller.role, ayRef.id, { name });
  return newYear;
}

export async function handleAdminSetActiveAcademicYear(authData: any, data: any) {
  const caller = await assertRole(authData, ["ADMIN"]);
  const { academicYearId } = data;

  if (!academicYearId) {
    throw new HttpsError("invalid-argument", "academicYearId is required.");
  }

  const snap = await db.collection("academicYears").get();
  const batch = db.batch();

  snap.docs.forEach((doc) => {
    if (doc.id === academicYearId) {
      batch.update(doc.ref, { status: "ACTIVE", updatedAt: Timestamp.now() });
    } else if (doc.data().status === "ACTIVE") {
      batch.update(doc.ref, { status: "COMPLETED", updatedAt: Timestamp.now() });
    }
  });

  await batch.commit();
  await writeAuditLog("ACADEMIC_YEAR_ACTIVATED", caller.uid, caller.role, academicYearId);
  return { success: true, activeAcademicYearId: academicYearId };
}

/**
 * Manual Student Promotion (Section 16: Bulk & Single support, historical attendance preserved)
 */
export async function handleAdminPromoteStudents(authData: any, data: any) {
  const caller = await assertRole(authData, ["ADMIN"]);
  const { studentIds, targetAcademicYearId, targetClassId, action } = data;

  if (!Array.isArray(studentIds) || studentIds.length === 0 || !action) {
    throw new HttpsError("invalid-argument", "studentIds array and action ('PROMOTE' | 'COMPLETED' | 'DISCONTINUED') are required.");
  }

  let targetClassName = "";
  if (action === "PROMOTE") {
    if (!targetAcademicYearId || !targetClassId) {
      throw new HttpsError("invalid-argument", "targetAcademicYearId and targetClassId are required for promotion.");
    }
    const cDoc = await db.collection("classes").doc(targetClassId).get();
    targetClassName = cDoc.exists ? cDoc.data()?.name : targetClassId;
  }

  const batch = db.batch();
  const now = Timestamp.now();

  for (const sId of studentIds) {
    const sRef = db.collection("students").doc(sId);
    const sDoc = await sRef.get();
    if (!sDoc.exists) continue;

    const sData = sDoc.data()!;
    const previousClassId = sData.currentClassId;
    const previousAcademicYearId = sData.currentAcademicYearId;

    if (action === "PROMOTE") {
      // Close previous enrollment
      const prevEnrollments = await sRef.collection("enrollments").where("status", "==", "ACTIVE").get();
      prevEnrollments.docs.forEach((eDoc) => {
        batch.update(eDoc.ref, { status: "COMPLETED", endDate: now });
      });

      // Update student document with new class and year
      batch.update(sRef, {
        currentClassId: targetClassId,
        currentAcademicYearId: targetAcademicYearId,
        status: "ACTIVE",
        updatedAt: now,
      });

      // Add new enrollment record in subcollection (retaining full history)
      const newEnrollmentRef = sRef.collection("enrollments").doc();
      const newEnrollment: EnrollmentDoc = {
        enrollmentId: newEnrollmentRef.id,
        academicYearId: targetAcademicYearId,
        classId: targetClassId,
        className: targetClassName,
        status: "ACTIVE",
        startDate: now,
      };
      batch.set(newEnrollmentRef, newEnrollment);
    } else if (action === "COMPLETED") {
      batch.update(sRef, { status: "COMPLETED", updatedAt: now });
      const activeEnrollments = await sRef.collection("enrollments").where("status", "==", "ACTIVE").get();
      activeEnrollments.docs.forEach((eDoc) => {
        batch.update(eDoc.ref, { status: "COMPLETED", endDate: now });
      });
    } else if (action === "DISCONTINUED") {
      batch.update(sRef, { status: "DISCONTINUED", updatedAt: now });
      const activeEnrollments = await sRef.collection("enrollments").where("status", "==", "ACTIVE").get();
      activeEnrollments.docs.forEach((eDoc) => {
        batch.update(eDoc.ref, { status: "DISCONTINUED", endDate: now });
      });
    }
  }

  await batch.commit();

  await writeAuditLog("STUDENT_PROMOTED", caller.uid, caller.role, "BULK", {
    studentIds,
    action,
    targetAcademicYearId,
    targetClassId,
  });

  return { success: true, count: studentIds.length, action };
}

/**
 * Expected Opportunities Management: Query pending and missed
 */
export async function handleAdminGetPendingAndMissedOpportunities(authData: any) {
  await assertRole(authData, ["ADMIN"]);

  const [pendingSnap, missedSnap] = await Promise.all([
    db.collection("expectedAttendanceOpportunities").where("status", "==", "PENDING").get(),
    db.collection("expectedAttendanceOpportunities").where("status", "==", "MISSED_DEADLINE").get(),
  ]);

  const results: any[] = [];
  pendingSnap.docs.forEach((d) => results.push({ ...d.data(), opportunityId: d.id }));
  missedSnap.docs.forEach((d) => results.push({ ...d.data(), opportunityId: d.id }));

  results.sort((a, b) => b.sessionDate.localeCompare(a.sessionDate));
  return results;
}

/**
 * On-demand creation of an expected attendance opportunity slot
 */
export async function handleAdminCreateExpectedOpportunity(authData: any, data: any) {
  const caller = await assertRole(authData, ["ADMIN"]);
  const { classId, sessionDate, slotNumber } = data;

  if (!classId || !sessionDate) {
    throw new HttpsError("invalid-argument", "classId and sessionDate (YYYY-MM-DD) are required.");
  }

  const classDoc = await db.collection("classes").doc(classId).get();
  if (!classDoc.exists) {
    throw new HttpsError("not-found", "Class not found.");
  }

  // Get active academic year
  const ayQuery = await db.collection("academicYears").where("status", "==", "ACTIVE").limit(1).get();
  const academicYearId = ayQuery.empty ? "2026_2027" : ayQuery.docs[0].id;
  const slot = typeof slotNumber === "number" ? slotNumber : 1;
  const oppId = `${academicYearId}__${classId}__${sessionDate}__slot_${slot}`;

  const oppRef = db.collection("expectedAttendanceOpportunities").doc(oppId);
  const existing = await oppRef.get();
  if (existing.exists) {
    throw new HttpsError("already-exists", `Expected opportunity slot ${slot} already exists for this class and date.`);
  }

  const oppDoc: ExpectedOpportunityDoc = {
    opportunityId: oppId,
    academicYearId,
    classId,
    className: classDoc.data()?.name || classId,
    sessionDate,
    slotNumber: slot,
    status: "PENDING",
    attendanceDeadline: computeAttendanceDeadline(sessionDate),
    allowedCompletionDeadline: computeAllowedCompletionDeadline(sessionDate),
    createdAt: Timestamp.now(),
    updatedAt: Timestamp.now(),
  };

  await oppRef.set(oppDoc);
  await writeAuditLog("EXPECTED_OPPORTUNITY_CREATED", caller.uid, caller.role, oppId, {
    classId,
    sessionDate,
    slotNumber: slot,
  });

  return oppDoc;
}

/**
 * Cancel an expected opportunity (e.g. rain holiday, school event)
 */
export async function handleAdminCancelExpectedOpportunity(authData: any, data: any) {
  const caller = await assertRole(authData, ["ADMIN"]);
  const { opportunityId, reason } = data;

  if (!opportunityId) {
    throw new HttpsError("invalid-argument", "opportunityId is required.");
  }

  const oppRef = db.collection("expectedAttendanceOpportunities").doc(opportunityId);
  const oppDoc = await oppRef.get();
  if (!oppDoc.exists) {
    throw new HttpsError("not-found", "Opportunity not found.");
  }

  if (oppDoc.data()?.status === "LOCKED" || oppDoc.data()?.status === "COMPLETED_AFTER_DEADLINE") {
    throw new HttpsError("failed-precondition", "Cannot cancel a session that has already been confirmed and locked.");
  }

  await oppRef.update({
    status: "CANCELLED",
    cancellationReason: reason || "Cancelled by Admin",
    updatedAt: Timestamp.now(),
  });

  await writeAuditLog("EXPECTED_OPPORTUNITY_CANCELLED", caller.uid, caller.role, opportunityId, { reason });
  return { success: true };
}
