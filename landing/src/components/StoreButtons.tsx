import DownloadLink from "./DownloadLink";
import { showDownloadLinks, type DownloadLocation } from "@/lib/downloadLinks";

interface StoreButtonsProps {
  /// Landing-page section the buttons sit in, forwarded to the GA event.
  location: DownloadLocation;

  /// Visual variant. "light" sits on paper (hero); "dark" sits on a dark
  /// photo (final CTA).
  variant: "light" | "dark";

  /// Localized small sub-labels above each store name.
  labels: { ios: string; android: string };
}

function AppleIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="currentColor" className={className}>
      <path d="M16.4 12.9c0-2.3 1.9-3.4 2-3.5-1.1-1.6-2.8-1.8-3.4-1.8-1.4-.1-2.8.9-3.5.9s-1.8-.8-3-.8c-1.5 0-3 .9-3.8 2.3-1.6 2.8-.4 7 1.2 9.3.8 1.1 1.7 2.4 2.9 2.3 1.2 0 1.6-.7 3-.7s1.8.7 3 .7 2-1.1 2.8-2.2c.9-1.3 1.2-2.5 1.3-2.6-.1 0-2.5-1-2.5-3.8zM14.2 6.2c.6-.8 1.1-1.9.9-3-.9 0-2.1.6-2.8 1.4-.6.7-1.1 1.8-1 2.9 1 .1 2.1-.5 2.9-1.3z" />
    </svg>
  );
}

function GooglePlayIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 16 16" fill="currentColor" className={className}>
      <path d="M14.222 9.374c1.037-.61 1.037-2.137 0-2.748L11.528 5.04 8.32 8l3.207 2.96 2.694-1.586Zm-3.595 2.116L7.583 8.68 1.03 14.73c.201 1.029 1.36 1.61 2.303 1.055l7.294-4.295ZM1 13.396V2.603L6.846 8 1 13.396ZM1.03 1.27l6.553 6.05 3.044-2.81L3.333.215C2.39-.341 1.231.24 1.03 1.27Z" />
    </svg>
  );
}

/// The paired App Store / Google Play store-style download buttons used in the
/// hero and final CTA. Hidden entirely while `showDownloadLinks` is false.
export default function StoreButtons({ location, labels }: StoreButtonsProps) {
  if (!showDownloadLinks) return null;

  const iosClass = "btn btn--store-custom btn--store";
  const androidClass = "btn btn--store-custom btn--store";

  return (
    <>
      <DownloadLink platform="ios" location={location} className={iosClass}>
        <AppleIcon className="icon-apple" />
        <span>
          <span className="sm">{labels.ios}</span>
          <span className="lg">App Store</span>
        </span>
      </DownloadLink>
      <DownloadLink
        platform="android"
        location={location}
        className={androidClass}
      >
        <GooglePlayIcon className="icon-googleplay" />
        <span>
          <span className="sm">{labels.android}</span>
          <span className="lg">Google Play</span>
        </span>
      </DownloadLink>
    </>
  );
}
