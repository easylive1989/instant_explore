// ui.jsx — shared primitives. Exports to window.
(function(){
  const Icon = window.Icon;
  const { CAT } = window.LS_DATA;

  function StatusBar({ light, time="8:08" }){
    return (
      <div className={"statusbar " + (light ? "is-light" : "is-dark")}>
        <div className="sb-time">{time}</div>
        <div className="sb-right">
          <svg width="18" height="13" viewBox="0 0 18 13" fill="currentColor" aria-hidden>
            <rect x="0"  y="9"  width="3" height="4"  rx="1"/>
            <rect x="5"  y="6"  width="3" height="7"  rx="1"/>
            <rect x="10" y="3"  width="3" height="10" rx="1"/>
            <rect x="15" y="0"  width="3" height="13" rx="1"/>
          </svg>
          <svg width="17" height="13" viewBox="0 0 17 13" fill="currentColor" aria-hidden>
            <path d="M8.5 2.3c2.7 0 5.2 1 7 2.8l-1.4 1.5A7.9 7.9 0 0 0 8.5 4.4 7.9 7.9 0 0 0 2.9 6.6L1.5 5.1A9.9 9.9 0 0 1 8.5 2.3zm0 3.6c1.7 0 3.3.7 4.5 1.8l-1.5 1.5A4 4 0 0 0 8.5 9.5 4 4 0 0 0 5.5 9.2L4 7.7A6.4 6.4 0 0 1 8.5 5.9zm0 3.7c.8 0 1.5.3 2 .9L8.5 12.5 6.5 10.5c.5-.6 1.2-.9 2-.9z"/>
          </svg>
          <div className="sb-batt"><i/></div>
        </div>
      </div>
    );
  }

  function TopBar({ title, onBack, right, dark, blur=true, leftTitle }){
    return (
      <div className={"topbar " + (dark?"is-dark ":"") + (blur?"is-blur":"")}>
        {onBack
          ? <button className="iconbtn" onClick={onBack} aria-label="返回"><Icon name="chevron-left" size={26}/></button>
          : <div className="topbar__spacer"/>}
        <div className={"topbar__title" + (leftTitle?" is-left":"")}>{title}</div>
        {right || <div className="topbar__spacer"/>}
      </div>
    );
  }

  function CategoryTag({ cat, onPhoto }){
    const c = CAT[cat];
    if(!c) return null;
    return (
      <span className={"tag tag--"+c.cls + (onPhoto?" on-photo":"")}>
        <Icon name={c.glyph} size={15} stroke={1.8}/>{c.label}
      </span>
    );
  }

  function GlyphThumb({ cat, className }){
    const c = CAT[cat] || CAT.nature;
    return (
      <div className={"glyph-thumb "+(className||"")}
           style={{ background:"var(--cat-"+c.cls+"-bg)", color:"var(--cat-"+c.cls+"-ink)" }}>
        <Icon name={c.glyph} size={34} stroke={1.6}/>
      </div>
    );
  }

  function Toggle({ on, onClick }){
    return <div className={"toggle"+(on?" is-on":"")} onClick={onClick}><i/></div>;
  }

  function Masthead({ eyebrow, title, actions }){
    return (
      <div className="masthead">
        <div className="masthead__top">
          <div>
            {eyebrow && <div className="masthead__eyebrow">{eyebrow}</div>}
            <h1>{title}</h1>
          </div>
          {actions && <div className="masthead__actions">{actions}</div>}
        </div>
        <div className="masthead__rule"/>
      </div>
    );
  }

  Object.assign(window, { StatusBar, TopBar, CategoryTag, GlyphThumb, Toggle, Masthead });
})();
