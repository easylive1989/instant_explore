// screens_explore.jsx — Explore tab (world map), filter sheet, saved sheet
(function(){
  const { useState, useRef, useEffect } = React;
  const Icon = window.Icon;
  const { StatusBar, TopBar, CategoryTag, GlyphThumb, Masthead } = window;
  const { PLACES, CAT } = window.LS_DATA;

  function ExploreScreen({ go, openSheet, saved, toggleSaved }){
    const elRef = useRef(null);
    const mapRef = useRef(null);

    useEffect(()=>{
      const L = window.L;
      if(mapRef.current || !elRef.current || !L) return;
      const map = L.map(elRef.current, { zoomControl:false, worldCopyJump:true, minZoom:2 });
      mapRef.current = map;
      L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        { attribution:'© OpenStreetMap contributors', maxZoom:18 }).addTo(map);
      const pts = PLACES.filter(p=>p.coord);
      const markers = pts.map(p=>{
        const cls = "map-pin"+((p.cat==="urban"||p.cat==="heritage")?(" map-pin--"+p.cat):"");
        const icon = L.divIcon({ className:"", html:'<div class="'+cls+'"><i></i></div>', iconSize:[30,30], iconAnchor:[15,30] });
        const m = L.marker(p.coord, { icon }).addTo(map);
        m.on("click", ()=>go("place",{id:p.id}));
        return m;
      });
      if(markers.length){
        const grp = L.featureGroup(markers);
        map.fitBounds(grp.getBounds().pad(0.35), { maxZoom:6 });
      } else { map.setView([24.15,120.66], 11); }
      const t = setTimeout(()=>map.invalidateSize(), 260);
      return ()=>{ clearTimeout(t); map.remove(); mapRef.current=null; };
    }, []);

    function focus(p){
      if(mapRef.current && p.coord) mapRef.current.flyTo(p.coord, 14, { duration:1.1 });
    }

    return (
      <div className="screen has-tabbar fade-enter">
        <StatusBar dark time="8:00"/>
        <div className="map-el" ref={elRef}/>
        <div className="map-top">
          <div className="map-hd">
            <div>
              <div className="map-hd__eyebrow">{PLACES.length} 個地點 · Atlas</div>
              <h1>探索</h1>
            </div>
            <div className="map-hd__acts">
              <button className="iconbtn" style={{background:"var(--paper-raised)",boxShadow:"var(--e1)"}}
                      onClick={()=>openSheet("filter")}><Icon name="sliders" size={22}/></button>
              <button className="iconbtn" style={{background:"var(--clay)",color:"#fff",boxShadow:"var(--e1)"}}
                      onClick={()=>{ const m=mapRef.current, L=window.L; if(m&&L){ const g=L.featureGroup(PLACES.filter(p=>p.coord).map(p=>L.marker(p.coord))); m.flyToBounds(g.getBounds().pad(0.35),{maxZoom:6}); } }}>
                <Icon name="refresh" size={20}/></button>
            </div>
          </div>
          <div className="search map-search">
            <Icon name="search" size={20}/>
            <input placeholder="搜尋地點、城市或地標……"/>
          </div>
        </div>
        <div className="map-cards">
          {PLACES.map(p=>(
            <div key={p.id} className="map-card" onClick={()=>focus(p)}>
              <div className="map-card__thumb">
                {p.glyph ? <GlyphThumb cat={p.cat}/> : <img src={p.img} alt=""/>}
              </div>
              <div className="map-card__b">
                <div className="map-card__name">{p.name}</div>
                {p.latin && <div className="map-card__latin">{p.latin.split(" · ")[0]}</div>}
                <div><CategoryTag cat={p.cat}/></div>
              </div>
              <button className="map-card__go" onClick={(e)=>{ e.stopPropagation(); go("place",{id:p.id}); }} aria-label="查看地點">
                <Icon name="chevron-right" size={20}/></button>
            </div>
          ))}
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
