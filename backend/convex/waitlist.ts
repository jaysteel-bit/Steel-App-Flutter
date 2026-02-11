// waitlist.ts
// Steel by Exo — Waitlist (from steel.html)
//
// Captures email signups from the Steel landing page
// and from NFC share recipients who want to join.

import { query, mutation } from "./_generated/server";
import { v } from "convex/values";

// ─── Queries ──────────────────────────────────────────────

/** Check if an email is already on the waitlist */
export const checkEmail = query({
  args: { email: v.string() },
  handler: async (ctx, args) => {
    const entry = await ctx.db
      .query("waitlist")
      .withIndex("by_email", (q) => q.eq("email", args.email.toLowerCase()))
      .first();
    return { exists: !!entry };
  },
});

/** Get all waitlist entries (admin) */
export const getAll = query({
  handler: async (ctx) => {
    return await ctx.db.query("waitlist").order("desc").collect();
  },
});

// ─── Mutations ────────────────────────────────────────────

/** Add an email to the waitlist */
export const join = mutation({
  args: {
    email: v.string(),
    name: v.optional(v.string()),
    source: v.optional(v.string()),
    referredBy: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    const email = args.email.toLowerCase();

    // Check for duplicate
    const existing = await ctx.db
      .query("waitlist")
      .withIndex("by_email", (q) => q.eq("email", email))
      .first();

    if (existing) {
      return { id: existing._id, alreadyExists: true };
    }

    const id = await ctx.db.insert("waitlist", {
      email,
      name: args.name,
      source: args.source ?? "website",
      referredBy: args.referredBy,
      createdAt: Date.now(),
    });

    return { id, alreadyExists: false };
  },
});
