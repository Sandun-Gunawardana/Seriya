import { cert, getApp, getApps, initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore } from "firebase-admin/firestore";

import { requireEnv } from "./env.js";

const firebaseApp =
  getApps().length > 0
    ? getApp()
    : initializeApp({
        credential: cert({
          projectId: requireEnv("FIREBASE_PROJECT_ID"),
          clientEmail: requireEnv("FIREBASE_CLIENT_EMAIL"),
          privateKey: requireEnv("FIREBASE_PRIVATE_KEY").replace(/\\n/g, "\n"),
        }),
      });

export const adminAuth = getAuth(firebaseApp);
export const adminFirestore = getFirestore(firebaseApp);
