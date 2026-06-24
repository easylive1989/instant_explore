import DownloadLink from "./DownloadLink";
import { showDownloadLinks } from "@/lib/downloadLinks";
import BrandSeal from "./BrandSeal";

/// Site footer: brand blurb plus product / company / legal link columns.
export default function Footer() {
  return (
    <footer className="foot">
      <div className="wrap">
        <div className="foot__top">
          <div>
            <div className="foot__brand">
              <span className="seal">
                <BrandSeal />
              </span>
              Lorescape
            </div>
            <p className="foot__tag">
              溫潤紙感 × 文學宋體 × 陶土點綴——為旅途中的每一段故事而設計。
            </p>
          </div>
          <div className="foot__cols">
            <div className="foot__col">
              <h4>產品</h4>
              <a href="#stories">在地故事</a>
              <a href="#angles">多種角度</a>
              <a href="#explore">探索附近</a>
              <a href="#journey">旅程手記</a>
              {showDownloadLinks && (
                <DownloadLink platform="ios" location="footer">
                  下載 App
                </DownloadLink>
              )}
            </div>
            <div className="foot__col">
              <h4>公司</h4>
              <a href="/support">聯絡我們</a>
            </div>
            <div className="foot__col">
              <h4>法律</h4>
              <a href="/privacy">隱私政策</a>
              <a href="/terms">使用條款</a>
              <a href="/credits">圖片來源</a>
            </div>
          </div>
        </div>
        <div className="foot__bar">
          <span>© 2026 Lorescape. 版權所有。</span>
          <span>地誌手記 · v1.0</span>
        </div>
      </div>
    </footer>
  );
}
