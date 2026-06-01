/// Feature 01 — AI writes a story for the place in front of you. A split
/// layout with copy + subcards on one side and a portrait photo on the other.
export default function LocalStories() {
  return (
    <section className="section section--sunk" id="stories">
      <div className="wrap">
        <div className="split">
          <div className="split__copy">
            <div className="sec-label">
              <span className="bar" />
              <span className="no">功能 01</span>
            </div>
            <h2 className="h2">
              為眼前的風景，
              <br />
              即時寫一篇故事
            </h2>
            <p className="sec-lede">
              不是條列式的百科資料。Lorescape
              為你經過的每座地標、古蹟與山林，當場編寫一篇有人物、有轉折、值得細讀的故事。
            </p>
            <div className="subgrid">
              <div className="subcard">
                <div className="ic">
                  <svg
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="1.7"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  >
                    <path d="M4 5a2 2 0 012-2h13v16H6a2 2 0 00-2 2z" />
                    <path d="M8 8h8M8 11.5h8M8 15h5" />
                  </svg>
                </div>
                <div>
                  <h3>值得細讀的歷史長文</h3>
                  <p>有起承轉合、有人物與懸念的敘事，而不是冰冷的年份與條目。</p>
                </div>
              </div>
              <div className="subcard">
                <div className="ic">
                  <svg
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="1.7"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  >
                    <path d="M3 10v4M7 7v10M11 4v16M15 8v8M19 10v4" />
                  </svg>
                </div>
                <div>
                  <h3>一鍵化為語音</h3>
                  <p>把手機收進口袋，邊走邊聽它把這裡的來歷娓娓道來。</p>
                </div>
              </div>
            </div>
          </div>
          <div className="split__media">
            <img src="/images/temple.jpg" alt="台中朝聖宮" />
            <div className="media-cap">
              台中朝聖宮
              <span className="o">Chaosheng Temple · Taichung</span>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
