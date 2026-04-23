const links = [
  { label: "Privacy Policy", href: "/privacy" },
  { label: "Terms of Use", href: "/terms" },
  { label: "Support", href: "/support" },
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
    <footer className="bg-slate-950 w-full py-12 border-t border-white/10">
      <div className="flex flex-col md:flex-row justify-between items-center px-8 max-w-7xl mx-auto gap-6">
        <div className="text-lg font-black text-white">Lorescape</div>
        <div className="flex flex-wrap justify-center gap-8 text-[10px] uppercase tracking-widest text-white/40">
          {links.map((link) => {
            const isExternal = link.href.startsWith("http");
            return (
              <a
                key={link.label}
                className="hover:text-blue-400 transition-colors"
                href={link.href}
                target={isExternal ? "_blank" : undefined}
                rel={isExternal ? "noopener noreferrer" : undefined}
              >
                {link.label}
              </a>
            );
          })}
        </div>
        <div className="text-[10px] uppercase tracking-widest text-white/40">
          &copy; {new Date().getFullYear()} Lorescape. All rights reserved.
        </div>
      </div>
    </footer>
  );
}
