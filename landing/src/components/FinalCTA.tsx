import type { Dict } from "@/i18n/dictionaries";
import StoreButtons from "./StoreButtons";
import { showDownloadLinks } from "@/lib/downloadLinks";

/// Closing call-to-action over a full-bleed photo, with the store buttons.
export default function FinalCTA({ d }: { d: Dict["finalCTA"] }) {
  return (
    <section className="final" id="download">
      <div className="final__bg">
        <img src="/images/agra.jpg" alt={d.imageAlt} />
      </div>
      <div className="wrap">
        <div className="final__in">
          <span className="over" style={{ color: "#E9B79B" }}>
            {d.over}
          </span>
          <h2>
            {d.h2Top}
            <br />
            {d.h2Bottom}
          </h2>
          <p>{d.body}</p>
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
