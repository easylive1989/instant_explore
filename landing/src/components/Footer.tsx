const links = [
  "Privacy Policy",
  "Terms of Service",
  "Support",
  "Instagram",
  "App Store",
  "Play Store",
];

export default function Footer() {
  return (
    <footer className="bg-slate-950 w-full py-12 border-t border-white/10">
      <div className="flex flex-col md:flex-row justify-between items-center px-8 max-w-7xl mx-auto gap-6">
        <div className="text-lg font-black text-white">Conexture</div>
        <div className="flex flex-wrap justify-center gap-8 text-[10px] uppercase tracking-widest text-white/40">
          {links.map((link) => (
            <a
              key={link}
              className="hover:text-blue-400 transition-colors"
              href="#"
            >
              {link}
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
