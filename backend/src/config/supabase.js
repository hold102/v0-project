const { createClient } = require("@supabase/supabase-js");
const { supabaseUrl, supabaseSecretKey } = require("./env");

if (!supabaseUrl || !supabaseSecretKey) {
    throw new Error("Missing SUPABASE_URL or SUPABASE_SECRET_KEY in .env");
}
// create supabase client with env variables
const supabase = createClient(
    supabaseUrl,
    supabaseSecretKey
);

module.exports = supabase;