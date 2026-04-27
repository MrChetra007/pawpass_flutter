import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { createTransport } from "https://deno.land/x/nodemailer@v1.25.0/mod.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface RequestBody {
  email: string;
  action: "create" | "reset";
  token?: string;
  newPassword?: string;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    const { email, action, token, newPassword }: RequestBody = await req.json();

    if (action === "create") {
      const resetToken = crypto.randomUUID();
      
      await supabase.from("password_resets").upsert({
        email,
        token: resetToken,
        expires_at: new Date(Date.now() + 60 * 60 * 1000).toISOString(),
        used: false,
      }, { onConflict: 'email' });

      const resetLink = `pawpass://reset-password?token=${resetToken}`;
      
      return new Response(
        JSON.stringify({ token: resetToken, resetLink, message: "Token generated" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (action === "reset") {
      const { data: resetRecord } = await supabase
        .from("password_resets")
        .select("*")
        .eq("token", token!)
        .eq("used", false)
        .single();

      if (!resetRecord) {
        return new Response(
          JSON.stringify({ error: "Invalid or used token" }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      if (new Date(resetRecord.expires_at) < new Date()) {
        return new Response(
          JSON.stringify({ error: "Token expired" }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      const { error: updateError } = await supabase.auth.admin.updateUserByEmail(
        resetRecord.email,
        { password: newPassword! }
      );

      if (updateError) {
        return new Response(
          JSON.stringify({ error: updateError.message }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      await supabase
        .from("password_resets")
        .update({ used: true })
        .eq("token", token);

      return new Response(
        JSON.stringify({ success: true, message: "Password updated" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({ error: "Invalid action" }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});