"use client";

import { sendGAEvent } from "@next/third-parties/google";
import type { ReactNode } from "react";
import {
  storeUrlFor,
  type DownloadLocation,
  type DownloadPlatform,
} from "@/lib/downloadLinks";

interface DownloadLinkProps {
  /// Which app store this link opens. Determines the URL and is reported as
  /// the `platform` parameter on the `download_click` GA event.
  platform: DownloadPlatform;

  /// Which landing-page section the link sits in. Reported as the
  /// `location` parameter so we can compare conversion rates across CTAs.
  location: DownloadLocation;

  /// CSS classes for the underlying anchor, so callers keep full styling
  /// control without having to pass through every Tailwind utility.
  className?: string;

  children: ReactNode;
}

/// Anchor wrapper that opens an app store URL in a new tab and reports a
/// `download_click` event to Google Analytics with `platform` and
/// `location` parameters before the navigation.
export default function DownloadLink({
  platform,
  location,
  className,
  children,
}: DownloadLinkProps) {
  const handleClick = () => {
    sendGAEvent("event", "download_click", {
      platform,
      location,
    });
  };

  return (
    <a
      href={storeUrlFor(platform)}
      target="_blank"
      rel="noopener noreferrer"
      className={className}
      onClick={handleClick}
    >
      {children}
    </a>
  );
}
