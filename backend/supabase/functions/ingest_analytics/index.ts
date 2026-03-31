import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.8";
import { corsHeaders } from "../_shared/cors.ts";

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

const MAX_BATCH_SIZE = 50;

type AnalyticsEventPayload = {
  event_name: string;
  project_id?: string | null;
  session_id?: string | null;
  properties?: Record<string, unknown>;
  occurred_at?: string;
};

function jsonResponse(status: number, payload: Record<string, unknown>): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function isPlainObject(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse(405, { error: "method_not_allowed" });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const authHeader = req.headers.get("Authorization") ?? "";

  if (!supabaseUrl || !supabaseAnonKey) {
    return jsonResponse(400, { error: "missing_environment" });
  }

  let body: AnalyticsEventPayload | AnalyticsEventPayload[];

  try {
    body = await req.json();
  } catch {
    return jsonResponse(400, { error: "invalid_json_body" });
  }

  const events = Array.isArray(body) ? body : [body];

  if (events.length == 0) {
    return jsonResponse(400, { error: "events_required" });
  }

  if (events.length > MAX_BATCH_SIZE) {
    return jsonResponse(400, {
      error: "batch_size_exceeded",
      max_batch_size: MAX_BATCH_SIZE,
    });
  }

  const normalizedEvents = events.map((event, index) => {
    if (!isPlainObject(event)) {
      throw new Error(`invalid_event_payload:${index}`);
    }

    const eventName = event.event_name;
    if (typeof eventName !== "string" || eventName.length === 0) {
      throw new Error(`event_name_required:${index}`);
    }

    if (!ALLOWED_EVENTS.has(eventName)) {
      throw new Error(`event_name_not_allowed:${index}:${eventName}`);
    }

    const projectId = event.project_id ?? null;
    const sessionId = event.session_id ?? null;
    const properties = event.properties ?? {};

    if (!isPlainObject(properties)) {
      throw new Error(`properties_must_be_object:${index}`);
    }

    return {
      eventName,
      projectId,
      sessionId,
      properties: event.occurred_at
        ? { ...properties, occurred_at: event.occurred_at }
        : properties,
    };
  });

  const isBatchRequest = Array.isArray(body);

  const supabase = createClient(supabaseUrl, supabaseAnonKey, {
    global: {
      headers: authHeader ? { Authorization: authHeader } : {},
    },
  });

  const analyticsEventIds: number[] = [];

  try {
    for (const event of normalizedEvents) {
      const { data, error } = await supabase.rpc("log_analytics_event", {
        p_event_name: event.eventName,
        p_project_id: event.projectId,
        p_session_id: event.sessionId,
        p_properties: event.properties,
      });

      if (error) {
        return jsonResponse(400, { error: error.message });
      }

      analyticsEventIds.push(data);
    }
  } catch (error) {
    const message = error instanceof Error ? error.message : "invalid_event_payload";
    const [errorCode, index, detail] = message.split(":");
    return jsonResponse(400, {
      error: errorCode,
      event_index: index != undefined ? Number(index) : null,
      detail: detail ?? null,
      allowed_events: Array.from(ALLOWED_EVENTS).sort(),
    });
  }

  if (isBatchRequest) {
    return jsonResponse(200, {
      ingested: analyticsEventIds.length,
      analytics_event_ids: analyticsEventIds,
    });
  }

  return jsonResponse(200, {
    analytics_event_id: analyticsEventIds[0],
  });
});
