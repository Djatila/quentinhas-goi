import { createClient } from '@supabase/supabase-js'

export function createAdminClient() {
    // TEMPORÁRIO: Hardcoded até resolver problema do .env
    const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://mtvehkyansdqiwpddwwa.supabase.co'
    const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im10dmVoa3lhbnNkcWl3cGRkd3dhIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1ODQ2MDQ1NywiZXhwIjoyMDc0MDM2NDU3fQ.AvfHDKVdVVk4nUlkhAn0cQkC0e4PRwUGYXmcUhzi8aM'

    console.log('🔧 Debug Admin Client')
    console.log('URL:', supabaseUrl)
    console.log('Service Key Exists:', !!supabaseServiceKey)

    if (!supabaseUrl) {
        throw new Error('Missing NEXT_PUBLIC_SUPABASE_URL')
    }
    if (!supabaseServiceKey) {
        throw new Error('Missing SUPABASE_SERVICE_ROLE_KEY')
    }

    return createClient(supabaseUrl, supabaseServiceKey, {
        auth: {
            autoRefreshToken: false,
            persistSession: false
        }
    })
}
