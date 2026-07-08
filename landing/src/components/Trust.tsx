import type { Dict } from "@/i18n/dictionaries";

/// Trust — answers the ICP's first objection about AI content ("is it made
/// up?") by foregrounding Wikipedia grounding as the core differentiator, with
/// a proof chip. Sits before the pricing ask so trust is established first.
export default function Trust({ d }: { d: Dict["trust"] }) {
  return (
    <section className="section" id="trust">
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
          <div className="trust-proof">
            <span className="trust-proof__mark" aria-hidden="true">
              W
            </span>
            <span>{d.proof}</span>
          </div>
        </div>
      </div>
    </section>
  );
}
