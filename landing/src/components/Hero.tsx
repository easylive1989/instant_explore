import type { Dict } from "@/i18n/dictionaries";
import StoreButtons from "./StoreButtons";
import { showDownloadLinks } from "@/lib/downloadLinks";

/// Centered hero: pill kicker, headline, lede, store CTAs and a wide "plate"
/// showcase image with a now-playing tag and caption.
export default function Hero({ d, store }: { d: Dict["hero"]; store: Dict["storeButtons"] }) {
  return (
    <section className="hero" id="top">
      <div className="wrap">
        <span className="pill">
          <span className="dot" />
          {d.pill}
        </span>
        <h1>
          {d.headlineTop}
          <br />
          <span className="clay">{d.headlineClay}</span>
        </h1>
        <p className="lede">{d.lede}</p>
        {showDownloadLinks && (
          <div className="hero__cta">
            <StoreButtons location="hero" variant="light" labels={store} />
          </div>
        )}
        <div className="hero__scroll">
          {d.scroll}
          <svg
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="1.6"
            strokeLinecap="round"
            strokeLinejoin="round"
          >
            <path d="M6 9l6 6 6-6" />
          </svg>
        </div>
      </div>

      <div className="wrap">
        <div className="plate">
          <div className="plate__frame">
            <img src="/images/stpeters.jpg" alt={d.plateImageAlt} />
            <span className="plate__tag">
              <svg
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="1.8"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <polygon points="7 4 20 12 7 20" fill="currentColor" stroke="none" />
              </svg>
              {d.nowTouring}
            </span>
            <div className="plate__cap">
              <span className="ln" />
              <span>
                <span className="t">{d.plateTitle}</span>
                <span className="o">{d.plateOrigin}</span>
              </span>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
