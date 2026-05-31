// screens_settings.jsx — 設定 tab
(function(){
  const { useState } = React;
  const Icon = window.Icon;
  const { StatusBar, Toggle } = window;

  function SettingsScreen({ go }){
    const [sync,setSync] = useState(true);
    return (
      <div className="screen has-tabbar fade-enter">
        <StatusBar dark time="8:00"/>
        <div className="screen__scroll">
          <div className="lg-header" style={{paddingTop:8,paddingBottom:14}}><h1>設定</h1></div>
          <div className="settings">

            <div className="upgrade" onClick={()=>go("paywall",{})}>
              <div className="upgrade__gem"><Icon name="gem" size={30}/></div>
              <div className="upgrade__b">
                <div className="upgrade__t">解鎖無盡旅程</div>
                <div className="upgrade__d">升級高級會員 · 無限導覽與路線規劃</div>
              </div>
              <Icon name="chevron-right" size={22} style={{color:"var(--on-dark-2)"}}/>
            </div>

            <div className="set-group">
              <div className="set-group__lab">偏好設定</div>
              <div className="set-card">
                <div className="set-row">
                  <div className="set-ic"><Icon name="globe" size={20}/></div>
                  <div className="set-row__b"><div className="set-row__t">語言設定</div></div>
                  <div className="set-row__r">繁體中文 <Icon name="chevron-right" size={18}/></div>
                </div>
              </div>
            </div>

            <div className="set-group">
              <div className="set-group__lab">帳號</div>
              <div className="set-card">
                <div className="set-row">
                  <div className="set-ic"><Icon name="user" size={20}/></div>
                  <div className="set-row__b"><div className="set-row__t">已登入:Wu Paul</div>
                    <div className="set-row__d">wu.paul@example.com</div></div>
                  <div className="set-row__r" style={{color:"var(--clay)",fontWeight:600}}>登出</div>
                </div>
              </div>
            </div>

            <div className="set-group">
              <div className="set-group__lab">雲端同步</div>
              <div className="set-card">
                <div className="set-row">
                  <div className="set-ic"><Icon name="cloud-sync" size={20}/></div>
                  <div className="set-row__b"><div className="set-row__t">同步到雲端</div>
                    <div className="set-row__d">您的地點與旅程會在裝置間保持同步。</div></div>
                  <Toggle on={sync} onClick={()=>setSync(s=>!s)}/>
                </div>
              </div>
            </div>

            <div className="set-group">
              <div className="set-group__lab">每日使用量</div>
              <div className="set-card">
                <div className="set-row">
                  <div className="set-ic"><Icon name="bar-chart" size={20}/></div>
                  <div className="set-row__b"><div className="set-row__t">每日使用量</div></div>
                  <div className="set-row__r">今日剩餘 1 次</div>
                </div>
              </div>
            </div>

          </div>
        </div>
      </div>
    );
  }
  window.SettingsScreen = SettingsScreen;
})();
