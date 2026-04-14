const links = [
  { label: "Privacy Policy", href: "#" },
  { label: "Terms of Service", href: "#" },
  { label: "Support", href: "#" },
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
        <div className="text-lg font-black text-white">Conexture</div>
        <div className="flex flex-wrap justify-center gap-8 text-[10px] uppercase tracking-widest text-white/40">
          {links.map((link) => (
            <a
              key={link.label}
              className="hover:text-blue-400 transition-colors"
              href={link.href}
              target={link.href !== "#" ? "_blank" : undefined}
              rel={link.href !== "#" ? "noopener noreferrer" : undefined}
            >
              {link.label}
            </a>
          ))}
        </div>
        <div className="text-[10px] uppercase tracking-widest text-white/40">
          &copy; {new Date().getFullYear()} Conexture. All rights reserved.
        </div>
      </div>
    </footer>
  );
}
