# Steel — Convex Backend Setup

> How to initialize and deploy the Steel Convex backend.

For full project details see the main [README](../README.md).

---

## Overview

Steel uses [Convex](https://convex.dev) as its backend database. Convex provides:
- **Real-time subscriptions** — Profile updates push instantly to connected devices
- **Type-safe queries** — Schema-validated TypeScript functions
- **Serverless functions** — No infra to manage
- **Built-in auth** — Integrates with Clerk, Auth0, or custom auth

---

## Prerequisites

- [Node.js](https://nodejs.org/) v18+ installed
- A [Convex account](https://dashboard.convex.dev) (free tier available)
- npm or yarn

---

## Quick Start

### 1. Install dependencies

```bash
cd backend
npm install
```

### 2. Initialize Convex project

```bash
npx convex dev
```

This will:
- Prompt you to log in to Convex (opens browser)
- Ask you to create a new project or link an existing one
- Name it something like `steel-app`
- Deploy the schema and functions automatically
- Start watching for changes (hot deploy on save)

### 3. Get your deployment URL

After `npx convex dev` runs, it creates a `.env.local` file with:
```
CONVEX_DEPLOYMENT=dev:your-project-name
```

Copy the deployment URL from the Convex dashboard. You'll need it for the Flutter app.

### 4. Connect Flutter to Convex

Update the service URLs in `lib/services/profile_service.dart`:
```dart
ProfileService(
  baseUrl: 'https://your-project.convex.cloud',
)
```

> **Note:** For MVP, the Flutter app uses stub mode (mock data). The Convex backend is ready for when you switch to production.

---

## Database Schema

Defined in `backend/convex/schema.ts`. Five tables:

| Table | Purpose |
|-------|---------|
| `profiles` | Steel member profiles (name, bio, socials, privacy settings, NFC tag binding) |
| `nfc_shares` | Every NFC tap event for viral loop analytics |
| `connections` | Mutual connections between members |
| `verification` | SMS PIN verification sessions (5min expiry, 3 attempts max) |
| `waitlist` | Pre-launch email signups from steel.html |

### Key Indexes

- `profiles.by_slug` — Fast lookup for `steel.app/p/{slug}` URLs
- `profiles.by_nfcTagId` — Instant profile lookup on NFC tap
- `nfc_shares.by_sharer` — Share history for analytics dashboard
- `verification.by_profileId` — Active verification session lookup

---

## Convex Functions

### Profiles (`convex/profiles.ts`)
- `getBySlug(slug)` — Public profile page lookup
- `getByNfcTag(nfcTagId)` — NFC tap → profile
- `create(...)` — New member signup
- `update(id, fields)` — Edit profile
- `bindNfcTag(profileId, nfcTagId)` — Link NFC tag to profile

### NFC Shares (`convex/nfcShares.ts`)
- `logShare(...)` — Record every NFC tap event
- `getBySharer(profileId)` — Tap analytics for a member
- `markRecipientJoined(shareId)` — Track viral conversion

### Verification (`convex/verification.ts`)
- `createSession(phone, profileId)` — Send PIN, start 5-min timer
- `verifyPin(profileId, pin)` — Check PIN (max 3 attempts)
- `getStatus(profileId)` — Check if session is active/expired

### Connections (`convex/connections.ts`)
- `request(from, to)` — Send connection request
- `accept(connectionId)` — Accept connection
- `getForProfile(profileId)` — List all connections

### Waitlist (`convex/waitlist.ts`)
- `join(email, source)` — Add to waitlist
- `checkEmail(email)` — Check if already signed up

---

## Production Checklist

Before going live, you'll need to:

- [ ] **SMS Integration:** Add Twilio action in `convex/verification.ts` to actually send PINs
- [ ] **Auth:** Set up Convex Auth (Clerk or custom) for user authentication
- [ ] **PIN Hashing:** Hash PINs before storing (bcrypt or similar via Convex action)
- [ ] **Rate Limiting:** Add rate limits to verification and waitlist endpoints
- [ ] **File Storage:** Use Convex file storage for profile avatar uploads
- [ ] **Environment Variables:** Set `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN` in Convex dashboard

---

## Deploying to Production

```bash
cd backend
npx convex deploy
```

This deploys your schema and functions to your production Convex instance.

---

## Useful Commands

```bash
# Start dev server (hot deploys on file change)
npx convex dev

# Deploy to production
npx convex deploy

# Open Convex dashboard
npx convex dashboard

# View logs
npx convex logs

# Run a function manually
npx convex run waitlist:getAll
```
