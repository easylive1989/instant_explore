import DownloadLink from "./DownloadLink";
import { showDownloadLinks } from "@/lib/downloadLinks";
import BrandSeal from "./BrandSeal";
import type { Dict } from "@/i18n/dictionaries";

/// Site footer: brand blurb plus product / company / legal link columns.
export default function Footer({
  d,
  homeHref,
}: {
  d: Dict;
  homeHref: string;
}) {
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
            <p className="foot__tag">{d.footer.tag}</p>
          </div>
          <div className="foot__cols">
            <div className="foot__col">
              <h4>{d.footer.colProduct}</h4>
              {d.nav.links.map((link) => (
                <a key={link.anchor} href={`${homeHref}${link.anchor}`}>
                  {link.label}
                </a>
              ))}
              {showDownloadLinks && (
                <DownloadLink platform="ios" location="footer">
                  {d.nav.downloadApp}
                </DownloadLink>
              )}
            </div>
            <div className="foot__col">
              <h4>{d.footer.colCompany}</h4>
              <a href="/support">{d.footer.contact}</a>
            </div>
            <div className="foot__col">
              <h4>{d.footer.colLegal}</h4>
              <a href="/privacy">{d.footer.privacy}</a>
              <a href="/terms">{d.footer.terms}</a>
              <a href="/credits">{d.footer.credits}</a>
            </div>
          </div>
        </div>
        <div className="foot__bar">
          <span>{d.footer.copyright}</span>
          <span>{d.footer.version}</span>
        </div>
      </div>
    </footer>
  );
}
