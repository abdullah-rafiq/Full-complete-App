# Assist

Assist is a Flutter application for a two-sided home-services marketplace.

- **Customers** browse services and create bookings.
- **Workers (service providers)** manage jobs and must complete **document-based              verification** before accepting/starting jobs.
- **Admins** review and approve/reject worker verification submissions.
- A **Support Chat** feature calls an external AI backend (with Firebase ID token auth).

---

## Tech Stack

- **Frontend**: Flutter (Android / iOS / Web / Desktop)
- **Backend (BaaS)**: Firebase
  - Authentication (Email/Password + Google Sign-In)
  - Firestore
  - Storage (Cloudinary for images, depending on feature)
- **Routing**: `go_router`
- **Localization**: `flutter_localizations`, `intl` (English + Urdu)
- **State**: Stream-based controllers + `setState` (custom controller pattern)

---

## Features

### Customer
- **Authentication** (email/password + Google)
- **Role-based routing** (customer vs provider vs admin)
- **Bookings**: create, view, status updates
- **Support**: “Contact Us” live chat via AI backend

### Worker (Provider)
- **Worker home**: demand hints + job overview
- **Job management**: accept/start/complete flows
- **Verification workflow**: CNIC + Live Selfie + Shop/Tools photo upload
- **Verification status tracking** (pending/approved/rejected)

### Admin
- **Workers list**
- **Verification review**
- Approve/reject workers and/or individual documents

---

## Roles & Onboarding

Users are stored in Firestore under:

- `users/{uid}`

On login:
- **New user** (missing `role` in Firestore): routed to **Role Selection** (`/role`)
- **Existing user** (role exists): routed to their role-based home:
  - `customer` → `/home`
  - `provider` → `/worker`
  - `admin` → `/admin`

Roles used in code:
- `customer`
- `provider`
- `admin`

---

## Worker Verification (Document-Based)

Worker verification is **NOT** based on Firebase `emailVerified`.
It is based on verification documents and admin approval.

### Core fields (Firestore: `users/{uid}`)

These are the fields used by the app to drive verification:

- **`verificationStatus`**: `none` | `pending` | `approved` | `rejected`

Document uploads:
- **`cnicFrontImageUrl`**
- **`cnicBackImageUrl`**
- **`selfieImageUrl`**
- **`shopImageUrl`**

Per-document statuses:
- **`cnicFrontStatus`**: `none` | `pending` | `approved` | `rejected`
- **`cnicBackStatus`**: `none` | `pending` | `approved` | `rejected`
- **`selfieStatus`**: `none` | `pending` | `approved` | `rejected`
- **`shopStatus`**: `none` | `pending` | `approved` | `rejected`

Optional admin notes:
- **`verificationReason`**: string (optional)

AI-assisted CNIC extraction (optional, stored by backend):
- **`verification.cnic.extracted`** (structured extracted fields)
- **`verification.cnic.expectedMatches`** (match scores)
- **`verification.cnic.updatedAt`**

### Rules enforced in app
- Worker is “verified” only if:
  - `verificationStatus == 'approved'`
- Worker cannot accept/start jobs unless verified:
  - job actions are gated in worker controllers

---

## AI Support Chat (External Backend)

The Support/Contact chat calls an external AI backend.

- Client sends `Authorization: Bearer <Firebase ID token>`
- Base URL is configured in:
  - `lib/services/support_service.dart`

### Endpoint used by the app
- `POST /ai/support/ask`
  - JSON body: `{ "message": "..." }`
  - Response: `{ "reply": "..." }` (or similar)

### Backend notes (deployment)
The Node/Express backend is deployed separately (for example on Render).
Common environment variables used by that backend include:
- `HUGGINGFACE_API_KEY` (or `HF_TOKEN`)
- `HF_CHAT_MODEL`
- `FIREBASE_SERVICE_ACCOUNT` or `FIREBASE_SERVICE_ACCOUNT_PATH`

If your backend logs show:
- `ReferenceError: isReplyInLanguage is not defined`
then that helper must be defined or removed in the backend code.

---

## Firestore Collections (Observed in App)

This section lists collections the Flutter app reads/writes (based on code references).

### `users/{uid}`
Used for:
- role (`customer/provider/admin`)
- profile info
- worker verification fields
- location fields (`locationLat`, `locationLng`)

Common fields (varies by role):
- `name`, `email`, `phone`
- `role`: `customer` | `provider` | `admin`
- `profileImageUrl`
- `verified` (legacy/general flag; providers should use `verificationStatus`)
- `verificationStatus` + per-document fields (providers)
- `walletBalance`
- `status` (e.g., Active/Suspended)

### `bookings/{bookingId}`
Used for:
- customer/provider assignments
- booking status transitions
- reporting and worker demand hints

Common fields (observed):
- `providerId`
- `customerId`
- `status` (e.g., requested/accepted/inProgress/completed/cancelled)
- `price`
- timestamps (`createdAt`, scheduled time)

### `reviews/{reviewId}`
Used for:
- provider rating calculations
- featured providers ranking

### `chats/{chatId}`
Used for:
- customer-worker messaging
- `participants`: `[customerId, providerId]`
- `updatedAt`

### `support_conversations/{threadId}` (created by backend)
Used for:
- storing support threads and messages
- `support_conversations/{id}/messages/{messageId}`

### `admin_notifications/{id}`
Used for:
- notifying admins about new users/roles

---

## Project Structure

```text
lib/
├── auth/           Authentication screens (login, signup, role selection)
├── common/         Shared widgets/pages (profile, settings, contact/support)
├── controllers/    Controllers (verification, profile, admin actions, etc.)
├── models/         Data models (AppUser, Booking, Review, ...)
├── services/       Firebase + HTTP services (auth, user, support_service, ...)
├── user/           Customer features (home, bookings, etc.)
├── worker/         Worker features (home, jobs, earnings, verification)
└── main.dart       App entry point