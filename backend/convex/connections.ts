// connections.ts
// Steel by Exo — Member Connections
//
// Tracks mutual connections between Steel members.
// Created after a successful NFC share + optional verification.

import { query, mutation } from "./_generated/server";
import { v } from "convex/values";

// ─── Queries ──────────────────────────────────────────────

/** Get all connections for a profile */
export const getForProfile = query({
  args: { profileId: v.id("profiles") },
  handler: async (ctx, args) => {
    const asA = await ctx.db
      .query("connections")
      .withIndex("by_profileA", (q) => q.eq("profileA", args.profileId))
      .collect();
    const asB = await ctx.db
      .query("connections")
      .withIndex("by_profileB", (q) => q.eq("profileB", args.profileId))
      .collect();
    return [...asA, ...asB];
  },
});

// ─── Mutations ────────────────────────────────────────────

/** Request a connection (after NFC share) */
export const request = mutation({
  args: {
    from: v.id("profiles"),
    to: v.id("profiles"),
  },
  handler: async (ctx, args) => {
    // Check if connection already exists
    const existing = await ctx.db
      .query("connections")
      .withIndex("by_profileA", (q) => q.eq("profileA", args.from))
      .filter((q) => q.eq(q.field("profileB"), args.to))
      .first();

    if (existing) return existing._id;

    const reverse = await ctx.db
      .query("connections")
      .withIndex("by_profileA", (q) => q.eq("profileA", args.to))
      .filter((q) => q.eq(q.field("profileB"), args.from))
      .first();

    if (reverse) return reverse._id;

    return await ctx.db.insert("connections", {
      profileA: args.from,
      profileB: args.to,
      status: "pending",
      initiatedBy: args.from,
      connectedAt: undefined,
      createdAt: Date.now(),
    });
  },
});

/** Accept a connection request */
export const accept = mutation({
  args: { connectionId: v.id("connections") },
  handler: async (ctx, args) => {
    await ctx.db.patch(args.connectionId, {
      status: "connected",
      connectedAt: Date.now(),
    });
  },
});

/** Block a connection */
export const block = mutation({
  args: { connectionId: v.id("connections") },
  handler: async (ctx, args) => {
    await ctx.db.patch(args.connectionId, { status: "blocked" });
  },
});
