const checks = [
  "依距離篩選，只看走得到的地方",
  "多種主題分類，各有專屬故事",
  "收藏想去的地點，隨時回來",
];

const chips = [
  { label: "自然景觀", path: <path d="M3 19l6-9 4 5 3-4 5 8z" /> },
  {
    label: "人文古蹟",
    path: <path d="M4 9h16M5 9v9M9 9v9M15 9v9M19 9v9M3 20h18M4 9l8-5 8 5" />,
  },
  {
    label: "信仰聖地",
    path: (
      <>
        <path d="M6 4h12v16l-6-3-6 3z" />
        <path d="M12 4v6M9.5 7h5" />
      </>
    ),
  },
  {
    label: "城市地標",
    path: (
      <>
        <rect x="5" y="3" width="14" height="18" rx="1" />
        <path d="M9 7h2M13 7h2M9 11h2M13 11h2M9 15h2M13 15h2" />
      </>
    ),
  },
];

/// Feature 03 — explore what is nearby. Full-bleed photo with copy, checklist
/// and category chips anchored to the left.
export default function ExploreNearby() {
  return (
    <section className="bleed" id="explore">
      <div className="bleed__bg">
        <img src="/images/park.jpg" alt="公園步道" />
      </div>
      <div className="wrap">
        <div className="bleed__in">
          <span className="over">功能 03 · Explore Nearby</span>
          <h2>探索身邊的風景</h2>
          <p>
            翻開地圖之前，先看看方圓之內。Lorescape
            依距離與主題，為你列出附近值得停留的每一個角落——每一種風景，都有屬於它的故事。
          </p>
          <div className="checks">
            {checks.map((text) => (
              <div className="check" key={text}>
                <span className="tick">
                  <svg
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="#fff"
                    strokeWidth="2.4"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  >
                    <polyline points="5 12.5 10 17.5 19 7" />
                  </svg>
                </span>
                {text}
              </div>
            ))}
          </div>
          <div className="cat-chips">
            {chips.map((chip) => (
              <span className="cat-chip" key={chip.label}>
                <svg
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="1.8"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                >
                  {chip.path}
                </svg>
                {chip.label}
              </span>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
