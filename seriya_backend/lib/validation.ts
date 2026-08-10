import { ApiError } from "./errors.js";

export interface RegistrationProfile {
  fullName: string;
  employeeId: string;
  email: string;
  requestedRole: "passenger" | "driver";
}

export function normalizeSriLankanPhone(value: unknown): string {
  if (typeof value !== "string") {
    throw new ApiError(
      400,
      "INVALID_PHONE",
      "Enter a valid Sri Lankan mobile number.",
    );
  }

  let digits = value.replace(/\D/g, "");
  if (digits.startsWith("94")) {
    digits = digits.slice(2);
  } else if (digits.startsWith("0")) {
    digits = digits.slice(1);
  }

  const phone = `+94${digits}`;
  if (!/^\+947\d{8}$/.test(phone)) {
    throw new ApiError(
      400,
      "INVALID_PHONE",
      "Enter a valid Sri Lankan mobile number.",
    );
  }
  return phone;
}

export function requireOtpCode(value: unknown): string {
  if (typeof value !== "string" || !/^\d{6}$/.test(value)) {
    throw new ApiError(
      400,
      "INVALID_OTP_FORMAT",
      "Enter the six-digit verification code.",
    );
  }
  return value;
}

export function requireChallengeId(value: unknown): string {
  if (
    typeof value !== "string" ||
    !/^[0-9a-f]{8}-[0-9a-f-]{27,}$/i.test(value)
  ) {
    throw new ApiError(
      400,
      "INVALID_CHALLENGE",
      "Request a new verification code.",
    );
  }
  return value;
}

export function requireMode(value: unknown): "registration" | "signIn" {
  if (value === "registration" || value === "signIn") return value;
  throw new ApiError(400, "INVALID_MODE", "Invalid authentication request.");
}

export function validateRegistrationProfile(
  value: unknown,
): RegistrationProfile {
  if (value == null || Array.isArray(value) || typeof value !== "object") {
    throw new ApiError(
      400,
      "INVALID_PROFILE",
      "Enter the required registration details.",
    );
  }

  const data = value as Record<string, unknown>;
  const fullName = typeof data.fullName === "string" ? data.fullName.trim() : "";
  const employeeId =
    typeof data.employeeId === "string"
      ? data.employeeId.trim().toUpperCase()
      : "";
  const email = typeof data.email === "string" ? data.email.trim().toLowerCase() : "";
  const requestedRole = data.requestedRole;

  if (fullName.length < 3 || fullName.length > 100) {
    throw new ApiError(400, "INVALID_NAME", "Enter your full name.");
  }
  if (!/^[A-Z0-9_-]{1,30}$/.test(employeeId)) {
    throw new ApiError(400, "INVALID_EMPLOYEE_ID", "Enter a valid employee ID.");
  }
  if (email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    throw new ApiError(400, "INVALID_EMAIL", "Enter a valid email address.");
  }
  if (requestedRole !== "passenger" && requestedRole !== "driver") {
    throw new ApiError(400, "INVALID_ROLE", "Select passenger or driver.");
  }

  return { fullName, employeeId, email, requestedRole };
}
