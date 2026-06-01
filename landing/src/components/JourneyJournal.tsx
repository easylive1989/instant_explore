const stats = [
  {
    num: "I",
    lab: "Auto Journal",
    cn: "自動成篇",
    body: "每聽完一段故事，就自動留下一篇可回味的手記。",
  },
  {
    num: "II",
    lab: "Trips",
    cn: "依旅程歸檔",
    body: "把沿途的記錄整理成一趟趟旅程，井然有序。",
  },
  {
    num: "III",
    lab: "Timeline",
    cn: "沿時間軸重溫",
    body: "順著時間軸回看，隨時重返走過的任何一個角落。",
  },
];

/// Feature 04 — your journey is bound into a journal automatically. Centered
/// header with three stat-style cards.
export default function JourneyJournal() {
  return (
    <section className="section" id="journey">
      <div className="wrap">
        <div className="stats-head">
          <div className="sec-label" style={{ justifyContent: "center" }}>
            <span className="bar" />
            <span className="no">功能 04</span>
            <span className="bar" />
          </div>
          <h2 className="h2">你的旅程，自動成冊</h2>
          <p
            className="sec-lede"
            style={{ marginLeft: "auto", marginRight: "auto", textAlign: "center" }}
          >
            每一次駐足，都被悄悄寫進一本屬於你的旅行手記。
          </p>
        </div>
        <div className="stats">
          {stats.map((stat) => (
            <div className="stat" key={stat.num}>
              <div className="num">{stat.num}</div>
              <div className="lab">{stat.lab}</div>
              <div className="cn">{stat.cn}</div>
              <p>{stat.body}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
