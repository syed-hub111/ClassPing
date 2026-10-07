import { Timestamp } from "firebase-admin/firestore";
import { db, messaging } from "../utils/auth";
import { StudentAttendanceStatus, NotificationDoc } from "../types";

export interface AttendanceNotificationRequest {
  attendanceSessionId: string;
  subject: string;
  tutorName: string;
  tutorPhoneNumber: string;
  studentRecords: Array<{
    studentId: string;
    studentName: string;
    status: StudentAttendanceStatus;
  }>;
}

/**
 * Generates and stores notifications for all parents of students in a confirmed attendance session,
 * and triggers FCM push notifications to parents.
 */
export async function dispatchAttendanceNotifications(req: AttendanceNotificationRequest): Promise<void> {
  const { attendanceSessionId, subject, tutorName, tutorPhoneNumber, studentRecords } = req;

  for (const record of studentRecords) {
    const studentDoc = await db.collection("students").doc(record.studentId).get();
    if (!studentDoc.exists) continue;

    const sData = studentDoc.data()!;
    const parentIds: string[] = sData.parentIds || [];
    const parentName = sData.parentName || "Parent";

    // Format message per Section 22
    let statusText = "present";
    if (record.status === "LATE") statusText = "late";
    if (record.status === "ABSENT") statusText = "absent";

    const message = `Dear ${parentName}, your child ${record.studentName} is ${statusText} for today's tuition session. Tutor: ${tutorName}. Subject: ${subject}.`;

    for (const parentUid of parentIds) {
      const notifRef = db.collection("notifications").doc();
      const notifDoc: NotificationDoc = {
        notificationId: notifRef.id,
        parentUid,
        studentId: record.studentId,
        studentName: record.studentName,
        attendanceSessionId,
        status: record.status,
        subject,
        tutorName,
        tutorPhoneNumber: tutorPhoneNumber || "",
        message,
        createdAt: Timestamp.now(),
      };

      await notifRef.set(notifDoc);

      // Fetch parent FCM tokens if available in users/{parentUid}/fcmTokens or users doc
      try {
        const userDoc = await db.collection("users").doc(parentUid).get();
        const fcmTokens: string[] = userDoc.data()?.fcmTokens || [];
        if (fcmTokens.length > 0) {
          await messaging.sendEachForMulticast({
            tokens: fcmTokens,
            notification: {
              title: `Tuition Attendance: ${record.studentName} (${record.status})`,
              body: message,
            },
            data: {
              studentId: record.studentId,
              attendanceSessionId,
              status: record.status,
              type: "ATTENDANCE_UPDATE",
            },
          });
        }
      } catch (fcmErr) {
        console.warn(`Could not dispatch FCM push to parent ${parentUid}:`, fcmErr);
      }
    }
  }
}
