import {NextResponse} from "next/server";
import {createClient} from "@/lib/supabase/server";

export async function GET(request:Request){
  const url=new URL(request.url);
  const code=url.searchParams.get("code");
  const flowId=url.searchParams.get("sb_flow_id");
  const next=url.searchParams.get("next");
  const destination=next?.startsWith("/")&&!next.startsWith("//")?next:"/dashboard";

  if(!code){
    const errorUrl=new URL("/",request.url);
    errorUrl.searchParams.set("authError","missing_code");
    return NextResponse.redirect(errorUrl);
  }

  const supabase=await createClient();
  const {error}=await supabase.auth.exchangeCodeForSession(code,flowId?{flowId}:undefined);
  if(error){
    const errorUrl=new URL("/",request.url);
    errorUrl.searchParams.set("authError","callback_failed");
    return NextResponse.redirect(errorUrl);
  }

  return NextResponse.redirect(new URL(destination,request.url));
}
