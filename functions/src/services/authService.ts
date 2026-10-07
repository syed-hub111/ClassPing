import { HttpsError } from "firebase-functions/v2/https";
import { Timestamp } from "firebase-admin/firestore";
import { db, auth, writeAuditLog } from "../utils/auth";
import { normalizePhoneNumber } from "../utils/dates";
import { UserProfile, ParentDoc } from "../types";

/**
 * Returns the active user profile and portal role
 */
export async function handleGetInitialUserProfile(authData: any): Promise<UserProfile> {
  if (!authData || !authData.uid) {
    throw new HttpsError("unauthenticated", "User must be authenticated.");
  }

  const uid = authData.uid;
  const userDocRef = db.collection("users").doc(uid);
  const userDoc = await userDocRef.get();

  if (userDoc.exists) {
    const data = userDoc.data()!;
    return {
      uid,
      role: data.role,
      accountStatus: data.accountStatus,
      displayName: data.displayName || "",
      email: data.email,
      phoneNumber: data.phoneNumber,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
    };
  }

  // If user document doesn't exist yet, check pre-authorized collections:
  // 1. Admin
  const adminDoc = await db.collection("admins").doc(uid).get();
  if (adminDoc.exists && adminDoc.data()?.status === "ACTIVE") {
    const adminData = adminDoc.data()!;
    const profile: UserProfile = {
      uid,
      role: "ADMIN",
      accountStatus: "ACTIVE",
      displayName: adminData.name,
      email: adminData.email,
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    };
    await userDocRef.set(profile);
    await auth.setCustomUserClaims(uid, { role: "ADMIN" });
    return profile;
  }

  // Also check admin by email if signed in via Google/Email
  if (authData.token?.email) {
    const adminQuery = await db.collection("admins").where("email", "==", authData.token.email).limit(1).get();
    if (!adminQuery.empty && adminQuery.docs[0].data().status === "ACTIVE") {
      const adminData = adminQuery.docs[0].data();
      const profile: UserProfile = {
        uid,
        role: "ADMIN",
        accountStatus: "ACTIVE",
        displayName: adminData.name,
        email: adminData.email,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      };
      await userDocRef.set(profile);
      await auth.setCustomUserClaims(uid, { role: "ADMIN" });
      return profile;
    }
  }

  // 2. Tutor
  const tutorDoc = await db.collection("tutors").doc(uid).get();
  if (tutorDoc.exists && tutorDoc.data()?.status === "ACTIVE") {
    const tutorData = tutorDoc.data()!;
    const profile: UserProfile = {
      uid,
      role: "TUTOR",
      accountStatus: "ACTIVE",
      displayName: tutorData.name,
      email: tutorData.email,
      phoneNumber: tutorData.mobileNumber,
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    };
    await userDocRef.set(profile);
    await auth.setCustomUserClaims(uid, { role: "TUTOR" });
    return profile;
  }

  // Also check tutor by email
  if (authData.token?.email) {
    const tutorQuery = await db.collection("tutors").where("email", "==", authData.token.email).limit(1).get();
    if (!tutorQuery.empty && tutorQuery.docs[0].data().status === "ACTIVE") {
      const tutorData = tutorQuery.docs[0].data();
      // Link this auth UID to the tutor document if different
      const tutorDocRef = tutorQuery.docs[0].ref;
      await tutorDocRef.update({ uid, updatedAt: Timestamp.now() });
      const profile: UserProfile = {
        uid,
        role: "TUTOR",
        accountStatus: "ACTIVE",
        displayName: tutorData.name,
        email: tutorData.email,
        phoneNumber: tutorData.mobileNumber,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      };
      await userDocRef.set(profile);
      await auth.setCustomUserClaims(uid, { role: "TUTOR" });
      return profile;
    }
  }

  // 3. Parent
  const parentDoc = await db.collection("parents").doc(uid).get();
  if (parentDoc.exists) {
    const parentData = parentDoc.data()!;
    const profile: UserProfile = {
      uid,
      role: "PARENT",
      accountStatus: parentData.accountStatus,
      displayName: parentData.name,
      email: parentData.email,
      phoneNumber: parentData.phoneNumber,
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    };
    await userDocRef.set(profile);
    await auth.setCustomUserClaims(uid, { role: "PARENT" });
    return profile;
  }

  // Unregistered user
  throw new HttpsError(
    "permission-denied",
    "No authorized account found for this user. Tutors and Admins must be pre-authorized. Parents must verify their registered phone number."
  );
}

/**
 * Verified Parent-Child Linking
 * Security: Extracts the verified phone number directly from the decoded Firebase ID Token.
 * The Flutter client is NEVER allowed to supply student IDs.
 */
export async function handleLinkParentPhone(authData: any): Promise<{ linkedCount: number; studentNames: string[] }> {
  if (!authData || !authData.uid) {
    throw new HttpsError("unauthenticated", "User must be authenticated.");
  }

  // Phone number MUST come from the verified Firebase Auth token
  const verifiedPhone = authData.token?.phone_number;
  if (!verifiedPhone) {
    throw new HttpsError(
      "failed-precondition",
      "Authentication token does not contain a verified phone number. Please complete phone verification."
    );
  }

  const uid = authData.uid;
  const normalizedPhone = normalizePhoneNumber(verifiedPhone);

  // Query all registered students matching this verified parent phone number
  const studentsQuery = await db
    .collection("students")
    .where("parentMobileNumber", "==", normalizedPhone)
    .get();

  if (studentsQuery.empty) {
    throw new HttpsError(
      "not-found",
      "No registered students found matching this phone number. Please contact your tuition administrator."
    );
  }

  const studentIds: string[] = [];
  const studentNames: string[] = [];
  let parentName = authData.token?.name || "Parent";

  const batch = db.batch();

  for (const doc of studentsQuery.docs) {
    const data = doc.data();
    studentIds.push(doc.id);
    studentNames.push(data.name);
    if (data.parentName && parentName === "Parent") {
      parentName = data.parentName;
    }

    // Link parent UID into student's parentIds array if not already present
    const currentParentIds: string[] = data.parentIds || [];
    if (!currentParentIds.includes(uid)) {
      batch.update(doc.ref, {
        parentIds: [...currentParentIds, uid],
        updatedAt: Timestamp.now(),
      });
    }
  }

  // Create/Update parent document
  const parentRef = db.collection("parents").doc(uid);
  const parentData: ParentDoc = {
    uid,
    name: parentName,
    phoneNumber: normalizedPhone,
    email: authData.token?.email,
    linkedStudentIds: studentIds,
    accountStatus: "ACTIVE",
    createdAt: Timestamp.now(),
    updatedAt: Timestamp.now(),
  };
  batch.set(parentRef, parentData, { merge: true });

  // Update user document
  const userRef = db.collection("users").doc(uid);
  const userProfile: UserProfile = {
    uid,
    role: "PARENT",
    accountStatus: "ACTIVE",
    displayName: parentName,
    email: authData.token?.email,
    phoneNumber: normalizedPhone,
    createdAt: Timestamp.now(),
    updatedAt: Timestamp.now(),
  };
  batch.set(userRef, userProfile, { merge: true });

  await batch.commit();

  // Set custom user claim
  await auth.setCustomUserClaims(uid, { role: "PARENT" });

  // Audit log
  await writeAuditLog("PARENT_PHONE_VERIFIED_AND_LINKED", uid, "PARENT", uid, {
    phoneNumber: normalizedPhone,
    linkedStudentIds: studentIds,
  });

  return {
    linkedCount: studentIds.length,
    studentNames,
  };
}
