// Edge Function: generate_asset
// Registra la solicitud de generación de un asset derivado (miniatura, teaser v0)
// para un proyecto publicado y actualiza el estado en generated_asset.
//
// Fase MVP: la generación real se delega a un worker externo o proceso asíncrono;
// esta función actúa como punto de entrada y registro de estado.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const ALLOWED_ASSET_TYPES = new Set(["thumbnail", "teaser_video", "cover"]);

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response(JSON.stringify({ error: "Missing authorization header" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

  const token = authHeader.replace("Bearer ", "");
  const { data: userData, error: authError } = await supabase.auth.getUser(token);
  if (authError || !userData.user) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  const userId = userData.user.id;

  let body: { project_id: string; asset_type: string };
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON body" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  const { project_id, asset_type } = body;

  if (!project_id) {
    return new Response(JSON.stringify({ error: "project_id is required" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  if (!asset_type || !ALLOWED_ASSET_TYPES.has(asset_type)) {
    return new Response(
      JSON.stringify({ error: "asset_type must be one of: thumbnail, teaser_video, cover" }),
      { status: 400, headers: { "Content-Type": "application/json" } }
    );
  }

  // Verify ownership
  const { data: project, error: projectError } = await supabase
    .from("project")
    .select("id, owner_id, status, title")
    .eq("id", project_id)
    .single();

  if (projectError || !project) {
    return new Response(JSON.stringify({ error: "Project not found" }), {
      status: 404,
      headers: { "Content-Type": "application/json" },
    });
  }

  if (project.owner_id !== userId) {
    return new Response(JSON.stringify({ error: "Forbidden" }), {
      status: 403,
      headers: { "Content-Type": "application/json" },
    });
  }

  // Upsert a pending generation record (one per project + asset_type)
  const { data: asset, error: upsertError } = await supabase
    .from("generated_asset")
    .upsert(
      {
        project_id,
        asset_type,
        generation_status: "pending",
        storage_path: null,
      },
      { onConflict: "project_id,asset_type", ignoreDuplicates: false }
    )
    .select("id")
    .single();

  if (upsertError) {
    return new Response(
      JSON.stringify({ error: "Failed to register asset generation", details: upsertError.message }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }

  return new Response(
    JSON.stringify({ success: true, asset_id: asset.id, status: "pending" }),
    { status: 200, headers: { "Content-Type": "application/json" } }
  );
});
