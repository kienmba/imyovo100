import fs from "node:fs";

const file=process.argv[2];
if(!file){console.error("Usage: node scripts/validate-curriculum.mjs <curriculum.json>");process.exit(2)}
const data=JSON.parse(fs.readFileSync(file,"utf8"));
const segments=["preschool","primary","middle_school","high_school","university","postgraduate","working","senior"];
const errors=[];
for(const segment of segments){
  const days=data[segment];
  if(!Array.isArray(days)||days.length!==100){errors.push(`${segment}: expected 100 days`);continue}
  for(let i=0;i<100;i++){
    const d=days[i];
    if(d?.dayNumber!==i+1)errors.push(`${segment}: day index ${i} must have dayNumber ${i+1}`);
    if(!Array.isArray(d?.words)||d.words.length!==10)errors.push(`${segment} day ${i+1}: expected 10 words`);
    const terms=new Set((d?.words||[]).map(w=>String(w.term||"").trim().toLowerCase()));
    if(terms.size!==10)errors.push(`${segment} day ${i+1}: duplicate/empty terms`);
  }
}
if(errors.length){console.error(errors.slice(0,100).join("\n"));console.error(`FAILED: ${errors.length} errors`);process.exit(1)}
console.log("OK: 8 segments × 100 days × 10 words validated.");
