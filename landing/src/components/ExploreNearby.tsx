import type { Dict } from "@/i18n/dictionaries";

const chipPaths = [
  <path key="nature" d="M3 19l6-9 4 5 3-4 5 8z" />,
  <path key="heritage" d="M4 9h16M5 9v9M9 9v9M15 9v9M19 9v9M3 20h18M4 9l8-5 8 5" />,
  <g key="sacred">
    <path d="M6 4h12v16l-6-3-6 3z" />
    <path d="M12 4v6M9.5 7h5" />
  </g>,
  <g key="city">
    <rect x="5" y="3" width="14" height="18" rx="1" />
    <path d="M9 7h2M13 7h2M9 11h2M13 11h2M9 15h2M13 15h2" />
  </g>,
];

/// Feature 03 — explore what is nearby. Full-bleed photo with copy, checklist
/// and category chips anchored to the left.
export default function ExploreNearby({ d }: { d: Dict["exploreNearby"] }) {
  return (
    <section className="bleed" id="explore">
      <div className="bleed__bg">
        <img src="/images/park.jpg" alt={d.imageAlt} />
      </div>
      <div className="wrap">
        <div className="bleed__in">
          <span className="over">{d.over}</span>
          <h2>{d.h2}</h2>
          <p>{d.body}</p>
          <div className="checks">
            {d.checks.map((text) => (
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
            {d.chips.map((label, i) => (
              <span className="cat-chip" key={label}>
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                  {chipPaths[i]}
                </svg>
                {label}
              </span>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
