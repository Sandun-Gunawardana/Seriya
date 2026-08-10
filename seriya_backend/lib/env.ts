import { ApiError } from "./errors.js";

export function requireEnv(name: string): string {
  const value = process.env[name]?.trim();
  if (!value) {
    console.error(`Missing required environment variable: ${name}`);
    throw new ApiError(
      500,
      "SERVER_NOT_CONFIGURED",
      "The authentication service is not configured.",
    );
  }
  return value;
}

export function allowedOrigins(): string[] {
  return (process.env.ALLOWED_ORIGINS ?? "")
    .split(",")
    .map((origin) => origin.trim())
    .filter(Boolean);
}
