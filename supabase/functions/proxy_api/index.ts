// Using built-in Deno.serve() - no imports needed!

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req: Request) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { action, payload } = await req.json()

    // Example: Handle 'openai_completion' action
    if (action === 'openai_completion') {
      const OPENAI_KEY = Deno.env.get('OPENAI_KEY')
      if (!OPENAI_KEY) {
        throw new Error('OPENAI_KEY not set')
      }

      const response = await fetch('https://api.openai.com/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${OPENAI_KEY}`,
        },
        body: JSON.stringify(payload),
      })

      const data = await response.json()
      return new Response(JSON.stringify(data), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: response.status,
      })
    }

    // Example: Handle 'send_sms_provider' action (if using external provider like Twilio)
    if (action === 'send_sms_provider') {
      const SMS_PROVIDER_KEY = Deno.env.get('SMS_PROVIDER_KEY')
      // Implementation would go here
      return new Response(JSON.stringify({ message: "Not implemented yet" }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    throw new Error(`Unknown action: ${action}`)

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
