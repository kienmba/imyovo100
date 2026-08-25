import {NextResponse} from "next/server";
import {createClient} from "@/lib/supabase/server";
import {importCurriculumSchema} from "@/lib/validators";
import {COURSE_SLUG} from "@/lib/constants";
import {z} from "zod";

const schema=importCurriculumSchema.extend({
  learnerType:z.enum(["preschool","primary","middle_school","high_school","university","postgraduate","working","senior"])
});

export async function POST(request:Request){
  const parsed=schema.safeParse(await request.json().catch(()=>null));
  if(!parsed.success){
    return NextResponse.json({error:parsed.error.issues.map(x=>x.message).join(", ")},{status:400});
  }

  const supabase=await createClient();
  const {data:{user}}=await supabase.auth.getUser();
  if(!user) return NextResponse.json({error:"Unauthorized"},{status:401});

  const {data,error}=await supabase.rpc("admin_import_lesson",{
    p_course_slug:COURSE_SLUG,
    p_day_number:parsed.data.dayNumber,
    p_title:parsed.data.title,
    p_theme:parsed.data.theme,
    p_learner_type:parsed.data.learnerType,
    p_words:parsed.data.words
  });

  if(error){
    const status=error.message.includes("FORBIDDEN")?403:400;
    return NextResponse.json({error:error.message},{status});
  }
  return NextResponse.json(data);
}
