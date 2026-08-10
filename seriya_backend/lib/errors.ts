export class ApiError extends Error {
  constructor(
    readonly status: number,
    readonly code: string,
    message: string,
    readonly retryAfterSeconds?: number,
  ) {
    super(message);
    this.name = "ApiError";
  }
}

export function errorResponse(error: unknown): Response {
  if (error instanceof ApiError) {
    return jsonResponse(
      {
        error: {
          code: error.code,
          message: error.message,
          ...(error.retryAfterSeconds == null
            ? {}
            : { retryAfterSeconds: error.retryAfterSeconds }),
        },
      },
      error.status,
      error.retryAfterSeconds,
    );
  }

  console.error("Unhandled API error", error);
  return jsonResponse(
    {
      error: {
        code: "INTERNAL_ERROR",
        message: "The request could not be completed. Please try again.",
      },
    },
    500,
  );
}

export function jsonResponse(
  body: unknown,
  status = 200,
  retryAfterSeconds?: number,
): Response {
  const headers = new Headers({ "Content-Type": "application/json" });
  if (retryAfterSeconds != null) {
    headers.set("Retry-After", retryAfterSeconds.toString());
  }
  return new Response(JSON.stringify(body), { status, headers });
}
