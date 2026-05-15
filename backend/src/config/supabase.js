const { createClient } = require("@supabase/supabase-js");
const ws = require("ws");
const { supabaseUrl, supabaseSecretKey } = require("./env");

if (!supabaseUrl || !supabaseSecretKey) {
    throw new Error("Missing SUPABASE_URL or SUPABASE_SECRET_KEY in .env");
}
const supabase = createClient(supabaseUrl, supabaseSecretKey, {
    realtime: { transport: ws },
});

module.exports = supabase;