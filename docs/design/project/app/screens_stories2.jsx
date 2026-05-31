// screens_stories.jsx — 故事 feed tab
(function(){
  const Icon = window.Icon;
  const { StatusBar } = window;
  const { STORIES } = window.LS_DATA;

  function StoriesScreen({ go }){
    return (
      <div className="screen has-tabbar fade-enter">
        <StatusBar dark time="7:59"/>
        <div className="screen__scroll">
          <div className="lg-header" style={{paddingTop:8,paddingBottom:10}}>
            <h1>故事</h1>
            <div className="actions"><button className="iconbtn" style={{background:"var(--paper-sunk)"}}><Icon name="search" size={21}/></button></div>
          </div>
          <div className="story-feed">
            {STORIES.map((s,i)=>(
              <React.Fragment key={s.id}>
                <div className="story-card" onClick={()=>go("reader",{story:s})}>
                  <div className="story-card__img"><img src={s.img} alt=""/></div>
                  <div className="story-card__meta">
                    <div className="overline" style={{color:"var(--clay)"}}>{s.chapter}</div>
                    <div className="story-card__title" style={{marginTop:6}}>{s.title}</div>
                    <div className="story-card__date">{s.place} · {s.date}</div>
                    <div className="story-card__excerpt">{s.dropcap}{s.body[0]}</div>
                  </div>
                </div>
                {i<STORIES.length-1 && <div className="feed-divider"/>}
              </React.Fragment>
            ))}
          </div>
        </div>
      </div>
    );
  }
  window.StoriesScreen = StoriesScreen;
})();
