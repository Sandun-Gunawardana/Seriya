# Seriya authentication backend

This Vercel backend sends one-time passwords through Text.lk and exchanges a
verified OTP for a Firebase custom authentication token.

## API routes

- `GET /api/health` checks that the deployed function is reachable.
- `POST /api/auth/send-otp` accepts `{ "phone": "+94761234567" }`.
- `POST /api/auth/verify-otp` verifies the code for sign-in or registration.

OTP values are generated with Node's cryptographic random generator. Only an
HMAC hash is stored in Firestore, codes expire after five minutes, and send and
verification attempts are rate limited.

## Required Vercel environment variables

Copy the names from `.env.example` into Vercel. Never commit their real values.
`FIREBASE_PRIVATE_KEY` may contain either real line breaks or escaped `\n`;
the backend supports both formats.

Use an approved Text.lk sender ID for real delivery. `TextLKDemo` is suitable
only while initially testing the Text.lk account.

## Check and deploy

Use Node.js 24 LTS. Node.js 26 is not currently a supported Vercel build and
Functions runtime for this project.

```bash
node --version
npm run check
npx vercel --prod
```

After deployment, test the non-secret health route:

```bash
curl https://seriya-backend.vercel.app/api/health
```

The expected response is:

```json
{"status":"ok","service":"seriya-auth"}
```

## Flutter configuration

The Flutter app uses `https://seriya-backend.vercel.app` by default. To use a
different deployment without changing source code, run:

```bash
flutter run --dart-define=AUTH_API_BASE_URL=https://your-domain.example
```
