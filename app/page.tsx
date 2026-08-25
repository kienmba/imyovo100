import AuthForm from "@/components/AuthForm";

export default async function Home({searchParams}:{searchParams:Promise<{authError?:string}>}){
  const {authError}=await searchParams;
  return <main className="container hero">
    <section>
      <span className="pill">100 DAYS ENGLISH CHALLENGE</span>
      <h1>1.000 từ.<br/><span style={{color:"var(--brand)"}}>100 ngày.</span><br/>Một thói quen.</h1>
      <p className="muted">Mỗi ngày đúng 10 từ theo lộ trình. Ngày tương lai được khóa và chỉ mở theo thời gian thực. Nội dung được cá nhân hóa theo nhóm người học.</p>
      <div className="grid grid-3" style={{marginTop:28}}>{[[10,"từ/ngày"],[100,"ngày"],["1K","từ vựng"]].map(([n,l])=><div key={String(l)} className="card kpi center"><b>{n}</b><span className="muted">{l}</span></div>)}</div>
    </section>
    <div>
      {authError&&<div className="error" style={{marginBottom:12}}>Liên kết xác thực không hợp lệ hoặc đã hết hạn. Vui lòng thử lại.</div>}
      <AuthForm/>
    </div>
  </main>;
}
