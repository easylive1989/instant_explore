// ob_app.jsx — Lorescape Onboarding shell
(function(){
  const { useState, useEffect } = React;
  const Icon = window.Icon;
  const { WelcomeScreen, ValueScreen, CategoriesScreen } = window;
  const {
    useTweaks, TweaksPanel, TweakSection, TweakRadio,
  } = window;

  const ACCENTS = {
    terracotta:{ clay:"#BC5E3E", deep:"#97442A", soft:"#F1DDCE", tint:"#F7E8DD" },
    amber:     { clay:"#B7842B", deep:"#8A5F18", soft:"#F0E5C8", tint:"#F6EED8" },
    sage:      { clay:"#5F7148", deep:"#46542F", soft:"#E3E8D3", tint:"#EBEFE0" },
  };

  // flow variant → tone per step (welcome / value / personalize)
  const FLOWS = {
    immersive:["dark","dark","dark"],   // 沉浸：整段深色攝影
    paper:    ["paper","paper","paper"], // 紙感：淺色版面
    hybrid:   ["dark","paper","paper"],  // 混合：深色開場 → 紙感操作
  };

  const STEPS = 3;
  const NEXT_LABEL = ["開始旅程","繼續","進入 Lorescape"];
  const APP_URL = "Lorescape Redesign.html";

  const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
    "flow": "hybrid",
    "accent": "terracotta",
    "headlineFont": "serif"
  }/*EDITMODE-END*/;

  function App(){
    const [t, setTweak] = useTweaks(TWEAK_DEFAULTS);
    const [step, setStep] = useState(()=> {
      const s = +localStorage.getItem("ob_step"); return (s>=0 && s<STEPS) ? s : 0;
    });
    const [finishing, setFinishing] = useState(false);

    useEffect(()=>{ localStorage.setItem("ob_step", step); },[step]);

    const tones = FLOWS[t.flow] || FLOWS.hybrid;
    const tone = tones[step];
    const dark = tone==="dark";

    const a = ACCENTS[t.accent] || ACCENTS.terracotta;
    const vars = {
      "--clay":a.clay, "--clay-deep":a.deep, "--clay-soft":a.soft, "--clay-tint":a.tint,
      "--serif": t.headlineFont==="sans" ? 'var(--sans)' : '"Noto Serif TC","Songti TC",serif',
    };

    const goNext = ()=>{
      if(step < STEPS-1) setStep(step+1);
      else finish();
    };
    const goBack = ()=> setStep(s=> Math.max(0, s-1));

    // swipe nav: left → next, right → back
    const sw = React.useRef(null);
    const onTouchStart = e=>{ const t0=e.touches[0]; sw.current={x:t0.clientX,y:t0.clientY}; };
    const onTouchEnd = e=>{
      if(!sw.current) return;
      const t1=e.changedTouches[0];
      const dx=t1.clientX-sw.current.x, dy=t1.clientY-sw.current.y;
      sw.current=null;
      if(Math.abs(dx)<50 || Math.abs(dx)<Math.abs(dy)) return;
      if(dx<0) goNext(); else goBack();
    };
    const finish = ()=>{
      setFinishing(true);
      localStorage.removeItem("ob_step");
      setTimeout(()=>{ window.location.href = APP_URL; }, 1700);
    };

    const body = (()=>{
      switch(step){
        case 0: return <WelcomeScreen tone={tone}/>;
        case 1: return <ValueScreen tone={tone}/>;
        case 2: return <CategoriesScreen tone={tone}/>;
        default:return null;
      }
    })();

    return (
      <div className="stage">
        <div className="phone" style={vars} onTouchStart={onTouchStart} onTouchEnd={onTouchEnd}>
          <div className="phone__notch"/>

          {/* animated screen body (re-keyed per step so entrance replays) */}
          <div key={step+"-"+tone}>{body}</div>

          {/* progress + skip */}
          <div className={"ob-top "+(dark?"is-dark":"is-paper")}>
            <div className="ob-progress">
              {Array.from({length:STEPS}).map((_,i)=>(
                <div key={i} className={"ob-dot"+(i<step?" is-done":"")+(i===step?" is-on":"")}/>
              ))}
            </div>
            {step<STEPS-1 && <button className="ob-skip" onClick={finish}>略過</button>}
          </div>

          {/* action dock */}
          <div className={"ob-dock "+(dark?"is-dark":"is-paper")}>
            <button className="btn btn--primary" onClick={goNext}>
              {step===2 && <Icon name="sparkle" size={18}/>}
              {NEXT_LABEL[step]}
              {step<2 && <Icon name="chevron-right" size={20}/>}
            </button>
          </div>

          {/* finish */}
          {finishing && (
            <div className="ob-finish">
              <div className="ob-finish__gem"><Icon name="gem" size={84} stroke={1.2}/></div>
              <div className="ob-finish__t">旅程,啟程</div>
              <div className="ob-finish__d">已為你備好專屬的故事羅盤,<br/>翻開 Lorescape 的第一頁。</div>
              <div className="ob-finish__row"><span className="spinner"/> 正在為你編纂…</div>
            </div>
          )}

          <div className={"home-ind"+(dark?" is-light":"")}/>
        </div>

        <TweaksPanel title="Lorescape Onboarding">
          <TweakSection label="流程版本"/>
          <TweakRadio label="Flow" value={t.flow}
            options={["immersive","paper","hybrid"]}
            onChange={v=>setTweak("flow",v)}/>
          <TweakSection label="品牌主色"/>
          <TweakRadio label="Accent" value={t.accent}
            options={["terracotta","amber","sage"]}
            onChange={v=>setTweak("accent",v)}/>
          <TweakSection label="標題字體"/>
          <TweakRadio label="Headline" value={t.headlineFont}
            options={["serif","sans"]}
            onChange={v=>setTweak("headlineFont",v)}/>
        </TweaksPanel>
      </div>
    );
  }

  window.LorescapeOnboarding = App;
})();
