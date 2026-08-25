"use client";
import {useState} from "react";

type ReviewItem={wordId:string;term:string;ipa:string|null;meaning:string;example:string|null};

export default function ReviewFlow({items}:{items:ReviewItem[]}){
  const[index,setIndex]=useState(0),[revealed,setRevealed]=useState(false),[done,setDone]=useState(false),[busy,setBusy]=useState(false);
  if(done||items.length===0) return <div className="card center" style={{padding:36}}><h2>Ôn tập hoàn tất 🎯</h2><p className="muted">Không còn từ đến hạn trong phiên này.</p></div>;
  const item=items[index];
  async function grade(quality:number){
    setBusy(true);
    const res=await fetch("/api/review/submit",{method:"POST",headers:{"content-type":"application/json"},body:JSON.stringify({wordId:item.wordId,quality})});
    setBusy(false);
    if(!res.ok){const d=await res.json().catch(()=>({}));alert(d.error||"Không thể lưu kết quả");return}
    if(index===items.length-1)setDone(true);else{setIndex(index+1);setRevealed(false)}
  }
  return <div style={{maxWidth:760}}>
    <div className="progress"><span style={{width:`${((index+1)/items.length)*100}%`}}/></div>
    <div className="card word-card" style={{marginTop:24}}>
      <div className="word">{item.term}</div><div className="ipa">{item.ipa}</div>
      {!revealed?<button className="btn btn-primary" style={{marginTop:32}} onClick={()=>setRevealed(true)}>Hiện nghĩa</button>:<>
        <div className="meaning">{item.meaning}</div>{item.example&&<div className="example">{item.example}</div>}
        <div style={{display:"flex",gap:10,marginTop:28,flexWrap:"wrap",justifyContent:"center"}}>
          <button className="btn btn-soft" disabled={busy} onClick={()=>grade(1)}>Quên</button>
          <button className="btn btn-soft" disabled={busy} onClick={()=>grade(3)}>Khó</button>
          <button className="btn btn-primary" disabled={busy} onClick={()=>grade(5)}>Nhớ</button>
        </div>
      </>}
    </div>
  </div>;
}
