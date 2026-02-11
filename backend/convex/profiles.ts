// profiles.ts
// Steel by Exo — Profile Queries & Mutations

import { query, mutation } from "./_generated/server";
import { v } from "convex/values";

// ─── Queries ──────────────────────────────────────────────

/** Get a profile by its slug (public profile page) */
export const getBySlug = query({
  args: { slug: v.string() },
  handler: async (ctx, args) => {
    return await ctx.db
      .query("profiles")
      .withIndex("by_slug", (q) => q.eq("slug", args.slug))
      .first();
  },
});

/** Get a profile by ID (authenticated) */
export const get = query({
  args: { id: v.id("profiles") },
  handler: async (ctx, args) => {
    return await ctx.db.get(args.id);
  },
});

/** Get profile by auth ID (for login) */
export const getByAuthId = query({
  args: { authId: v.string() },
  handler: async (ctx, args) => {
    return await ctx.db
      .query("profiles")
      .withIndex("by_authId", (q) => q.eq("authId", args.authId))
      .first();
  },
});

/** Get profile by NFC tag ID (for tap lookup) */
export const getByNfcTag = query({
  args: { nfcTagId: v.string() },
  handler: async (ctx, args) => {
    return await ctx.db
      .query("profiles")
      .withIndex("by_nfcTagId", (q) => q.eq("nfcTagId", args.nfcTagId))
      .first();
  },
});

// ─── Mutations ────────────────────────────────────────────

/** Create a new Steel profile */
export const create = mutation({
  args: {
    name: v.string(),
    slug: v.string(),
    title: v.optional(v.string()),
    company: v.optional(v.string()),
    bio: v.optional(v.string()),
    email: v.optional(v.string()),
    phone: v.optional(v.string()),
    tier: v.string(),
    memberId: v.string(),
    privacyMode: v.string(),
    requirePin: v.boolean(),
    authProvider: v.optional(v.string()),
    authId: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    // Check slug uniqueness
    const existing = await ctx.db
      .query("profiles")
      .withIndex("by_slug", (q) => q.eq("slug", args.slug))
      .first();
    if (existing) {
      throw new Error(`Slug "${args.slug}" is already taken`);
    }

    const now = Date.now();
    return await ctx.db.insert("profiles", {
      ...args,
      socials: [],
      avatarUrl: undefined,
      nfcTagId: undefined,
      createdAt: now,
      updatedAt: now,
    });
  },
});

/** Update profile fields */
export const update = mutation({
  args: {
    id: v.id("profiles"),
    name: v.optional(v.string()),
    title: v.optional(v.string()),
    company: v.optional(v.string()),
    bio: v.optional(v.string()),
    email: v.optional(v.string()),
    phone: v.optional(v.string()),
    avatarUrl: v.optional(v.string()),
    privacyMode: v.optional(v.string()),
    requirePin: v.optional(v.boolean()),
    socials: v.optional(
      v.array(
        v.object({
          platform: v.string(),
          url: v.string(),
        })
      )
    ),
  },
  handler: async (ctx, args) => {
    const { id, ...fields } = args;
    // Filter out undefined values
    const updates: Record<string, unknown> = { updatedAt: Date.now() };
    for (const [key, value] of Object.entries(fields)) {
      if (value !== undefined) {
        updates[key] = value;
      }
    }
    await ctx.db.patch(id, updates);
  },
});

/** Bind an NFC tag to a profile */
export const bindNfcTag = mutation({
  args: {
    profileId: v.id("profiles"),
    nfcTagId: v.string(),
  },
  handler: async (ctx, args) => {
    await ctx.db.patch(args.profileId, {
      nfcTagId: args.nfcTagId,
      updatedAt: Date.now(),
    });
  },
});
