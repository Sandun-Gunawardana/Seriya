import {
  completeRegistration,
  completeSignIn,
} from "../../lib/auth.js";
import { errorResponse } from "../../lib/errors.js";
import {
  assertOriginAllowed,
  assertPost,
  handlePreflight,
  okResponse,
  readJsonObject,
  withCors,
} from "../../lib/http.js";
import { verifyOtpChallenge } from "../../lib/otp.js";
import {
  requireChallengeId,
  requireMode,
  requireOtpCode,
  validateRegistrationProfile,
} from "../../lib/validation.js";

export default {
  async fetch(request: Request): Promise<Response> {
    const preflight = handlePreflight(request);
    if (preflight != null) return preflight;

    try {
      assertOriginAllowed(request);
      assertPost(request);
      const body = await readJsonObject(request);
      const challengeId = requireChallengeId(body.challengeId);
      const code = requireOtpCode(body.code);
      const mode = requireMode(body.mode);
      const profile =
        mode === "registration"
          ? validateRegistrationProfile(body.profile)
          : null;

      const phone = await verifyOtpChallenge(challengeId, code);
      const result =
        mode === "registration"
          ? await completeRegistration(phone, profile!)
          : await completeSignIn(phone);

      return okResponse(request, result);
    } catch (error) {
      return withCors(request, errorResponse(error));
    }
  },
};
