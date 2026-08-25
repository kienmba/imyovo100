export function getSupabaseUrl() {
  // Keep NEXT_PUBLIC_* references static so Next.js can inline them in browser bundles.
  const value = process.env.NEXT_PUBLIC_SUPABASE_URL?.trim();
  if (!value) throw new Error("[config] Missing environment variable: NEXT_PUBLIC_SUPABASE_URL");
  try {
    const url = new URL(value);
    if (url.protocol !== "https:" && url.hostname !== "localhost") {
      throw new Error("Supabase URL must use HTTPS in production");
    }
    return value.replace(/\/$/, "");
  } catch (error) {
    throw new Error(`[config] Invalid NEXT_PUBLIC_SUPABASE_URL: ${error instanceof Error ? error.message : "invalid URL"}`);
  }
}

export function getSupabasePublishableKey() {
  // Explicit static accesses are required for client-side Next.js env replacement.
  const value =
    process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY?.trim() ||
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY?.trim();
  if (!value) {
    throw new Error(
      "[config] Missing NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY (or legacy NEXT_PUBLIC_SUPABASE_ANON_KEY)",
    );
  }
  return value;
}

export function getSiteUrl() {
  let value =
    process.env.NEXT_PUBLIC_SITE_URL?.trim() ||
    process.env.NEXT_PUBLIC_VERCEL_URL?.trim() ||
    "http://localhost:3000";
  if (!/^https?:\/\//i.test(value)) value = `https://${value}`;
  return value.replace(/\/$/, "");
}

export function publicConfigStatus() {
  return {
    supabaseUrl: Boolean(process.env.NEXT_PUBLIC_SUPABASE_URL?.trim()),
    supabaseKey: Boolean(
      process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY?.trim() ||
        process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY?.trim(),
    ),
    siteUrl: Boolean(
      process.env.NEXT_PUBLIC_SITE_URL?.trim() || process.env.NEXT_PUBLIC_VERCEL_URL?.trim(),
    ),
  };
}
