import DownloadLink from "./DownloadLink";
import { showDownloadLinks, type DownloadLocation } from "@/lib/downloadLinks";

interface StoreButtonsProps {
  /// Landing-page section the buttons sit in, forwarded to the GA event.
  location: DownloadLocation;

  /// Visual variant. "light" sits on paper (hero); "dark" sits on a dark
  /// photo (final CTA).
  variant: "light" | "dark";
}

function AppleIcon() {
  return (
    <svg viewBox="0 0 24 24" fill="currentColor">
      <path d="M16.4 12.9c0-2.3 1.9-3.4 2-3.5-1.1-1.6-2.8-1.8-3.4-1.8-1.4-.1-2.8.9-3.5.9s-1.8-.8-3-.8c-1.5 0-3 .9-3.8 2.3-1.6 2.8-.4 7 1.2 9.3.8 1.1 1.7 2.4 2.9 2.3 1.2 0 1.6-.7 3-.7s1.8.7 3 .7 2-1.1 2.8-2.2c.9-1.3 1.2-2.5 1.3-2.6-.1 0-2.5-1-2.5-3.8zM14.2 6.2c.6-.8 1.1-1.9.9-3-.9 0-2.1.6-2.8 1.4-.6.7-1.1 1.8-1 2.9 1 .1 2.1-.5 2.9-1.3z" />
    </svg>
  );
}

function GooglePlayIcon() {
  return (
    <svg viewBox="0 0 24 24" fill="currentColor">
      <path d="M3.6 2.4c-.3.3-.5.8-.5 1.4v16.4c0 .6.2 1.1.5 1.4l.1.1 9.2-9.2v-.2L3.6 2.4z" />
      <path
        d="M16 15.3l-3.1-3.1v-.2L16 8.9l.1.1 3.7 2.1c1 .6 1 1.6 0 2.2L16 15.3z"
        opacity=".75"
      />
      <path
        d="M16.1 15.2L12.9 12l-9.3 9.3c.4.4 1 .4 1.7 0l10.8-6.1"
        opacity=".55"
      />
      <path
        d="M16.1 8.8L5.3 2.7c-.7-.4-1.3-.4-1.7 0L12.9 12l3.2-3.2z"
        opacity=".9"
      />
    </svg>
  );
}

/// The paired App Store / Google Play store-style download buttons used in the
/// hero and final CTA. Hidden entirely while `showDownloadLinks` is false.
export default function StoreButtons({ location, variant }: StoreButtonsProps) {
  if (!showDownloadLinks) return null;

  const iosClass =
    variant === "dark"
      ? "btn btn--dark btn--store"
      : "btn btn--primary btn--store";
  const androidClass =
    variant === "dark"
      ? "btn btn--outline-dark btn--store"
      : "btn btn--ghost btn--store";

  return (
    <>
      <DownloadLink platform="ios" location={location} className={iosClass}>
        <AppleIcon />
        <span>
          <span className="sm">Download on the</span>
          <span className="lg">App Store</span>
        </span>
      </DownloadLink>
      <DownloadLink
        platform="android"
        location={location}
        className={androidClass}
      >
        <GooglePlayIcon />
        <span>
          <span className="sm">GET IT ON</span>
          <span className="lg">Google Play</span>
        </span>
      </DownloadLink>
    </>
  );
}
