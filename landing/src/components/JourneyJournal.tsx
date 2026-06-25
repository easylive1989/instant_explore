import type { Dict } from "@/i18n/dictionaries";

/// Feature 04 — your journey is bound into a journal automatically. Centered
/// header with three stat-style cards.
export default function JourneyJournal({ d }: { d: Dict["journeyJournal"] }) {
  return (
    <section className="section" id="journey">
      <div className="wrap">
        <div className="stats-head">
          <div className="sec-label" style={{ justifyContent: "center" }}>
            <span className="bar" />
            <span className="no">{d.no}</span>
            <span className="bar" />
          </div>
          <h2 className="h2">{d.h2}</h2>
          <p
            className="sec-lede"
            style={{ marginLeft: "auto", marginRight: "auto", textAlign: "center" }}
          >
            {d.lede}
          </p>
        </div>
        <div className="stats">
          {d.stats.map((stat) => (
            <div className="stat" key={stat.num}>
              <div className="num">{stat.num}</div>
              <div className="lab">{stat.lab}</div>
              <div className="cn">{stat.caption}</div>
              <p>{stat.body}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
