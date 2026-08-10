import { jsonResponse } from "../lib/errors.js";

export default {
  fetch(): Response {
    return jsonResponse({ status: "ok", service: "seriya-auth" });
  },
};
