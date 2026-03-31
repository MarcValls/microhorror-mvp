// Edge Function: ingest_event
// Recibe eventos analíticos del cliente y los persiste en analytics_event.
// Acepta un único evento o un batch de eventos.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const ALLOWED_EVENTS = new Set([
  "onboarding_started",
  "signup_completed",
  "project_created",
  "playtest_started",
  "playtest_completed",
  "project_published",
  "project_link_opened",
  "result_shared",
  "game_session_started",
  "objective_seen",
  "ending_reached",
  "game_session_completed",
]);

interface EventPayload {
  event_name: string;
  project_id?: string;
  session_id?: string;
  properties?: Record<string, unknown>;
  occurred_at?: string;
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

  // User is optional: anonymous sessions are allowed
  let userId: string | null = null;
  const authHeader = req.headers.get("Authorization");
  if (authHeader) {
    const token = authHeader.replace("Bearer ", "");
    const { data: userData } = await supabase.auth.getUser(token);
    userId = userData?.user?.id ?? null;
  }

  let body: EventPayload | EventPayload[];
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON body" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  const events = Array.isArray(body) ? body : [body];

  if (events.length === 0) {
    return new Response(JSON.stringify({ error: "No events provided" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  if (events.length > 50) {
    return new Response(JSON.stringify({ error: "Batch size exceeds limit of 50" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  const rows = [];
  for (const event of events) {
    if (!event.event_name || !ALLOWED_EVENTS.has(event.event_name)) {
      continue; // silently skip unknown events
    }
    rows.push({
      event_name: event.event_name,
      user_id: userId,
      project_id: event.project_id ?? null,
      session_id: event.session_id ?? null,
      properties: {
        ...( event.properties ?? {} ),
        ...(event.occurred_at ? { occurred_at: event.occurred_at } : {}),
      },
      created_at: new Date().toISOString(),
    });
  }

  if (rows.length === 0) {
    return new Response(JSON.stringify({ ingested: 0 }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  }

  const { error: insertError } = await supabase.from("analytics_events").insert(rows);

  if (insertError) {
    return new Response(
      JSON.stringify({ error: "Failed to ingest events", details: insertError.message }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }

  return new Response(
    JSON.stringify({ ingested: rows.length }),
    { status: 200, headers: { "Content-Type": "application/json" } }
  );
});
