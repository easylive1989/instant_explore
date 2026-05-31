const links = [
  { label: "隱私權政策", href: "/privacy" },
  { label: "使用條款", href: "/terms" },
  { label: "支援", href: "/support" },
  { label: "Instagram", href: "#" },
  {
    label: "App Store",
    href: "https://apps.apple.com/tw/app/%E8%AE%80%E6%99%AF/id6751904060",
  },
  {
    label: "Play Store",
    href: "https://play.google.com/store/apps/details?id=com.paulchwu.instantexplore&hl=zh_TW",
  },
];

export default function Footer() {
  return (
    <footer className="w-full border-t border-line bg-paper-sunk py-12">
      <div className="mx-auto flex max-w-7xl flex-col items-center justify-between gap-6 px-8 md:flex-row">
        <div className="font-serif text-lg font-bold tracking-wide text-ink">
          Lorescape
        </div>
        <div className="flex flex-wrap justify-center gap-7 text-xs text-ink-3">
          {links.map((link) => {
            const isExternal = link.href.startsWith("http");
            return (
              <a
                key={link.label}
                className="transition-colors hover:text-clay"
                href={link.href}
                target={isExternal ? "_blank" : undefined}
                rel={isExternal ? "noopener noreferrer" : undefined}
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
