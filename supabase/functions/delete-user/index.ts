import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    if (!supabaseUrl || !supabaseServiceKey) {
      return new Response(JSON.stringify({ error: "Missing environment variables" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 500,
      });
    }

    const body = await req.json();
    const userId = body.userId;

    if (!userId) {
      return new Response(JSON.stringify({ error: "Missing userId" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 400,
      });
    }

    console.log("Deleting user data for:", userId);

    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey);

    const tables = [
      { name: "vet_records", field: "user_id" },
      { name: "vaccines", field: "user_id" },
      { name: "appointments", field: "user_id" },
      { name: "medications", field: "user_id" },
      { name: "weight_logs", field: "user_id" },
      { name: "family_members", field: "owner_id" },
      { name: "pets", field: "user_id" },
      { name: "users", field: "id" },
    ];

    for (const table of tables) {
      try {
        await supabaseAdmin.from(table.name).delete().eq(table.field, userId);
        console.log(`Deleted from ${table.name}`);
      } catch (e) {
        console.error(`${table.name} error:`, e.message);
      }
    }

    const { error: deleteError } = await supabaseAdmin.auth.admin.deleteUser(userId);
    if (deleteError) {
      console.error("Auth delete error:", deleteError.message);
    }

    console.log("User deleted successfully:", userId);
    return new Response(JSON.stringify({ success: true }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });

  } catch (error) {
    console.error("Function error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 400,
    });
  }
});
