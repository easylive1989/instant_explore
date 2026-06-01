/// App store download URLs and shared types for the landing page CTAs.
///
/// Centralising the URLs here avoids the same string drifting between Hero,
/// FinalCTA, Navbar and Footer when we update the listing locale or app id.

/// Master switch for the app download CTAs across the landing page.
///
/// Temporarily set to `false` to hide every "下載 App" / store button while
/// the apps are not yet publicly available. Flip back to `true` to restore
/// all download links at once.
export const showDownloadLinks = false;

export type DownloadPlatform = "ios" | "android";

/// Where on the landing page a download CTA is rendered. Used as the
/// `location` parameter of the GA `download_click` event so we can attribute
/// downloads to the specific section that converted.
export type DownloadLocation =
  | "navbar"
  | "hero"
  | "final_cta"
  | "footer";

export const APP_STORE_URL =
  "https://apps.apple.com/tw/app/%E8%AE%80%E6%99%AF/id6751904060";

export const PLAY_STORE_URL =
  "https://play.google.com/store/apps/details?id=com.paulchwu.instantexplore&hl=zh_TW";

export function storeUrlFor(platform: DownloadPlatform): string {
  return platform === "ios" ? APP_STORE_URL : PLAY_STORE_URL;
}
