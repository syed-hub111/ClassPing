import * as admin from "firebase-admin";
import { Timestamp } from "firebase-admin/firestore";

if (!admin.apps.length) {
  admin.initializeApp({
    projectId: process.env.GCLOUD_PROJECT || "class-ping-66823",
  });
}

const db = admin.firestore();
const auth = admin.auth();

async function seedAdmin() {
  const email = process.env.ADMIN_EMAIL || process.argv[2] || "admin@classping.com";
  const password = process.env.ADMIN_PASSWORD || process.argv[3] || "Admin@123456";
  const name = process.env.ADMIN_NAME || process.argv[4] || "Head Administrator";

  console.log(`Pre-authorizing Application Admin: ${email} (${name})...`);

  let userRecord;
  try {
    userRecord = await auth.getUserByEmail(email);
    console.log(`Found existing Firebase Auth user: ${userRecord.uid}`);
  } catch (err: any) {
    if (err.code === "auth/user-not-found") {
      userRecord = await auth.createUser({
        email,
        password,
        displayName: name,
      });
      console.log(`Created new Firebase Auth user: ${userRecord.uid}`);
    } else {
      throw err;
    }
  }

  const uid = userRecord.uid;

  // 1. Write admins/{uid}
  await db.collection("admins").doc(uid).set(
    {
      uid,
      name,
      email,
      status: "ACTIVE",
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    },
    { merge: true }
  );

  // 2. Write users/{uid}
  await db.collection("users").doc(uid).set(
    {
      uid,
      role: "ADMIN",
      accountStatus: "ACTIVE",
      displayName: name,
      email,
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    },
    { merge: true }
  );

  // 3. Set custom claims
  await auth.setCustomUserClaims(uid, { role: "ADMIN" });

  console.log("=================================================");
  console.log("SUCCESS: Administrator account pre-authorized!");
  console.log(`UID:   ${uid}`);
  console.log(`Email: ${email}`);
  console.log(`Role:  ADMIN`);
  console.log("=================================================");
}

seedAdmin().catch((err) => {
  console.error("Failed to seed admin:", err);
  process.exit(1);
});
