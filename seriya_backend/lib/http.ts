import { allowedOrigins } from "./env.js";
import { ApiError, jsonResponse } from "./errors.js";

export function handlePreflight(request: Request): Response | null {
  if (request.method !== "OPTIONS") return null;
  return withCors(request, new Response(null, { status: 204 }));
}

export function assertPost(request: Request): void {
  if (request.method !== "POST") {
    throw new ApiError(405, "METHOD_NOT_ALLOWED", "Use a POST request.");
  }
}

export async function readJsonObject(
  request: Request,
): Promise<Record<string, unknown>> {
  const contentLength = Number(request.headers.get("content-length") ?? "0");
  if (contentLength > 16_384) {
    throw new ApiError(413, "REQUEST_TOO_LARGE", "The request is too large.");
  }

  try {
    const value: unknown = await request.json();
    if (value == null || Array.isArray(value) || typeof value !== "object") {
      throw new Error("Body is not an object");
    }
    return value as Record<string, unknown>;
  } catch {
    throw new ApiError(400, "INVALID_JSON", "Send a valid JSON request body.");
  }
}

export function requestIp(request: Request): string {
  return (
    request.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ||
    request.headers.get("x-real-ip")?.trim() ||
    "unknown"
  );
}

export function assertOriginAllowed(request: Request): void {
  const origin = request.headers.get("origin");
  if (!origin) return;

  const configuredOrigins = allowedOrigins();
  if (!configuredOrigins.includes(origin)) {
    throw new ApiError(403, "ORIGIN_NOT_ALLOWED", "This origin is not allowed.");
  }
}

export function withCors(request: Request, response: Response): Response {
  const origin = request.headers.get("origin");
  const configuredOrigins = allowedOrigins();
  if (origin && configuredOrigins.includes(origin)) {
    response.headers.set("Access-Control-Allow-Origin", origin);
    response.headers.set("Vary", "Origin");
  }
  response.headers.set("Access-Control-Allow-Headers", "Content-Type");
  response.headers.set("Access-Control-Allow-Methods", "POST, OPTIONS");
  return response;
}

export function okResponse(request: Request, body: unknown): Response {
  return withCors(request, jsonResponse(body));
}
