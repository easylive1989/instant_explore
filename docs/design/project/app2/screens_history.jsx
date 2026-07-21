// screens_history.jsx — 歷程 tab (notebook pager / by-trip), trip detail, create trip, date picker
(function(){
  const { useState, useRef } = React;
  const Icon = window.Icon;
  const { StatusBar, TopBar, Masthead } = window;
  const { TIMELINE, TRIPS } = window.LS_DATA;

  const NB_THRESH = 60;

  function NotebookPage({ it, index, total }){
    return (
      <div className="nb-page">
        <div className="nb-paper">
          <div className="nb-no">手記 · No.{String(index+1).padStart(2,"0")}</div>
          <div className="nb-stamp">{it.date} · {it.time}</div>
          <div className="polaroid">
            <div className={"nb-tape "+(index%2?"nb-tape--tr":"nb-tape--tl")}/>
            {it.img
              ? <div className="polaroid__ph"><img src={it.img} alt="" draggable="false"/></div>
              : <div className="polaroid__ph polaroid__ph--empty"><Icon name="image-off" size={30}/><span>無照片</span></div>}
            <div className="polaroid__cap">{it.title}</div>
          </div>
          <div className="nb-note">
            <div className="nb-note__title">{it.title}</div>
            {it.addr && <div className="nb-note__addr"><Icon name="location" size={13}/><span>{it.addr}</span></div>}
            <p className="nb-note__text">{it.text}</p>
          </div>
          <div className="nb-foot">
            <div className="nb-foot__pos">{String(index+1).padStart(2,"0")} / {String(total).padStart(2,"0")}</div>
            <div className="nb-foot__acts">
              <button><Icon name="share" size={16}/>分享</button>
              <button><Icon name="trash" size={16}/>刪除</button>
            </div>
          </div>
        </div>
      </div>
    );
  }

  function NotebookPager({ items }){
    const [i, setI] = useState(0);
    const [dx, setDx] = useState(0);
    const [drag, setDrag] = useState(false);
    const start = useRef(null);
    const stageW = useRef(1);
    const N = items.length;

    function clampI(n){ return Math.max(0, Math.min(N-1, n)); }

    function onDown(e){
      start.current = { x:e.clientX, y:e.clientY, lock:null };
      stageW.current = e.currentTarget.getBoundingClientRect().width || 1;
      e.currentTarget.setPointerCapture(e.pointerId);
      setDrag(true);
    }
    function onMove(e){
      if(!start.current) return;
      const mx = e.clientX - start.current.x;
      const my = e.clientY - start.current.y;
      if(start.current.lock===null && (Math.abs(mx)>6 || Math.abs(my)>6))
        start.current.lock = Math.abs(mx) >= Math.abs(my) ? "x" : "y";
      if(start.current.lock==="x"){
        let d = mx;
        if((i===0 && d>0) || (i===N-1 && d<0)) d *= 0.32; // rubber-band ends
        setDx(d);
      }
    }
    function onUp(){
      if(!start.current) return;
      const d = dx, w = stageW.current;
      start.current = null;
      setDrag(false);
      if(d < -NB_THRESH) setI(v=>clampI(v+1));
      else if(d > NB_THRESH) setI(v=>clampI(v-1));
      setDx(0);
    }

    const pct = -i * 100;
    const trackStyle = {
      transform: `translateX(calc(${pct}% + ${dx}px))`,
      transition: drag ? "none" : "transform .4s cubic-bezier(.22,.61,.36,1)",
    };

    return (
      <React.Fragment>
        <div className="nb-stage" onPointerDown={onDown} onPointerMove={onMove} onPointerUp={onUp} onPointerCancel={onUp}>
          <div className="nb-track" style={trackStyle}>
            {items.map((it,idx)=>(
              <NotebookPage key={idx} it={it} index={idx} total={N}/>
            ))}
          </div>
        </div>
        <div className="nb-dots">
          {items.map((_,idx)=>(
            <i key={idx} className={idx===i?"is-on":""} onClick={()=>setI(idx)}/>
          ))}
        </div>
      </React.Fragment>
    );
  }

  function TLItem({ it, showAddr }){
    const parts = (it.date||"").trim().split(/\s+/);
    const mo = parts[0] || "";
    const day = parts[1] || it.date;
    return (
      <div className="log-entry">
        <div className="log-date">
          <div className="log-date__day">{day}</div>
          <div className="log-date__mo">{mo}</div>
          <div className="log-date__time">{it.time}</div>
          <div className="log-date__spine"/>
        </div>
        <div className="log-body">
          <div className="log-body__title">{it.title}</div>
          {showAddr && it.addr && (
            <div className="log-body__addr"><Icon name="location" size={13}/><span>{it.addr}</span></div>
          )}
          <p className="log-body__text">{it.text}</p>
          {it.img && <div className="log-photo"><img src={it.img} alt=""/></div>}
          <div className="log-actions">
            <button><Icon name="share" size={16}/>分享</button>
            <button><Icon name="trash" size={16}/>刪除</button>
          </div>
        </div>
      </div>
    );
  }

  function HistoryScreen({ go }){
    return (
      <div className="screen has-tabbar fade-enter">
        <StatusBar dark time="8:00"/>
        <div className="screen__scroll">
          <Masthead eyebrow="旅程紀錄 · Chronicle" title="歷程"
            actions={<button className="iconbtn" style={{background:"var(--paper-sunk)"}} onClick={()=>go("createTrip",{})}>
              <Icon name="plus" size={22}/></button>}/>
          <div className="bookshelf">
            <div className="shelf__cap">旅程書架 · {TRIPS.length} 本</div>
            <div className="shelf">
              <div className="shelf__books">
                {TRIPS.map((t,idx)=>(
                  <div key={t.id} className={"book book--"+["a","c","b","d"][idx%4]}
                       style={{height: 190 + (idx%3)*14}}
                       onClick={()=>go("trip",{id:t.id})}>
                    <div className="book__badge"><Icon name={t.items?"book":"image-off"} size={13}/></div>
                    <div className="book__label"><div className="book__title">{t.name}</div></div>
                    <div className="book__count">{t.count.replace(" 筆記錄"," 篇")}</div>
                  </div>
                ))}
              </div>
              <div className="shelf__plank"/>
            </div>
          </div>
        </div>
      </div>
    );
  }

  function TripDetailScreen({ params, back }){
    const trip = TRIPS.find(t=>t.id===params.id);
    const items = trip.items || TIMELINE;
    return (
      <div className="screen fade-enter">
        <StatusBar dark time="8:01"/>
        <TopBar title={trip.name} onBack={back}
                right={<button className="iconbtn"><Icon name="sliders" size={20}/></button>}/>
        <div className="nb-wrap" style={{paddingTop:"calc(var(--safe-top) + 54px)", paddingBottom:"calc(var(--safe-bot) + 6px)"}}>
          <div className="tl-trip-meta" style={{padding:"2px 22px 2px"}}>
            <Icon name="calendar" size={17}/>{trip.dateLabel || trip.count}
          </div>
          <NotebookPager items={items}/>
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
