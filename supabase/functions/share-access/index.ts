// MI-RETRIEVE-CODE account-based shared project access.
// A recipient must sign in. Accepted projects are saved to that recipient's account.
// The original project remains owned by its creator. Never expose service keys.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function response(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function getServerSecretKey(): string | null {
  const namedKeys = Deno.env.get("SUPABASE_SECRET_KEYS");
  if (namedKeys) {
    try {
      const parsed = JSON.parse(namedKeys);
      if (typeof parsed.default === "string" && parsed.default.length > 0) return parsed.default;
    } catch {
      // Use the legacy fallback only during migration.
    }
  }
  return Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || null;
}

async function hashIp(ip: string, secret: string) {
  const bytes = new TextEncoder().encode(ip + ":" + secret);
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return Array.from(new Uint8Array(digest), (b) => b.toString(16).padStart(2, "0")).join("");
}

function getAttachments(item: Record<string, any>) {
  return [
    ...(Array.isArray(item.images) ? item.images.map((f: Record<string, unknown>) => ({ ...f, bucket: "mi-project-images" })) : []),
    ...(Array.isArray(item.files) ? item.files.map((f: Record<string, unknown>) => ({ ...f, bucket: "mi-project-files" })) : []),
  ];
}

async function presentProject(admin: ReturnType<typeof createClient>, item: Record<string, any>) {
  const attachments = getAttachments(item);
  const safeAttachments = [];
  for (const file of attachments) {
    const bucket = String(file.bucket);
    const path = String(file.path || "");
    if (!path) continue;
    const { data: signed, error } = await admin.storage.from(bucket).createSignedUrl(path, 3600);
    if (!error && signed?.signedUrl) {
      safeAttachments.push({
        file_name: String(file.file_name || "attachment"),
        mime_type: String(file.mime_type || "application/octet-stream"),
        url: signed.signedUrl,
      });
    }
  }
  return {
    title: String(item.title || "Shared project"),
    content: String(item.content || ""),
    project_structure: String(item.project_structure || ""),
    created_at: item.created_at || null,
    attachments: safeAttachments,
    note: "Read-only shared project saved in your account. Attachment links expire after one hour.",
  };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return response({ error: "Request not available." }, 405);

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceKey = getServerSecretKey();
  if (!supabaseUrl || !serviceKey) return response({ error: "Service temporarily unavailable." }, 503);

  const authorization = req.headers.get("Authorization") || "";
  const token = authorization.startsWith("Bearer ") ? authorization.slice(7) : "";
  if (!token) return response({ error: "Please sign in to your MI account first." }, 401);

  // Verify the signed-in recipient using their session token.
  const authClient = createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data: authData, error: authError } = await authClient.auth.getUser(token);
  const user = authData?.user;
  if (authError || !user) return response({ error: "Your session is not valid. Please sign in again." }, 401);

  let body: { action?: string; code?: string; password?: string };
  try {
    const rawBody = await req.text();
    if (!rawBody.trim()) {
      return response({ error: "The request body was empty. Please refresh the page and try again." }, 400);
    }
    body = JSON.parse(rawBody);
    if (!body || typeof body !== "object" || Array.isArray(body)) {
      return response({ error: "The request body format was invalid. Please refresh the page and try again." }, 400);
    }
  } catch (error) {
    console.error("share-access: invalid JSON request body", error instanceof Error ? error.name : "parse error");
    return response({ error: "The request body could not be read as JSON. Please refresh the page and try again." }, 400);
  }

  const action = body.action === "list" ? "list" : "accept";

  // Secret-key requests must not carry a Bearer JWT by default.
  const fetchWithoutBearer: typeof fetch = (input, init) => {
    const headers = new Headers(init?.headers);
    headers.delete("Authorization");
    return fetch(input, { ...init, headers });
  };
  const admin = createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
    global: { fetch: fetchWithoutBearer },
  });

  if (action === "list") {
    const { data: rows, error } = await admin
      .from("mi_received_projects")
      .select("id,share_code,project_title,project_data,project_created_at,received_at")
      .eq("recipient_id", user.id)
      .order("received_at", { ascending: false });

    if (error) return response({ error: "Could not load your received projects." }, 500);
    if (!rows?.length) return response({ projects: [] });

    const codes = [...new Set(rows.map((row: any) => row.share_code))];
    const { data: activeShares, error: shareError } = await admin
      .from("mi_shared_access")
      .select("share_code,is_active,expires_at")
      .in("share_code", codes);

    if (shareError) return response({ error: "Could not verify project sharing status." }, 500);
    const now = Date.now();
    const activeCodes = new Set((activeShares || [])
      .filter((share: any) => share.is_active && (!share.expires_at || new Date(share.expires_at).getTime() > now))
      .map((share: any) => share.share_code));

    const projects = [];
    for (const row of rows) {
      if (!activeCodes.has(row.share_code)) continue;
      projects.push({
        id: row.id,
        share_code: row.share_code,
        received_at: row.received_at,
        ...(await presentProject(admin, row.project_data || {})),
      });
    }
    return response({ projects });
  }

  const code = typeof body.code === "string" ? body.code.trim().toUpperCase() : "";
  const password = typeof body.password === "string" ? body.password : null;
  if (!code || code.length > 40 || (password !== null && password.length > 256)) {
    return response({ error: "Enter a valid Share Code and password." }, 400);
  }

  const forwarded = req.headers.get("x-forwarded-for")?.split(",")[0]?.trim();
  const connecting = req.headers.get("cf-connecting-ip")?.trim();
  const ipHash = await hashIp(connecting || forwarded || "unknown", serviceKey);

  const { data, error } = await admin.rpc("mi_get_shared_content_secure", {
    p_code: code,
    p_password: password,
    p_ip_hash: ipHash,
  });
  const item = Array.isArray(data) ? data[0] : data;
  if (error || !item) {
    return response({ error: "Share Code or password is incorrect, or the creator has turned sharing off." }, 404);
  }

  const { error: saveError } = await admin
    .from("mi_received_projects")
    .upsert({
      recipient_id: user.id,
      share_code: code,
      project_title: String(item.title || "Shared project"),
      project_data: item,
      project_created_at: item.created_at || null,
      received_at: new Date().toISOString(),
    }, { onConflict: "recipient_id,share_code" });

  if (saveError) return response({ error: "The project was found, but could not be saved to your account. Please try again." }, 500);

  const project = await presentProject(admin, item);
  return response({
    success: true,
    message: "Project received and saved to your account.",
    project,
  });
});
