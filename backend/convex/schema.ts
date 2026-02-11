// schema.ts
// Steel by Exo — Convex Database Schema
//
// Tables:
//   profiles     — Steel member profiles (name, bio, socials, privacy settings)
//   nfc_shares   — Every NFC tap event (viral loop analytics)
//   connections  — Mutual connections between members
//   verification — SMS PIN verification sessions
//   waitlist     — Pre-launch waitlist signups (from steel.html)

import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

export default defineSchema({
  // ─── Member Profiles ────────────────────────────────────
  profiles: defineTable({
    // Identity
    name: v.string(),
    slug: v.string(), // Unique URL slug: steel.app/p/{slug}
    title: v.optional(v.string()),
    company: v.optional(v.string()),
    bio: v.optional(v.string()),
    avatarUrl: v.optional(v.string()),

    // Contact (private by default)
    email: v.optional(v.string()),
    phone: v.optional(v.string()),

    // Social links — array of { platform, url }
    socials: v.array(
      v.object({
        platform: v.string(), // "instagram", "twitter", "linkedin", etc.
        url: v.string(),
      })
    ),

    // Membership
    tier: v.string(), // "founding" | "executive" | "standard"
    memberId: v.string(), // e.g. "STL-000001"

    // Privacy settings
    privacyMode: v.string(), // "public" | "private" | "event"
    requirePin: v.boolean(),

    // NFC tag binding
    nfcTagId: v.optional(v.string()),

    // Auth
    authProvider: v.optional(v.string()), // "phone" | "apple" | "google"
    authId: v.optional(v.string()),

    // Timestamps
    createdAt: v.number(),
    updatedAt: v.number(),
  })
    .index("by_slug", ["slug"])
    .index("by_memberId", ["memberId"])
    .index("by_authId", ["authId"])
    .index("by_nfcTagId", ["nfcTagId"]),

  // ─── NFC Share Events (Viral Loop) ─────────────────────
  nfc_shares: defineTable({
    sharerProfileId: v.id("profiles"),
    recipientProfileId: v.optional(v.id("profiles")), // null if recipient not a member
    recipientIdentifier: v.optional(v.string()), // phone or temp ID

    // Context
    privacyMode: v.string(), // mode at time of share
    wasVerified: v.boolean(), // did recipient complete PIN?
    location: v.optional(
      v.object({
        lat: v.number(),
        lng: v.number(),
      })
    ),
    eventTag: v.optional(v.string()), // event name if in event mode

    // Viral tracking
    recipientJoined: v.boolean(), // did they sign up after?
    connectBackRequested: v.boolean(),

    timestamp: v.number(),
  })
    .index("by_sharer", ["sharerProfileId"])
    .index("by_timestamp", ["timestamp"]),

  // ─── Connections ────────────────────────────────────────
  connections: defineTable({
    profileA: v.id("profiles"),
    profileB: v.id("profiles"),
    status: v.string(), // "pending" | "connected" | "blocked"
    initiatedBy: v.id("profiles"),
    connectedAt: v.optional(v.number()),
    createdAt: v.number(),
  })
    .index("by_profileA", ["profileA"])
    .index("by_profileB", ["profileB"]),

  // ─── SMS Verification Sessions ──────────────────────────
  verification: defineTable({
    phone: v.string(),
    pin: v.string(), // hashed in production
    profileId: v.id("profiles"), // who is being verified
    status: v.string(), // "pending" | "verified" | "expired"
    attempts: v.number(),
    expiresAt: v.number(),
    createdAt: v.number(),
  })
    .index("by_phone", ["phone"])
    .index("by_profileId", ["profileId"]),

  // ─── Waitlist (from steel.html) ─────────────────────────
  waitlist: defineTable({
    email: v.string(),
    name: v.optional(v.string()),
    source: v.optional(v.string()), // "website" | "nfc_share" | "referral"
    referredBy: v.optional(v.string()),
    createdAt: v.number(),
  }).index("by_email", ["email"]),
});
