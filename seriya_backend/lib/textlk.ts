import { requireEnv } from "./env.js";
import { ApiError } from "./errors.js";

interface TextLkResponse {
  status?: boolean | string;
  message?: string;
  data?: unknown;
}

export async function sendOtpSms(phone: string, code: string): Promise<void> {
  let response: Response;
  try {
    response = await fetch("https://app.text.lk/api/v3/sms/send", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${requireEnv("TEXTLK_API_TOKEN")}`,
        "Content-Type": "application/json",
        Accept: "application/json",
      },
      body: JSON.stringify({
        recipient: phone.replace(/^\+/, ""),
        sender_id: requireEnv("TEXTLK_SENDER_ID"),
        type: "plain",
        message: `Your Seriya verification code is ${code}. It expires in 5 minutes. Do not share this code.`,
      }),
      signal: AbortSignal.timeout(10_000),
    });
  } catch (error) {
    console.error("Text.lk request failed", error);
    throw new ApiError(
      502,
      "SMS_PROVIDER_UNAVAILABLE",
      "The verification message could not be sent. Please try again.",
    );
  }

  let payload: TextLkResponse = {};
  try {
    payload = (await response.json()) as TextLkResponse;
  } catch {
    // The HTTP status still determines failure when the provider returns no JSON.
  }

  const acceptedStatus = payload.status === true || payload.status === "success";
  if (!response.ok || !acceptedStatus) {
    console.error("Text.lk rejected SMS", {
      httpStatus: response.status,
      providerMessage: payload.message,
    });
    throw new ApiError(
      502,
      "SMS_DELIVERY_FAILED",
      "The verification message could not be sent. Please try again.",
    );
  }
}
