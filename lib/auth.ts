import {redirect} from "next/navigation"; import {createClient} from "@/lib/supabase/server";
export async function requireUser(){const supabase=await createClient();const {data,error}=await supabase.auth.getUser();if(error||!data.user) redirect("/");return{supabase,user:data.user}}
export async function requireProfile(){const ctx=await requireUser();const {data:profile}=await ctx.supabase.from("profiles").select("*").eq("id",ctx.user.id).single();if(!profile?.onboarding_completed) redirect("/onboarding");return{...ctx,profile}}
export async function requireAdmin(){const ctx=await requireProfile();if(ctx.profile.role!=="admin") redirect("/dashboard");return ctx}
