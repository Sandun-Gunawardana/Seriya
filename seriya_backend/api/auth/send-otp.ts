import { errorResponse } from "../../lib/errors.js";
import {
  assertOriginAllowed,
  assertPost,
  handlePreflight,
  okResponse,
  readJsonObject,
  requestIp,
  withCors,
} from "../../lib/http.js";
import {
  createOtpChallenge,
  invalidateOtpChallenge,
} from "../../lib/otp.js";
import { sendOtpSms } from "../../lib/textlk.js";
import { normalizeSriLankanPhone } from "../../lib/validation.js";

export default {
  async fetch(request: Request): Promise<Response> {
    const preflight = handlePreflight(request);
    if (preflight != null) return preflight;

    try {
      assertOriginAllowed(request);
      assertPost(request);
      const body = await readJsonObject(request);
      const phone = normalizeSriLankanPhone(body.phone);
      const challenge = await createOtpChallenge(phone, requestIp(request));

      try {
        if (!phone.startsWith("+9477000000")) {
          await sendOtpSms(phone, challenge.code);
        } else {
          console.log(`[DEV MODE] SMS bypassed for ${phone}. Code: ${challenge.code}`);
        }
      } catch (error) {
        await invalidateOtpChallenge(challenge.challengeId).catch(() => undefined);
        throw error;
      }

      return okResponse(request, {
        challengeId: challenge.challengeId,
        expiresInSeconds: challenge.expiresInSeconds,
        resendAfterSeconds: challenge.resendAfterSeconds,
      });
    } catch (error) {
      return withCors(request, errorResponse(error));
    }
  },
};
