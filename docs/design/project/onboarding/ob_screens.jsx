// ob_screens.jsx — Lorescape Onboarding screens
// Welcome / Value / Personalize. Each reads a `tone` ("dark" | "paper").
(function(){
  const { useRef, useEffect } = React;
  const Icon = window.Icon;
  const { StatusBar } = window;

  // ---- pointer / tilt parallax for the welcome hero ----
  function useParallax(){
    const ref = useRef(null);
    useEffect(()=>{
      const el = ref.current; if(!el) return;
      let raf = 0, tx = 0, ty = 0;
      const apply = ()=>{ el.style.transform = `translate(${tx}px,${ty}px)`; raf = 0; };
      const onMove = (e)=>{
        const r = el.getBoundingClientRect();
        const cx = (e.clientX - (r.left + r.width/2)) / (r.width/2);
        const cy = (e.clientY - (r.top  + r.height/2)) / (r.height/2);
        tx = Math.max(-1,Math.min(1,cx)) * -16;
        ty = Math.max(-1,Math.min(1,cy)) * -12;
        if(!raf) raf = requestAnimationFrame(apply);
      };
      window.addEventListener("mousemove", onMove);
      return ()=>{ window.removeEventListener("mousemove", onMove); if(raf) cancelAnimationFrame(raf); };
    },[]);
    return ref;
  }

  // ============================================================
  // STEP 1 — WELCOME
  // ============================================================
  const HERO = "assets/img/stpeters.jpg";
  const W_TITLE = <>讓每一處風景<br/>開口說它的故事</>;
  const W_TAG = "AI 隨行的旅行說書人。走到哪,就把那裡的來歷、傳說與歷史,說給你聽。";

  function WelcomeScreen({ tone }){
    const par = useParallax();
    if(tone==="dark"){
      return (
        <div className="ob-screen is-dark" key="w-dark">
          <StatusBar light time="8:08"/>
          <div className="ob-hero">
            <div className="ob-hero__par" ref={par}>
              <img className="ob-hero__img" src={HERO} alt=""/>
            </div>
            <div className="ob-hero__scrim"/>
            <div className="ob-hero__grain"/>
          </div>
          <div className="ob-welcome on-photo">
            <div className="ob-eyebrow ob-rise" style={{animationDelay:".05s"}}>
              <span className="ob-rule"/>LORESCAPE
            </div>
            <h1 className="ob-welcome__title ob-rise" style={{animationDelay:".14s"}}>{W_TITLE}</h1>
            <p className="ob-welcome__tag ob-rise" style={{animationDelay:".26s"}}>{W_TAG}</p>
            <div className="ob-welcome__loc ob-rise" style={{animationDelay:".36s"}}>
              <Icon name="location" size={15}/> 聖伯多祿大殿 · VATICAN
            </div>
          </div>
        </div>
      );
    }
    // paper — field-journal postcard
    return (
      <div className="ob-screen is-paper" key="w-paper">
        <StatusBar dark time="8:08"/>
        <div className="ob-welcome--paper">
          <div className="ob-eyebrow ob-rise" style={{animationDelay:".05s",marginBottom:18}}>
            <span className="ob-rule"/>LORESCAPE
          </div>
          <div className="ob-postcard ob-rise" style={{animationDelay:".12s"}}>
            <div className="ob-stamp"><b>Anno<br/>I</b></div>
            <div className="ob-postcard__img"><img src={HERO} alt=""/></div>
            <div className="ob-postcard__cap"><span>ST. PETER'S BASILICA</span><span>VATICAN</span></div>
          </div>
          <h1 className="ob-welcome__title ob-rise" style={{animationDelay:".24s"}}>{W_TITLE}</h1>
          <p className="ob-welcome__tag ob-rise" style={{animationDelay:".34s"}}>{W_TAG}</p>
        </div>
      </div>
    );
  }

  // ============================================================
  // STEP 2 — FEATURE VALUE
  // ============================================================
  const PILLARS = [
    { no:"I",   icon:"book-open", t:"AI 生成的在地故事",
      d:"為眼前的地標、古蹟與山林,即時編寫值得細讀的故事,還能化作語音邊走邊聽。" },
    { no:"II",  icon:"compass",   t:"探索身邊的風景",
      d:"依距離與主題,發現方圓之內值得停留的每一個角落。" },
    { no:"III", icon:"book",      t:"收藏你的旅行歷程",
      d:"走過的地方自動成冊,串成一條屬於你的旅程時間軸。" },
  ];

  function ValueScreen({ tone }){
    const dark = tone==="dark";
    return (
      <div className={"ob-screen "+(dark?"is-dark":"is-paper")} key={"v-"+tone}>
        <StatusBar light={dark} time="8:08"/>
        <div className="ob-value">
          <div className="ob-value__head">
            <div className="ob-value__kicker ob-rise" style={{animationDelay:".04s"}}>你的隨行旅伴</div>
            <h2 className="ob-value__h ob-rise" style={{animationDelay:".12s"}}>口袋裡的旅行說書人</h2>
            <p className="ob-value__sub ob-rise" style={{animationDelay:".22s"}}>
              Lorescape 把導覽、探索與旅誌收進一處,讓每段旅程都有故事相伴。
            </p>
          </div>
          <div className="ob-pillars">
            {PILLARS.map((p,i)=>(
              <div className="ob-pillar ob-rise" key={p.no} style={{animationDelay:(0.32+i*0.11)+"s"}}>
                <div className="ob-pillar__ic"><Icon name={p.icon} size={26} stroke={1.8}/></div>
                <div style={{flex:1,minWidth:0}}>
                  <div className="ob-pillar__no">{p.no}</div>
                  <div className="ob-pillar__t">{p.t}</div>
                  <div className="ob-pillar__d">{p.d}</div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    );
  }

  // ============================================================
  // STEP 3 — CATEGORY SHOWCASE (四大分類)
  // ============================================================
  const CATS = [
    { id:"nature",   name:"自然景觀", latin:"NATURE & WILD", img:"assets/img/park.jpg",     mark:"mountain" },
    { id:"heritage", name:"人文古蹟", latin:"HERITAGE",      img:"assets/img/agra.jpg",     mark:"columns" },
    { id:"sacred",   name:"信仰聖地", latin:"SACRED PLACES", img:"assets/img/temple.jpg",   mark:"book-marker" },
    { id:"urban",    name:"城市地標", latin:"LANDMARKS",     img:"assets/img/stpeters.jpg", mark:"building" },
  ];

  function CategoriesScreen({ tone }){
    const dark = tone==="dark";
    return (
      <div className={"ob-screen "+(dark?"is-dark":"is-paper")} key={"p-"+tone}>
        <StatusBar light={dark} time="8:08"/>
        <div className="ob-pers">
          <div className="ob-pers__head">
            <div className="ob-pers__kicker ob-rise" style={{animationDelay:".04s"}}>探索版圖</div>
            <h2 className="ob-pers__h ob-rise" style={{animationDelay:".12s"}}>四種風景,等你細讀</h2>
            <p className="ob-pers__sub ob-rise" style={{animationDelay:".2s"}}>
              從山林到信仰聖地,Lorescape 為每一種風景,備好屬於它的故事。
            </p>
          </div>
          <div className="ob-grid">
            {CATS.map((c,i)=>(
              <div key={c.id} className="ob-cat ob-rise" style={{animationDelay:(0.26+i*0.08)+"s"}}>
                <div className="ob-cat__img"><img src={c.img} alt=""/></div>
                <div className="ob-cat__scrim"/>
                <div className="ob-cat__mark"><Icon name={c.mark} size={17} stroke={1.9}/></div>
                <div className="ob-cat__lab">
                  <div className="ob-cat__name">{c.name}</div>
                  <div className="ob-cat__latin">{c.latin}</div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    );
  }

  Object.assign(window, { WelcomeScreen, ValueScreen, CategoriesScreen, OB_CATS:CATS });
})();
