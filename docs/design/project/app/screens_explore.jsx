// screens_explore.jsx — Explore tab, filter sheet, saved sheet
(function(){
  const { useState } = React;
  const Icon = window.Icon;
  const { StatusBar, TopBar, CategoryTag, GlyphThumb } = window;
  const { PLACES, CAT } = window.LS_DATA;

  function PlaceRow({ p, saved, onToggle, onOpen }){
    return (
      <div className="place" onClick={onOpen}>
        <div className="place__thumb">
          {p.glyph ? <GlyphThumb cat={p.cat}/> : <img src={p.img} alt=""/>}
        </div>
        <div className="place__body">
          <div className="place__name">{p.name}</div>
          <div><CategoryTag cat={p.cat}/></div>
        </div>
        <button className={"place__bk"+(saved?" is-on":"")}
                onClick={(e)=>{ e.stopPropagation(); onToggle(); }} aria-label="收藏">
          <Icon name={saved?"bookmark-fill":"bookmark"} size={24}/>
        </button>
      </div>
    );
  }

  function ExploreScreen({ go, openSheet, saved, toggleSaved }){
    return (
      <div className="screen has-tabbar fade-enter">
        <StatusBar dark time="8:00"/>
        <div className="screen__scroll">
          <div className="lg-header" style={{paddingTop:8}}>
            <h1>探索</h1>
            <div className="actions">
              <button className="iconbtn" style={{background:"var(--paper-sunk)"}}
                      onClick={()=>openSheet("filter")}><Icon name="sliders" size={22}/></button>
              <button className="iconbtn" style={{background:"var(--clay)",color:"#fff"}}>
                <Icon name="refresh" size={20}/></button>
            </div>
          </div>
          <div className="search">
            <Icon name="search" size={20}/>
            <input placeholder="搜尋地點、城市或地標……"/>
          </div>
          <div className="places">
            {PLACES.map(p=>(
              <PlaceRow key={p.id} p={p} saved={saved.includes(p.id)}
                        onToggle={()=>toggleSaved(p.id)} onOpen={()=>go("place",{id:p.id})}/>
            ))}
          </div>
        </div>
        <button className="fab" onClick={()=>openSheet("saved")} aria-label="儲存的地點">
          <Icon name="bookmark-fill" size={24}/>
          {saved.length>0 && <span className="fab__badge">{saved.length}</span>}
        </button>
      </div>
    );
  }

  function FilterSheet({ close }){
    const [km, setKm] = useState(10);
    return (
      <div className="overlay" onClick={close}>
        <div className="sheet" onClick={e=>e.stopPropagation()}>
          <div className="sheet__grab"/>
          <div className="sheet__head"><h3>篩選條件</h3></div>
          <div className="slider-wrap">
            <div className="muted-3" style={{fontSize:14}}>最大距離</div>
            <div style={{display:"flex",alignItems:"baseline",gap:6,marginTop:6}}>
              <span className="slider-val">{km}</span>
              <span className="muted" style={{fontWeight:600}}>km</span>
            </div>
            <input className="slider" type="range" min="0.5" max="30" step="0.5"
                   value={km} onChange={e=>setKm(+e.target.value)}/>
            <div className="slider-ends"><span>500 m</span><span>30 km</span></div>
            <p className="muted" style={{fontSize:14,marginTop:14,lineHeight:1.6}}>
              只顯示在您目前位置指定距離內的地點。</p>
          </div>
          <div style={{textAlign:"center",marginTop:8}}>
            <button className="btn--link" style={{margin:"0 auto"}} onClick={()=>setKm(10)}>重設為預設值</button>
          </div>
        </div>
      </div>
    );
  }

  function SavedSheet({ close, saved, go }){
    const items = PLACES.filter(p=>saved.includes(p.id));
    return (
      <div className="overlay" onClick={close}>
        <div className="sheet" onClick={e=>e.stopPropagation()} style={{minHeight:"60%"}}>
          <div className="sheet__grab"/>
          <div className="sheet__head">
            <h3><Icon name="bookmark-fill" size={20} style={{color:"var(--clay)"}}/>儲存的地點</h3>
            <button className="iconbtn" onClick={close}><Icon name="x" size={22}/></button>
          </div>
          {items.length===0
            ? <p className="muted" style={{padding:"30px 0",textAlign:"center"}}>還沒有收藏任何地點。</p>
            : items.map(p=>(
              <div className="saved-row" key={p.id} onClick={()=>{ close(); go("place",{id:p.id}); }}>
                <div className="saved-row__thumb">
                  {p.glyph ? <GlyphThumb cat={p.cat}/> : <img src={p.img} alt=""/>}
                </div>
                <div style={{flex:1}}>
                  <div style={{fontFamily:"var(--serif)",fontWeight:600,fontSize:17}}>{p.name}</div>
                  <div style={{marginTop:6}}><CategoryTag cat={p.cat}/></div>
                </div>
                <Icon name="chevron-right" size={20} style={{color:"var(--ink-3)"}}/>
              </div>
            ))}
        </div>
      </div>
    );
  }

  Object.assign(window, { ExploreScreen, FilterSheet, SavedSheet });
})();
