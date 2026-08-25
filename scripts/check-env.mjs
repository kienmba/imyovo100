const required=["NEXT_PUBLIC_SUPABASE_URL"];
const missing=required.filter(k=>!process.env[k]?.trim());
const key=process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY?.trim()||process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY?.trim();
if(!key) missing.push("NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY (or NEXT_PUBLIC_SUPABASE_ANON_KEY)");
if(missing.length){console.error(`Missing environment variables:\n- ${missing.join("\n- ")}`);process.exit(1)}
let url;
try{url=new URL(process.env.NEXT_PUBLIC_SUPABASE_URL)}catch{console.error("NEXT_PUBLIC_SUPABASE_URL is not a valid URL");process.exit(1)}
console.log(`Config OK: ${url.origin}`);
