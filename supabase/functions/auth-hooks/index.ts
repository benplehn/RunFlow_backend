// supabase/functions/auth-hooks/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Parse webhook payload
    const { record, type, table } = await req.json()
    
    // Vérifier que c'est un nouvel utilisateur
    if (type !== 'INSERT' || table !== 'users') {
      return new Response('Not a user insert', { status: 200 })
    }

    // Créer client Supabase admin
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Générer username temporaire unique
    const tempUsername = `user_${record.id.substring(0, 8)}`

    // Créer le profil automatiquement
    const { data, error } = await supabaseAdmin
      .from('profiles')
      .insert({
        id: record.id,
        username: tempUsername,
        preferences: {
          notifications: true,
          privacy: 'public',
          units: 'metric'
        }
      })

    if (error) {
      console.error('Erreur création profil:', error)
      return new Response(`Erreur: ${error.message}`, { 
        status: 500,
        headers: corsHeaders 
      })
    }

    console.log(`Profil créé pour user: ${record.id}`)
    
    return new Response(
      JSON.stringify({ success: true, profile: data }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Erreur webhook:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
})