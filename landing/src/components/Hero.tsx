import StoreButtons from "./StoreButtons";
import { showDownloadLinks } from "@/lib/downloadLinks";

/// Centered hero: pill kicker, headline, lede, store CTAs and a wide "plate"
/// showcase image with a now-playing tag and caption.
export default function Hero() {
  return (
    <section className="hero" id="top">
      <div className="wrap">
        <span className="pill">
          <span className="dot" />
          AI 隨行的旅行說書人
        </span>
        <h1>
          體驗歷史，
          <br />
          <span className="clay">而不只是風景。</span>
        </h1>
        <p className="lede">
          你的隨身 AI 旅行說書人。走到哪，就把那裡的來歷、傳說與歷史，說給你聽。
        </p>
        {showDownloadLinks && (
          <div className="hero__cta">
            <StoreButtons location="hero" variant="light" />
          </div>
        )}
        <div className="hero__scroll">
          向下捲動
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
            <img src="/images/stpeters.jpg" alt="聖伯多祿大殿" />
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
              正在導覽
            </span>
            <div className="plate__cap">
              <span className="ln" />
              <span>
                <span className="t">摧毀與重生的百年豪賭</span>
                <span className="o">St. Peter&apos;s Basilica · Vatican</span>
              </span>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
