import type { Dict } from "@/i18n/dictionaries";

/// Pricing — trial-forward plan comparison in the Field Journal language.
/// Placed just before the final download CTA so visitors who have read the
/// value proposition can weigh the plans and see the 7-day free trial before
/// tapping through to the store.
export default function Pricing({ d }: { d: Dict["pricing"] }) {
  return (
    <section className="section" id="pricing">
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
        <div className="plans">
          {d.plans.map((plan) => (
            <div
              className={plan.recommended ? "plan plan--recommended" : "plan"}
              key={plan.name}
            >
              {plan.recommended && (
                <span className="plan__flag">{d.recommendedBadge}</span>
              )}
              <div className="plan__name">{plan.name}</div>
              <div className="plan__price">
                <span className="plan__amount">{plan.price}</span>
                {plan.period && <span className="plan__period">{plan.period}</span>}
              </div>
              <p className="plan__desc">{plan.desc}</p>
              {plan.trial && <span className="plan__trial">{d.trialBadge}</span>}
            </div>
          ))}
        </div>
        <p className="plans__note">{d.note}</p>
      </div>
    </section>
  );
}
