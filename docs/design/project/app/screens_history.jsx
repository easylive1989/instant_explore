// screens_history.jsx — 歷程 tab (timeline / by-trip), trip detail, create trip, date picker
(function(){
  const { useState } = React;
  const Icon = window.Icon;
  const { StatusBar, TopBar } = window;
  const { TIMELINE, TRIPS } = window.LS_DATA;

  function TLItem({ it, showAddr, onShare }){
    return (
      <div className="tl-item">
        <div className="tl-dot"/>
        {it.img && <div className="tl-thumb"><img src={it.img} alt=""/></div>}
        <div className="tl-date"><b>{it.date}</b> &nbsp;{it.time}</div>
        <div className="tl-title" style={{maxWidth: it.img?"calc(100% - 72px)":"100%"}}>{it.title}</div>
        {showAddr && it.addr && <div className="tl-addr">{it.addr}</div>}
        <div className="tl-card">
          <p>{it.text}</p>
          <div className="tl-actions">
            <button><Icon name="share" size={17}/>分享</button>
            <button><Icon name="trash" size={17}/>刪除</button>
          </div>
        </div>
      </div>
    );
  }

  function HistoryScreen({ go }){
    const [tab, setTab] = useState("all");
    return (
      <div className="screen has-tabbar fade-enter">
        <StatusBar dark time="8:00"/>
        <div className="screen__scroll">
          <div className="lg-header" style={{paddingTop:8}}>
            <h1>歷程</h1>
            <div className="actions">
              <button className="iconbtn" style={{background:"var(--paper-sunk)"}} onClick={()=>go("createTrip",{})}>
                <Icon name="plus" size={22}/></button>
            </div>
          </div>
          <div className="seg">
            <button className={tab==="all"?"is-on":""} onClick={()=>setTab("all")}>全部時間軸</button>
            <button className={tab==="trip"?"is-on":""} onClick={()=>setTab("trip")}>依旅程</button>
          </div>

          {tab==="all" && (
            <div className="timeline" style={{paddingTop:14}}>
              {TIMELINE.map((it,i)=><TLItem key={i} it={it}/>)}
            </div>
          )}

          {tab==="trip" && (
            <div className="trip-grid">
              {TRIPS.map(t=>(
                <div key={t.id} className={"trip-tile trip-tile--"+t.style}
                     onClick={()=> t.items && go("trip",{id:t.id}) }>
                  <div className="trip-tile__ic"><Icon name={t.style==="clay"?"book":"image-off"} size={26}/></div>
                  <div>
                    <div className="trip-tile__name">{t.name}</div>
                    {t.range && <div className="trip-tile__sub">{t.range}</div>}
                    <div className="trip-tile__sub">{t.count}</div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    );
  }

  function TripDetailScreen({ params, back }){
    const trip = TRIPS.find(t=>t.id===params.id);
    return (
      <div className="screen fade-enter">
        <StatusBar dark time="8:01"/>
        <TopBar title={trip.name} onBack={back}
                right={<button className="iconbtn"><Icon name="sliders" size={20}/></button>}/>
        <div className="screen__scroll" style={{paddingTop:"calc(var(--safe-top) + 54px)"}}>
          <div className="tl-trip-meta" style={{padding:"0 22px 6px"}}>
            <Icon name="calendar" size={17}/>{trip.dateLabel}
          </div>
          <div className="timeline">
            {trip.items.map((it,i)=><TLItem key={i} it={it} showAddr/>)}
          </div>
        </div>
      </div>
    );
  }

  function CreateTripScreen({ back, openSheet, draft }){
    const [name,setName] = useState(draft.name||"");
    return (
      <div className="screen fade-enter">
        <StatusBar dark time="8:01"/>
        <TopBar title="建立旅程" onBack={back}/>
        <div className="screen__scroll" style={{paddingTop:"calc(var(--safe-top) + 54px)"}}>
          <div className="form">
            <div className="field">
              <div className="field__lab">旅程名稱</div>
              <input value={name} onChange={e=>setName(e.target.value)} placeholder="例如:2026 京都賞楓"/>
            </div>
            <div className="field field--row" onClick={()=>openSheet("date",{which:"start"})} style={{cursor:"pointer"}}>
              <div><div className="field__lab">開始日期</div>
                <div className={"field__val"+(draft.start?"":" is-empty")}>{draft.start||"未設定"}</div></div>
              <Icon name="calendar" size={22} style={{color:"var(--ink-3)"}}/>
            </div>
            <div className="field field--row" onClick={()=>openSheet("date",{which:"end"})} style={{cursor:"pointer"}}>
              <div><div className="field__lab">結束日期</div>
                <div className={"field__val"+(draft.end?"":" is-empty")}>{draft.end||"未設定"}</div></div>
              <Icon name="calendar" size={22} style={{color:"var(--ink-3)"}}/>
            </div>
            <button className="btn btn--primary" style={{marginTop:8}} onClick={back}>建立旅程</button>
          </div>
        </div>
      </div>
    );
  }

  function DatePickerSheet({ close, onPick }){
    const dow = ["日","一","二","三","四","五","六"];
    const [sel,setSel] = useState(30);
    const days = []; for(let d=1; d<=31; d++) days.push(d);
    const lead = 5; // May 2026 starts Friday
    return (
      <div className="overlay" onClick={close}>
        <div className="sheet" onClick={e=>e.stopPropagation()}>
          <div className="sheet__grab"/>
          <div className="muted-3" style={{fontSize:14,fontWeight:600}}>選取日期</div>
          <div className="cal__big serif">5月{sel}日 週{dow[(lead+sel-1)%7]}</div>
          <div className="cal__nav">
            <div className="mo">2026年5月</div>
            <div style={{display:"flex",gap:18,color:"var(--ink-2)"}}>
              <Icon name="chevron-left" size={22}/><Icon name="chevron-right" size={22}/></div>
          </div>
          <div className="cal__grid">
            {dow.map(d=><div key={d} className="cal__dow">{d}</div>)}
            {Array.from({length:lead}).map((_,i)=><div key={"x"+i}/>)}
            {days.map(d=>(
              <div key={d} className={"cal__day"+(d===sel?" is-sel":"")} onClick={()=>setSel(d)}>{d}</div>
            ))}
          </div>
          <div className="cal__actions">
            <button onClick={close}>取消</button>
            <button onClick={()=>{ onPick("2026年5月"+sel+"日"); close(); }}>確定</button>
          </div>
        </div>
      </div>
    );
  }

  Object.assign(window, { HistoryScreen, TripDetailScreen, CreateTripScreen, DatePickerSheet });
})();
