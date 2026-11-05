// MI-RETRIEVE-CODE public share access endpoint.
// Deploy as Supabase Edge Function: share-access
// Required Supabase secrets: SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY.
// Never expose the service-role key in the browser.

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

async function hashIp(ip: string, secret: string) {
  const bytes = new TextEncoder().encode(ip + ":" + secret);
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return Array.from(new Uint8Array(digest), (b) => b.toString(16).padStart(2, "0")).join("");
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return response({ error: "Request not available." }, 405);

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceKey) return response({ error: "Service temporarily unavailable." }, 503);

  let body: { code?: string; password?: string };
  try {
    body = await req.json();
  } catch {
    return response({ error: "Request not available." }, 400);
  }

  const code = typeof body.code === "string" ? body.code.trim().toUpperCase() : "";
  const password = typeof body.password === "string" ? body.password : null;
  if (!code || code.length > 40 || (password !== null && password.length > 256)) {
    return response({ error: "Request not available." }, 400);
  }

  const forwarded = req.headers.get("x-forwarded-for")?.split(",")[0]?.trim();
  const connecting = req.headers.get("cf-connecting-ip")?.trim();
  const ip = connecting || forwarded || "unknown";
  const ipHash = await hashIp(ip, serviceKey);

  const admin = createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { data, error } = await admin.rpc("mi_get_shared_content_secure", {
    p_code: code,
    p_password: password,
    p_ip_hash: ipHash,
  });

  // Keep the response generic: do not reveal whether a code exists or its password status.
  const item = Array.isArray(data) ? data[0] : data;
  if (error || !item) return response({ error: "Share code or password is incorrect, or access is unavailable." }, 404);

  const attachments = [
    ...(Array.isArray(item.images) ? item.images.map((f: Record<string, unknown>) => ({ ...f, bucket: "mi-project-images" })) : []),
    ...(Array.isArray(item.files) ? item.files.map((f: Record<string, unknown>) => ({ ...f, bucket: "mi-project-files" })) : []),
  ];

  const safeAttachments = [];
  for (const file of attachments) {
    const bucket = String(file.bucket);
    const path = String(file.path || "");
    const { data: signed, error: signedError } = await admin.storage.from(bucket).createSignedUrl(path, 3600);
    if (!signedError && signed?.signedUrl) {
      safeAttachments.push({
        file_name: String(file.file_name || "attachment"),
        mime_type: String(file.mime_type || "application/octet-stream"),
        url: signed.signedUrl,
      });
    }
  }

  return response({
    title: item.title,
    content: item.content,
    created_at: item.created_at,
    attachments: safeAttachments,
    note: "Read-only shared access. Attachment links expire after one hour.",
  });
});
