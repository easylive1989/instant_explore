// app.jsx — Lorescape shell: nav stack, tab bar, sheets, tweaks
(function(){
  const { useState, useEffect } = React;
  const Icon = window.Icon;
  const { PLACES } = window.LS_DATA;
  const {
    ExploreScreen, FilterSheet, SavedSheet,
    PlaceScreen, ReaderScreen,
    StoriesScreen, HistoryScreen, TripDetailScreen, CreateTripScreen, DatePickerSheet,
    SettingsScreen, PaywallScreen,
    useTweaks, TweaksPanel, TweakSection, TweakRadio,
  } = window;

  const TABS = [
    { id:"stories",  label:"故事", icon:"book-open" },
    { id:"explore",  label:"探索", icon:"compass" },
    { id:"history",  label:"歷程", icon:"book" },
    { id:"settings", label:"設定", icon:"settings" },
  ];
  const TAB_IDS = TABS.map(t=>t.id);

  const ACCENTS = {
    terracotta:{ clay:"#BC5E3E", deep:"#97442A", soft:"#F1DDCE", tint:"#F7E8DD" },
    amber:     { clay:"#B7842B", deep:"#8A5F18", soft:"#F0E5C8", tint:"#F6EED8" },
    sage:      { clay:"#5F7148", deep:"#46542F", soft:"#E3E8D3", tint:"#EBEFE0" },
  };
  const READS = {
    paper:{ bg:"#F7F1E6", ink:"#221C14", dim:"#5E5341", line:"#E4DAC8" },
    sepia:{ bg:"#EFE2CB", ink:"#2A2013", dim:"#6A5A3E", line:"#DDCBA8" },
    night:{ bg:"#1B1611", ink:"#E9E1D2", dim:"#9A8E7B", line:"rgba(247,241,230,.14)" },
  };

  const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
    "accent": "terracotta",
    "reading": "paper",
    "headlineFont": "serif"
  }/*EDITMODE-END*/;

  function App(){
    const [t, setTweak] = useTweaks(TWEAK_DEFAULTS);
    const [stack, setStack] = useState([{ name:"stories", params:{} }]);
    const [sheet, setSheet] = useState(null);
    const [saved, setSaved] = useState(PLACES.filter(p=>p.saved).map(p=>p.id));
    const [draft, setDraft] = useState({ name:"", start:"", end:"" });

    const top = stack[stack.length-1];
    const isTabRoot = TAB_IDS.includes(top.name) && stack.length===1;

    const go = (name, params={}) => setStack(s=>[...s, { name, params }]);
    const back = () => setStack(s=> s.length>1 ? s.slice(0,-1) : s);
    const setTab = (name) => { setStack([{ name, params:{} }]); setSheet(null); };
    const openSheet = (type, params={}) => setSheet({ type, params });
    const closeSheet = () => setSheet(null);
    const toggleSaved = (id) => setSaved(s=> s.includes(id) ? s.filter(x=>x!==id) : [...s,id]);

    // apply themeable CSS vars
    const a = ACCENTS[t.accent]||ACCENTS.terracotta;
    const r = READS[t.reading]||READS.paper;
    const vars = {
      "--clay":a.clay, "--clay-deep":a.deep, "--clay-soft":a.soft, "--clay-tint":a.tint,
      "--read-bg":r.bg, "--read-ink":r.ink, "--read-dim":r.dim, "--read-line":r.line, "--read-cap":a.deep,
      "--serif": t.headlineFont==="sans" ? 'var(--sans)' : '"Noto Serif TC","Songti TC",serif',
    };

    const screenFor = (route) => {
      switch(route.name){
        case "stories":   return <StoriesScreen go={go}/>;
        case "explore":   return <ExploreScreen go={go} openSheet={openSheet} saved={saved} toggleSaved={toggleSaved}/>;
        case "history":   return <HistoryScreen go={go}/>;
        case "settings":  return <SettingsScreen go={go}/>;
        case "place":     return <PlaceScreen params={route.params} back={back}/>;
        case "reader":    return <ReaderScreen params={route.params} back={back} go={go}/>;
        case "trip":      return <TripDetailScreen params={route.params} back={back}/>;
        case "createTrip":return <CreateTripScreen back={back} openSheet={openSheet} draft={draft}/>;
        case "paywall":   return <PaywallScreen back={back}/>;
        default: return null;
      }
    };

    // home indicator color: light on dark screens
    const darkRoutes = ["paywall"];
    const lightInd = darkRoutes.includes(top.name);

    return (
      <div className="stage" style={vars}>
        <div className="phone">
          <div className="phone__notch"/>
          <div key={stack.length+"-"+top.name}>{screenFor(top)}</div>

          {isTabRoot && (
            <div className="tabbar">
              {TABS.map(tb=>(
                <button key={tb.id} className={"tab"+(top.name===tb.id?" is-on":"")} onClick={()=>setTab(tb.id)}>
                  <Icon name={tb.icon} size={24} stroke={top.name===tb.id?2:1.7}/>
                  <span>{tb.label}</span>
                </button>
              ))}
            </div>
          )}

          {sheet && sheet.type==="filter" && <FilterSheet close={closeSheet}/>}
          {sheet && sheet.type==="saved"  && <SavedSheet close={closeSheet} saved={saved} go={go}/>}
          {sheet && sheet.type==="date"   && (
            <DatePickerSheet close={closeSheet}
              onPick={(d)=> setDraft(prev=>({ ...prev, [sheet.params.which]:d })) }/>
          )}

          <div className={"home-ind"+(lightInd?" is-light":"")}/>
        </div>

        <TweaksPanel title="Lorescape Tweaks">
          <TweakSection label="品牌主色"/>
          <TweakRadio label="Accent" value={t.accent}
            options={["terracotta","amber","sage"]}
            onChange={v=>setTweak("accent",v)}/>
          <TweakSection label="閱讀介面"/>
          <TweakRadio label="Reading" value={t.reading}
            options={["paper","sepia","night"]}
            onChange={v=>setTweak("reading",v)}/>
          <TweakSection label="標題字體"/>
          <TweakRadio label="Headline" value={t.headlineFont}
            options={["serif","sans"]}
            onChange={v=>setTweak("headlineFont",v)}/>
        </TweaksPanel>
      </div>
    );
  }

  window.LorescapeApp = App;
})();
