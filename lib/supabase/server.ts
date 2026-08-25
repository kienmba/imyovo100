import {createServerClient} from "@supabase/ssr";
import {cookies} from "next/headers";
import {getSupabasePublishableKey,getSupabaseUrl} from "@/lib/env";

export async function createClient(){
  const cookieStore=await cookies();
  return createServerClient(getSupabaseUrl(),getSupabasePublishableKey(),{
    cookies:{
      getAll(){return cookieStore.getAll();},
      setAll(cookiesToSet){
        try{
          cookiesToSet.forEach(({name,value,options})=>cookieStore.set(name,value,options));
        }catch{
          // Server Components cannot always mutate cookies. proxy.ts refreshes the
          // session before protected routes render, so this is safe to ignore here.
        }
      }
    }
  });
}
