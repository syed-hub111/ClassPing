import { Timestamp } from "firebase-admin/firestore";
import { db, writeAuditLog } from "../utils/auth";
import { formatDateKey, getDayName, computeAttendanceDeadline, computeAllowedCompletionDeadline } from "../utils/dates";
import { ExpectedOpportunityDoc } from "../types";

/**
 * Scheduled job: Generates expected attendance opportunities for active classes on their operating days
 */
export async function runDailyExpectedOpportunitiesGeneration(): Promise<{ createdCount: number }> {
  const now = new Date();
  const todayKey = formatDateKey(now);
  const todayDayName = getDayName(now);

  // Find active academic year
  const ayQuery = await db.collection("academicYears").where("status", "==", "ACTIVE").limit(1).get();
  if (ayQuery.empty) {
    console.log("No active academic year found. Skipping daily expected opportunities generation.");
    return { createdCount: 0 };
  }
  const academicYearId = ayQuery.docs[0].id;

  // Find active classes
  const classesSnap = await db.collection("classes").where("status", "==", "ACTIVE").get();
  let createdCount = 0;

  for (const classDoc of classesSnap.docs) {
    const classData = classDoc.data();
    const operatingDays: string[] = classData.operatingDays || ["MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY"];

    // Check if class operates today
    if (!operatingDays.includes(todayDayName)) {
      continue;
    }

    const sessionsCount = typeof classData.expectedSessionsPerDay === "number" ? classData.expectedSessionsPerDay : 1;

    for (let slot = 1; slot <= sessionsCount; slot++) {
      const oppId = `${academicYearId}__${classDoc.id}__${todayKey}__slot_${slot}`;
      const oppRef = db.collection("expectedAttendanceOpportunities").doc(oppId);
      const existing = await oppRef.get();

      if (!existing.exists) {
        const oppDoc: ExpectedOpportunityDoc = {
          opportunityId: oppId,
          academicYearId,
          classId: classDoc.id,
          className: classData.name || classDoc.id,
          sessionDate: todayKey,
          slotNumber: slot,
          status: "PENDING",
          attendanceDeadline: computeAttendanceDeadline(todayKey),
          allowedCompletionDeadline: computeAllowedCompletionDeadline(todayKey),
          createdAt: Timestamp.now(),
          updatedAt: Timestamp.now(),
        };

        await oppRef.set(oppDoc);
        createdCount++;
      }
    }
  }

  console.log(`Generated ${createdCount} expected attendance opportunities for ${todayKey} (${todayDayName}).`);
  return { createdCount };
}

/**
 * Scheduled job: Detects uncompleted attendance opportunities that missed the normal deadline
 * Transitions them to 'MISSED_DEADLINE'. Does NOT manufacture student absences!
 */
export async function runAttendanceDeadlineCheck(): Promise<{ missedCount: number }> {
  const now = Timestamp.now();

  const pendingSnap = await db
    .collection("expectedAttendanceOpportunities")
    .where("status", "==", "PENDING")
    .where("attendanceDeadline", "<", now)
    .get();

  let missedCount = 0;
  const batch = db.batch();

  for (const doc of pendingSnap.docs) {
    batch.update(doc.ref, {
      status: "MISSED_DEADLINE",
      missedDeadlineAt: now,
      updatedAt: now,
    });
    missedCount++;
  }

  if (missedCount > 0) {
    await batch.commit();
    await writeAuditLog("ATTENDANCE_DEADLINES_EVALUATED", "SYSTEM", "SYSTEM", "BATCH", {
      missedCount,
    });
    console.log(`Marked ${missedCount} attendance opportunities as MISSED_DEADLINE.`);
  }

  return { missedCount };
}
