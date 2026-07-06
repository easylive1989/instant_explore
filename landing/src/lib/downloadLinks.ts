/// App store download URLs and shared types for the landing page CTAs.
///
/// Centralising the URLs here avoids the same string drifting between Hero,
/// FinalCTA, Navbar and Footer when we update the listing locale or app id.

/// Master switch for the app download CTAs across the landing page.
///
/// `true` shows every "下載 App" / store button (Navbar, Hero, FinalCTA,
/// Footer). Set to `false` to hide them all at once, e.g. while a release
/// is pulled from the stores.
export const showDownloadLinks = true;

export type DownloadPlatform = "ios" | "android";

/// Where on the landing page a download CTA is rendered. Used as the
/// `location` parameter of the GA `download_click` event so we can attribute
/// downloads to the specific section that converted.
export type DownloadLocation =
  | "navbar"
  | "hero"
  | "final_cta"
  | "footer"
  | "story";

export const APP_STORE_URL =
  "https://apps.apple.com/tw/app/%E8%AE%80%E6%99%AF/id6751904060";

export const PLAY_STORE_URL =
  "https://play.google.com/store/apps/details?id=com.paulchwu.instantexplore&hl=zh_TW";

/// Builds the store URL with install-attribution params so the App Store and
/// Play consoles can attribute installs back to the landing page and the CTA
/// that converted. GA's `download_click` only sees the on-site click; these
/// params survive the redirect into the store.
///
/// - Google Play reads the Install Referrer: a `referrer` param holding a
///   URL-encoded UTM string, surfaced in Play Console acquisition reports.
/// - App Store reads a campaign token (`ct`, max 40 chars, alphanumeric),
///   surfaced in App Store Connect App Analytics under Campaigns.
///
/// Passing no `location` returns the bare URL (e.g. for non-CTA references).
export function storeUrlFor(
  platform: DownloadPlatform,
  location?: DownloadLocation,
): string {
  const base = platform === "ios" ? APP_STORE_URL : PLAY_STORE_URL;
  if (!location) return base;

  if (platform === "android") {
    const referrer = new URLSearchParams({
      utm_source: "lorescape.app",
      utm_medium: "web",
      utm_campaign: "landing",
      utm_content: location,
    }).toString();
    return `${base}&referrer=${encodeURIComponent(referrer)}`;
  }

  return `${base}?ct=web_${location}`;
}
