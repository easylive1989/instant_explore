import type { Dict } from "@/i18n/dictionaries";

/// Feature 01 — AI writes a story for the place in front of you. A split
/// layout with copy + subcards on one side and a portrait photo on the other.
export default function LocalStories({ d }: { d: Dict["localStories"] }) {
  return (
    <section className="section section--sunk" id="stories">
      <div className="wrap">
        <div className="split">
          <div className="split__copy">
            <div className="sec-label">
              <span className="bar" />
              <span className="no">{d.no}</span>
            </div>
            <h2 className="h2">
              {d.h2Top}
              <br />
              {d.h2Bottom}
            </h2>
            <p className="sec-lede">{d.lede}</p>
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
                  <h3>{d.card1Title}</h3>
                  <p>{d.card1Body}</p>
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
                  <h3>{d.card2Title}</h3>
                  <p>{d.card2Body}</p>
                </div>
              </div>
            </div>
          </div>
          <div className="split__media">
            <img src="/images/temple.jpg" alt={d.mediaAlt} />
            <div className="media-cap">
              {d.mediaCap}
              <span className="o">{d.mediaOrigin}</span>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
