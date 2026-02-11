// verification.ts
// Steel by Exo — SMS PIN Verification
//
// Handles the private-mode verification flow:
//   1. Recipient taps NFC tag
//   2. System sends PIN to sharer's phone
//   3. Sharer tells recipient the PIN verbally
//   4. Recipient enters PIN → profile revealed
//
// Security: PINs expire after 5 minutes, max 3 attempts

import { query, mutation } from "./_generated/server";
import { v } from "convex/values";

const PIN_EXPIRY_MS = 5 * 60 * 1000; // 5 minutes
const MAX_ATTEMPTS = 3;

// ─── Queries ──────────────────────────────────────────────

/** Check verification status */
export const getStatus = query({
  args: { profileId: v.id("profiles") },
  handler: async (ctx, args) => {
    const session = await ctx.db
      .query("verification")
      .withIndex("by_profileId", (q) =>
        q.eq("profileId", args.profileId)
      )
      .order("desc")
      .first();

    if (!session) return null;

    // Check if expired
    if (Date.now() > session.expiresAt) {
      return { ...session, status: "expired" };
    }

    return session;
  },
});

// ─── Mutations ────────────────────────────────────────────

/** Create a new verification session (sends PIN via SMS) */
export const createSession = mutation({
  args: {
    phone: v.string(),
    profileId: v.id("profiles"),
  },
  handler: async (ctx, args) => {
    // Generate 4-digit PIN
    const pin = String(Math.floor(1000 + Math.random() * 9000));
    const now = Date.now();

    const sessionId = await ctx.db.insert("verification", {
      phone: args.phone,
      pin, // TODO: Hash in production
      profileId: args.profileId,
      status: "pending",
      attempts: 0,
      expiresAt: now + PIN_EXPIRY_MS,
      createdAt: now,
    });

    // TODO: Trigger Twilio SMS via Convex action
    // await ctx.scheduler.runAfter(0, internal.sms.sendPin, {
    //   phone: args.phone,
    //   pin,
    // });

    return { sessionId, expiresAt: now + PIN_EXPIRY_MS };
  },
});

/** Verify a PIN attempt */
export const verifyPin = mutation({
  args: {
    profileId: v.id("profiles"),
    pin: v.string(),
  },
  handler: async (ctx, args) => {
    const session = await ctx.db
      .query("verification")
      .withIndex("by_profileId", (q) =>
        q.eq("profileId", args.profileId)
      )
      .order("desc")
      .first();

    if (!session) {
      return { success: false, error: "no_session" };
    }

    // Check expiry
    if (Date.now() > session.expiresAt) {
      await ctx.db.patch(session._id, { status: "expired" });
      return { success: false, error: "expired" };
    }

    // Check max attempts
    if (session.attempts >= MAX_ATTEMPTS) {
      await ctx.db.patch(session._id, { status: "expired" });
      return { success: false, error: "max_attempts" };
    }

    // Increment attempts
    await ctx.db.patch(session._id, {
      attempts: session.attempts + 1,
    });

    // Check PIN
    if (session.pin === args.pin) {
      await ctx.db.patch(session._id, { status: "verified" });
      return { success: true };
    }

    return {
      success: false,
      error: "wrong_pin",
      attemptsRemaining: MAX_ATTEMPTS - (session.attempts + 1),
    };
  },
});
