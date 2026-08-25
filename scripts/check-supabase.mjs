const url=(process.env.NEXT_PUBLIC_SUPABASE_URL||"").replace(/\/$/,"");
const key=process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY||process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY||"";
if(!url||!key){console.error("Set NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY first.");process.exit(1)}
try{
  const res=await fetch(`${url}/auth/v1/health`,{headers:{apikey:key},signal:AbortSignal.timeout(8000)});
  const body=await res.text();
  if(!res.ok){console.error(`Supabase health failed (${res.status}): ${body}`);process.exit(1)}
  console.log(`Supabase Auth reachable (${res.status}): ${body}`);
}catch(e){console.error(`Supabase connection failed: ${e instanceof Error?e.message:String(e)}`);process.exit(1)}
