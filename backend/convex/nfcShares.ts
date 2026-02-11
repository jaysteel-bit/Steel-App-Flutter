// nfcShares.ts
// Steel by Exo — NFC Share Event Tracking (Viral Loop)
//
// Every NFC tap creates a share event for analytics:
//   - Who shared → who received
//   - Privacy mode at time of share
//   - Whether recipient verified (PIN)
//   - Whether recipient joined Steel after

import { query, mutation } from "./_generated/server";
import { v } from "convex/values";

// ─── Queries ──────────────────────────────────────────────

/** Get share history for a profile (your tap analytics) */
export const getBySharer = query({
  args: { sharerProfileId: v.id("profiles") },
  handler: async (ctx, args) => {
    return await ctx.db
      .query("nfc_shares")
      .withIndex("by_sharer", (q) =>
        q.eq("sharerProfileId", args.sharerProfileId)
      )
      .order("desc")
      .collect();
  },
});

/** Get recent shares (global feed — admin) */
export const getRecent = query({
  args: { limit: v.optional(v.number()) },
  handler: async (ctx, args) => {
    const limit = args.limit ?? 50;
    return await ctx.db
      .query("nfc_shares")
      .withIndex("by_timestamp")
      .order("desc")
      .take(limit);
  },
});

// ─── Mutations ────────────────────────────────────────────

/** Log an NFC share event */
export const logShare = mutation({
  args: {
    sharerProfileId: v.id("profiles"),
    recipientProfileId: v.optional(v.id("profiles")),
    recipientIdentifier: v.optional(v.string()),
    privacyMode: v.string(),
    wasVerified: v.boolean(),
    location: v.optional(
      v.object({
        lat: v.number(),
        lng: v.number(),
      })
    ),
    eventTag: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    return await ctx.db.insert("nfc_shares", {
      ...args,
      recipientJoined: false,
      connectBackRequested: false,
      timestamp: Date.now(),
    });
  },
});

/** Mark that a share recipient joined Steel */
export const markRecipientJoined = mutation({
  args: { shareId: v.id("nfc_shares") },
  handler: async (ctx, args) => {
    await ctx.db.patch(args.shareId, { recipientJoined: true });
  },
});

/** Mark that a connect-back was requested */
export const markConnectBack = mutation({
  args: { shareId: v.id("nfc_shares") },
  handler: async (ctx, args) => {
    await ctx.db.patch(args.shareId, { connectBackRequested: true });
  },
});
