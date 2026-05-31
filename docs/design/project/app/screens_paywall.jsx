// screens_paywall.jsx — 訂閱 / 付費牆
(function(){
  const { useState } = React;
  const Icon = window.Icon;
  const { StatusBar } = window;
  const { PLANS } = window.LS_DATA;

  function PaywallScreen({ back }){
    const [sel,setSel] = useState("year");
    return (
      <div className="screen is-dark fade-enter">
        <StatusBar light time="8:12"/>
        <button className="iconbtn" onClick={back} aria-label="關閉"
                style={{position:"absolute",top:"calc(var(--safe-top) + 4px)",right:14,zIndex:40,color:"var(--on-dark)"}}>
          <Icon name="x" size={24}/></button>
        <div className="screen__scroll paywall" style={{paddingTop:"calc(var(--safe-top) + 30px)"}}>
          <div className="paywall__top">
            <div className="gem-hero"><Icon name="gem" size={92} stroke={1.2}/></div>
            <div className="paywall__eyebrow">高級 · 會員方案</div>
            <div className="paywall__h">解鎖無盡旅程</div>
            <div className="paywall__sub">每個轉角,都有一位 AI 旅伴</div>
          </div>
          <div className="plans">
            {PLANS.map(p=>(
              <div key={p.id} className={"plan"+(sel===p.id?" is-sel":"")} onClick={()=>setSel(p.id)}>
                <div className="plan__row">
                  <div className="plan__name">
                    {sel===p.id && <span className="plan__radio"><Icon name="check" size={13} stroke={2.6}/></span>}
                    {p.name}
                  </div>
                  {p.badge && <span className="plan__badge">{p.badge}</span>}
                </div>
                <div className="plan__price">{p.price}<span> {p.per}</span></div>
                {sel===p.id && p.feats && (
                  <div className="plan__feats">
                    {p.feats.map((f,i)=>(
                      <div className="plan__feat" key={i}><Icon name="sparkle" size={16}/>{f}</div>
                    ))}
                    <div className="plan__fine">{p.fine}</div>
                  </div>
                )}
              </div>
            ))}
          </div>
          <div className="paywall__cta">
            <button className="btn btn--primary"><Icon name="lock" size={18}/>訂閱{PLANS.find(p=>p.id===sel).name}</button>
            <div className="paywall__legal" style={{marginTop:16,fontSize:14}}>恢復購買</div>
            <div className="paywall__legal"><a>服務條款</a> · <a>隱私權政策</a></div>
          </div>
        </div>
      </div>
    );
  }
  window.PaywallScreen = PaywallScreen;
})();
