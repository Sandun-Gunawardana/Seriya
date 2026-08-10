import { FirebaseAuthError } from "firebase-admin/auth";
import { FieldValue } from "firebase-admin/firestore";

import { ApiError } from "./errors.js";
import { adminAuth, adminFirestore } from "./firebase-admin.js";
import type { RegistrationProfile } from "./validation.js";

export interface AuthenticationResult {
  customToken: string;
  status: string;
  approvedRole: string | null;
}

export async function completeRegistration(
  phone: string,
  profile: RegistrationProfile,
): Promise<AuthenticationResult> {
  let user = await findUserByPhone(phone);
  let createdUser = false;

  if (user == null) {
    user = await adminAuth.createUser({
      phoneNumber: phone,
      displayName: profile.fullName,
      ...(profile.email ? { email: profile.email } : {}),
    });
    createdUser = true;
  }

  const profileReference = adminFirestore.collection("users").doc(user.uid);
  const existingProfile = await profileReference.get();
  if (existingProfile.exists) {
    throw new ApiError(
      409,
      "ACCOUNT_EXISTS",
      "An account already exists for this mobile number. Sign in instead.",
    );
  }

  try {
    await profileReference.create({
      fullName: profile.fullName,
      employeeId: profile.employeeId,
      email: profile.email || null,
      phone,
      requestedRole: profile.requestedRole,
      approvedRole: null,
      status: "pending",
      vehicleId: null,
      routeId: null,
      authProvider: "textlk_otp",
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
  } catch (error) {
    if (createdUser) {
      await adminAuth.deleteUser(user.uid).catch(() => undefined);
    }
    throw error;
  }

  return createAuthenticationResult(user.uid, "pending", null);
}

export async function completeSignIn(
  phone: string,
): Promise<AuthenticationResult> {
  const user = await findUserByPhone(phone);
  if (user == null) {
    throw new ApiError(
      404,
      "ACCOUNT_NOT_FOUND",
      "No account exists for this mobile number. Create an account first.",
    );
  }

  const profileSnapshot = await adminFirestore
    .collection("users")
    .doc(user.uid)
    .get();
  if (!profileSnapshot.exists) {
    throw new ApiError(
      404,
      "PROFILE_NOT_FOUND",
      "Your account profile is unavailable. Contact the administrator.",
    );
  }

  const profile = profileSnapshot.data() ?? {};
  return createAuthenticationResult(
    user.uid,
    typeof profile.status === "string" ? profile.status : "pending",
    typeof profile.approvedRole === "string" ? profile.approvedRole : null,
  );
}

async function createAuthenticationResult(
  uid: string,
  status: string,
  approvedRole: string | null,
): Promise<AuthenticationResult> {
  const customToken = await adminAuth.createCustomToken(uid);
  return { customToken, status, approvedRole };
}

async function findUserByPhone(
  phone: string,
): Promise<Awaited<ReturnType<typeof adminAuth.getUserByPhoneNumber>> | null> {
  try {
    return await adminAuth.getUserByPhoneNumber(phone);
  } catch (error) {
    if (
      error instanceof FirebaseAuthError &&
      error.code === "auth/user-not-found"
    ) {
      return null;
    }
    throw error;
  }
}
