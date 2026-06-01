const modes = [
  {
    num: "01",
    title: "摧毀與重生的百年豪賭",
    body: "儒略二世決定拆毀君士坦丁大帝的千年古教堂，這場瘋狂重建竟耗時百餘年。",
  },
  {
    num: "02",
    title: "祭壇之下的神聖祕密",
    body: "世界上最大的教堂並非教宗的主教座堂，因為它底下埋藏著更神聖的祕密。",
  },
  {
    num: "03",
    title: "文藝復興巨匠的接力賽",
    body: "米開朗基羅與拉斐爾輪番上陣，在同一座教堂留下各自的瘋狂印記。",
  },
];

/// Feature 02 — the same landmark, many stories. Dark section pairing the list
/// of angles with a phone mockup of the player.
export default function ManyAngles() {
  return (
    <section className="section dark" id="angles">
      <div className="wrap">
        <div className="depth-grid">
          <div className="depth-copy">
            <div className="sec-label">
              <span className="bar" />
              <span className="no">功能 02</span>
            </div>
            <span className="over">Many Angles, One Place</span>
            <h2 className="h2" style={{ marginTop: 14 }}>
              同一座地標，
              <br />
              不只一個故事
            </h2>
            <p className="sec-lede">
              權謀、傳說、建築祕辛——AI
              在每個地點為你備好幾種切入角度。挑一個最吸引你的，開始聆聽。
            </p>
            <div className="depth-modes" style={{ marginTop: 36 }}>
              {modes.map((mode) => (
                <div className="depth-mode" key={mode.num}>
                  <span className="num">{mode.num}</span>
                  <div>
                    <h3>{mode.title}</h3>
                    <p>{mode.body}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>
          <div className="depth-phone">
            <div className="phone">
              <div className="phone__frame">
                <div className="phone__screen">
                  <span className="phone__notch" />
                  <div className="ph-img">
                    <img src="/images/stpeters.jpg" alt="聖伯多祿大殿導覽" />
                  </div>
                  <div className="ph-top">
                    <span className="nm">正在播放</span>
                    <svg viewBox="0 0 24 24" fill="currentColor" width="20" height="20">
                      <circle cx="5" cy="12" r="2" />
                      <circle cx="12" cy="12" r="2" />
                      <circle cx="19" cy="12" r="2" />
                    </svg>
                  </div>
                  <div className="ph-mid">
                    <span className="badge">Anno · I</span>
                    <div className="ti">
                      摧毀與重生的
                      <br />
                      百年豪賭
                    </div>
                    <div className="su">St. Peter&apos;s Basilica</div>
                  </div>
                  <div className="ph-bot">
                    <div className="ph-bar">
                      <i />
                    </div>
                    <div className="ph-time">
                      <span>02:31</span>
                      <span>06:38</span>
                    </div>
                    <div className="ph-ctrl">
                      <svg viewBox="0 0 24 24" fill="currentColor">
                        <polygon points="19 5 9 12 19 19" />
                        <rect x="5" y="5" width="2.4" height="14" rx="1" />
                      </svg>
                      <span className="play">
                        <svg viewBox="0 0 24 24" fill="#fff">
                          <polygon points="7 4 20 12 7 20" />
                        </svg>
                      </span>
                      <svg viewBox="0 0 24 24" fill="currentColor">
                        <polygon points="5 5 15 12 5 19" />
                        <rect x="16.6" y="5" width="2.4" height="14" rx="1" />
                      </svg>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
