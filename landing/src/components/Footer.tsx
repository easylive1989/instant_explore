import DownloadLink from "./DownloadLink";
import { showDownloadLinks, type DownloadPlatform } from "@/lib/downloadLinks";

type FooterLink =
  | { kind: "internal"; label: string; href: string }
  | { kind: "external"; label: string; href: string }
  | { kind: "download"; label: string; platform: DownloadPlatform };

const links: FooterLink[] = [
  { kind: "internal", label: "隱私權政策", href: "/privacy" },
  { kind: "internal", label: "使用條款", href: "/terms" },
  { kind: "internal", label: "支援", href: "/support" },
  { kind: "external", label: "Instagram", href: "#" },
  { kind: "download", label: "App Store", platform: "ios" },
  { kind: "download", label: "Play Store", platform: "android" },
];

export default function Footer() {
  return (
    <footer className="w-full border-t border-line bg-paper-sunk py-12">
      <div className="mx-auto flex max-w-7xl flex-col items-center justify-between gap-6 px-8 md:flex-row">
        <div className="font-serif text-lg font-bold tracking-wide text-ink">
          Lorescape
        </div>
        <div className="flex flex-wrap justify-center gap-7 text-xs text-ink-3">
          {links
            .filter((link) => showDownloadLinks || link.kind !== "download")
            .map((link) => {
            const className = "transition-colors hover:text-clay";
            if (link.kind === "download") {
              return (
                <DownloadLink
                  key={link.label}
                  platform={link.platform}
                  location="footer"
                  className={className}
                >
                  {link.label}
                </DownloadLink>
              );
            }
            return (
              <a
                key={link.label}
                className={className}
                href={link.href}
                target={link.kind === "external" ? "_blank" : undefined}
                rel={link.kind === "external" ? "noopener noreferrer" : undefined}
              >
                {link.label}
              </a>
            );
          })}
        </div>
        <div className="text-xs text-ink-3">
          &copy; {new Date().getFullYear()} Lorescape
        </div>
      </div>
    </footer>
  );
}
