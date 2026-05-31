import DownloadLink from "./DownloadLink";

const navLinks = [
  { label: "故事", href: "#story" },
  { label: "探索", href: "#explore" },
  { label: "風景", href: "#categories" },
  { label: "旅誌", href: "#journey" },
];

export default function Navbar() {
  return (
    <nav className="fixed top-0 z-50 w-full border-b border-line bg-paper/85 backdrop-blur-xl">
      <div className="mx-auto flex max-w-7xl items-center justify-between px-6 py-4 md:px-8">
        <a
          href="#top"
          className="font-serif text-xl font-bold tracking-wide text-ink"
        >
          Lorescape
        </a>

        <div className="hidden items-center gap-9 md:flex">
          {navLinks.map((link) => (
            <a
              key={link.href}
              href={link.href}
              className="text-[15px] font-medium text-ink-2 transition-colors hover:text-clay"
            >
              {link.label}
            </a>
          ))}
        </div>

        <DownloadLink
          platform="ios"
          location="navbar"
          className="btn-clay rounded-full px-5 py-2 text-sm font-semibold"
        >
          下載 App
        </DownloadLink>
      </div>
    </nav>
  );
}
