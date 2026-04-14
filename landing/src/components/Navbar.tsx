export default function Navbar() {
  return (
    <nav className="bg-slate-950/80 backdrop-blur-xl fixed top-0 w-full z-50 shadow-lg shadow-black/20">
      <div className="flex justify-between items-center px-8 py-4 max-w-7xl mx-auto">
        <div className="text-xl font-black text-white tracking-tighter">
          Conexture
        </div>
        <div className="hidden md:flex gap-10 items-center">
          <a
            className="text-blue-500 font-bold border-b-2 border-blue-500 pb-1 tracking-tight text-lg hover:text-white transition-colors duration-300 active:scale-95"
            href="#discovery"
          >
            Discovery
          </a>
          <a
            className="text-white/60 font-medium tracking-tight text-lg hover:text-white transition-colors duration-300 active:scale-95"
            href="#narration"
          >
            AI Narration
          </a>
          <a
            className="text-white/60 font-medium tracking-tight text-lg hover:text-white transition-colors duration-300 active:scale-95"
            href="#passport"
          >
            Passport
          </a>
        </div>
        <a
          href="https://apps.apple.com/tw/app/%E8%AE%80%E6%99%AF/id6751904060"
          target="_blank"
          rel="noopener noreferrer"
          className="bg-primary hover:bg-primary/90 text-white px-6 py-2 rounded-full font-bold transition-all active:scale-95 shadow-lg shadow-primary/20"
        >
          Download
        </a>
      </div>
    </nav>
  );
}
