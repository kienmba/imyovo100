import {NextResponse} from "next/server";
import {getSupabasePublishableKey,getSupabaseUrl,publicConfigStatus} from "@/lib/env";

export const dynamic="force-dynamic";

export async function GET(){
  const config=publicConfigStatus();
  if(!config.supabaseUrl||!config.supabaseKey){
    return NextResponse.json({ok:false,service:"imyovo100",config,supabase:{ok:false,error:"Missing Supabase environment variables"}},{status:503});
  }

  try{
    const response=await fetch(`${getSupabaseUrl()}/auth/v1/health`,{
      headers:{apikey:getSupabasePublishableKey()},
      cache:"no-store",
      signal:AbortSignal.timeout(5000)
    });
    const body=await response.json().catch(()=>null);
    const ok=response.ok;
    return NextResponse.json({ok,service:"imyovo100",config,supabase:{ok,status:response.status,name:body?.name??"GoTrue",version:body?.version??null},time:new Date().toISOString()},{status:ok?200:503});
  }catch(error){
    return NextResponse.json({ok:false,service:"imyovo100",config,supabase:{ok:false,error:error instanceof Error?error.message:"Supabase health check failed"},time:new Date().toISOString()},{status:503});
  }
}
