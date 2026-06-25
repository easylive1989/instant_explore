"use client";

import { useEffect, useState } from "react";
import DownloadLink from "./DownloadLink";
import { showDownloadLinks } from "@/lib/downloadLinks";
import BrandSeal from "./BrandSeal";
import LocaleSwitch from "./LocaleSwitch";
import type { Dict } from "@/i18n/dictionaries";

/// Sticky top navigation that gains a translucent backdrop once the page is
/// scrolled past the hero, matching the approved design.
export default function Navbar({
  d,
  homeHref,
}: {
  d: Dict;
  homeHref: string;
}) {
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 24);
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  return (
    <header className={`nav${scrolled ? " scrolled" : ""}`}>
      <a className="brand" href="#top">
        <span className="seal">
          <BrandSeal />
        </span>
        Lorescape
      </a>
      <nav className="nav__links">
        {d.nav.links.map((link) => (
          <a key={link.anchor} href={`${homeHref}${link.anchor}`}>
            {link.label}
          </a>
        ))}
      </nav>
      <span className="nav__spacer" />
      <LocaleSwitch label={d.nav.switchTo} />
      {showDownloadLinks && (
        <DownloadLink
          platform="ios"
          location="navbar"
          className="btn btn--primary"
        >
          <svg
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="1.8"
            strokeLinecap="round"
            strokeLinejoin="round"
          >
            <path d="M12 5v12" />
            <path d="M7 12l5 5 5-5" />
            <path d="M5 20h14" />
          </svg>
          {d.nav.downloadApp}
        </DownloadLink>
      )}
    </header>
  );
}
