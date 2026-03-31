// Edge Function: publish_project
// Valida un proyecto en estado draft o ready_to_publish y lo publica generando un slug único.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

function generateSlug(title: string): string {
  const base = title
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "")
    .slice(0, 40);
  const suffix = Math.random().toString(36).slice(2, 8);
  return `${base}-${suffix}`;
}

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

  // Verify the JWT and get the user
  const token = authHeader.replace("Bearer ", "");
  const { data: userData, error: authError } = await supabase.auth.getUser(token);
  if (authError || !userData.user) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  const userId = userData.user.id;

  let body: { project_id: string };
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON body" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  const { project_id } = body;
  if (!project_id) {
    return new Response(JSON.stringify({ error: "project_id is required" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  // Fetch the project
  const { data: project, error: fetchError } = await supabase
    .from("project")
    .select("id, owner_id, title, status, template_id, threat_id, ending_payload, story_payload, event_payload")
    .eq("id", project_id)
    .single();

  if (fetchError || !project) {
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

  if (project.status === "published") {
    return new Response(JSON.stringify({ error: "Project is already published" }), {
      status: 409,
      headers: { "Content-Type": "application/json" },
    });
  }

  // Minimal validation
  const validationErrors: string[] = [];
  if (!project.template_id) validationErrors.push("template_id is required");
  if (!project.threat_id) validationErrors.push("threat_id is required");
  if (!project.title || project.title.trim().length === 0) validationErrors.push("title is required");

  if (validationErrors.length > 0) {
    return new Response(JSON.stringify({ error: "Validation failed", details: validationErrors }), {
      status: 422,
      headers: { "Content-Type": "application/json" },
    });
  }

  // Generate a unique slug
  const slug = generateSlug(project.title);

  const { error: updateError } = await supabase
    .from("project")
    .update({
      status: "published",
      publish_slug: slug,
      visibility: "public",
      published_at: new Date().toISOString(),
    })
    .eq("id", project_id);

  if (updateError) {
    return new Response(JSON.stringify({ error: "Failed to publish project", details: updateError.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }

  // Emit analytics event
  await supabase.from("analytics_event").insert({
    event_name: "project_published",
    user_id: userId,
    project_id: project_id,
    properties: {
      template_id: project.template_id,
      slug,
    },
  });

  return new Response(
    JSON.stringify({ success: true, slug, project_id }),
    { status: 200, headers: { "Content-Type": "application/json" } }
  );
});
