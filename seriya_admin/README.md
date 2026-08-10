# Seriya Admin

React and TypeScript web dashboard for Seriya transport administrators.

## Current features

- Firebase Email/Password administrator sign-in
- Approved-admin authorization check
- Live Firestore registration list
- Search and status filtering
- Passenger/driver approval and rejection
- Reversible approval decisions with confirmation

## First administrator

Create the administrator in Firebase Authentication using Email/Password. Then
create a Firestore `users/{uid}` document using the same Firebase Authentication
UID and set:

```text
status = approved
approvedRole = admin
fullName = Seriya Administrator
email = the same Firebase Authentication email
```

Only do this manually for the initial trusted administrator. The public
registration form cannot request the admin role.

## Development

```bash
npm install
npm run dev
```

Open `http://localhost:5174`. The administrator's Firebase email is entered in
the dashboard's Username field.

## Production

Deploy the generated `dist` directory through Vercel or another static web host.
