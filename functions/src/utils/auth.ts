import * as admin from "firebase-admin";
import { HttpsError } from "firebase-functions/v2/https";
import { Timestamp } from "firebase-admin/firestore";
import { UserRole, AuditLogDoc } from "../types";

// Initialize admin app if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

export const db = admin.firestore();
export const auth = admin.auth();
export const messaging = admin.messaging();

export interface VerifiedCaller {
  uid: string;
  role: UserRole;
  email?: string;
  phoneNumber?: string;
  displayName?: string;
}

/**
 * Asserts caller is authenticated and retrieves their verified user document/role from Firestore
 */
export async function assertCaller(authData: any): Promise<VerifiedCaller> {
  if (!authData || !authData.uid) {
    throw new HttpsError("unauthenticated", "User must be authenticated to perform this operation.");
  }

  const uid = authData.uid;

  // Check custom claim first for fast path, or fetch from Firestore users collection
  const userDoc = await db.collection("users").doc(uid).get();
  if (!userDoc.exists) {
    // Check if user is pre-authorized in admins or tutors
    const adminDoc = await db.collection("admins").doc(uid).get();
    if (adminDoc.exists && adminDoc.data()?.status === "ACTIVE") {
      return {
        uid,
        role: "ADMIN",
        email: adminDoc.data()?.email,
        displayName: adminDoc.data()?.name,
      };
    }

    const tutorDoc = await db.collection("tutors").doc(uid).get();
    if (tutorDoc.exists && tutorDoc.data()?.status === "ACTIVE") {
      return {
        uid,
        role: "TUTOR",
        email: tutorDoc.data()?.email,
        phoneNumber: tutorDoc.data()?.mobileNumber,
        displayName: tutorDoc.data()?.name,
      };
    }

    throw new HttpsError("permission-denied", "User account does not have an active profile.");
  }

  const userData = userDoc.data();
  if (userData?.accountStatus === "DISABLED") {
    throw new HttpsError("permission-denied", "This account has been disabled.");
  }

  return {
    uid,
    role: userData?.role as UserRole,
    email: userData?.email,
    phoneNumber: userData?.phoneNumber,
    displayName: userData?.displayName,
  };
}

/**
 * Asserts that the caller possesses one of the allowed roles
 */
export async function assertRole(authData: any, allowedRoles: UserRole[]): Promise<VerifiedCaller> {
  const caller = await assertCaller(authData);
  if (!allowedRoles.includes(caller.role)) {
    throw new HttpsError("permission-denied", `Operation requires role: ${allowedRoles.join(" or ")}.`);
  }
  return caller;
}

/**
 * Appends an audit log entry in the auditLogs collection
 */
export async function writeAuditLog(
  action: string,
  performedByUid: string,
  performedByRole: string,
  targetId: string,
  metadata: Record<string, any> = {}
): Promise<void> {
  const logRef = db.collection("auditLogs").doc();
  const log: AuditLogDoc = {
    logId: logRef.id,
    action,
    performedByUid,
    performedByRole,
    targetId,
    timestamp: Timestamp.now(),
    metadata,
  };
  await logRef.set(log);
}
