import StoreButtons from "./StoreButtons";
import { showDownloadLinks } from "@/lib/downloadLinks";

/// Closing call-to-action over a full-bleed photo, with the store buttons.
export default function FinalCTA() {
  return (
    <section className="final" id="download">
      <div className="final__bg">
        <img src="/images/agra.jpg" alt="阿格拉紅堡" />
      </div>
      <div className="wrap">
        <div className="final__in">
          <span className="over" style={{ color: "#E9B79B" }}>
            開始你的第一段故事
          </span>
          <h2>
            城市是一本書。
            <br />
            開始閱讀吧。
          </h2>
          <p>加入五萬名探索者，一同揭開世界各地隱藏的篇章。</p>
          {showDownloadLinks && (
            <div className="final__cta">
              <StoreButtons location="final_cta" variant="dark" />
            </div>
          )}
        </div>
      </div>
    </section>
  );
}
