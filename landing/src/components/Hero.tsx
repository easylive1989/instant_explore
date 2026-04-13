export default function Hero() {
  return (
    <header className="relative min-h-screen flex items-center justify-center pt-20 overflow-hidden">
      {/* Background Image */}
      <div className="absolute inset-0 z-0">
        <img
          className="w-full h-full object-cover opacity-40 grayscale-[20%] mix-blend-overlay"
          src="/images/hero-bg.jpg"
          alt="Cinematic night shot of a historic shrine with glowing lanterns and electric blue highlights"
        />
        <div className="absolute inset-0 bg-gradient-to-t from-surface via-surface/40 to-transparent" />
      </div>

      {/* Content */}
      <div className="relative z-10 max-w-5xl mx-auto px-8 text-center">
        <div className="inline-block mb-6 px-4 py-1.5 glass-card rounded-full text-[10px] uppercase tracking-[0.2em] font-bold text-primary">
          The Future of Exploration
        </div>
        <h1 className="text-5xl md:text-8xl font-black tracking-tighter mb-8 leading-[0.9]">
          Experience History, <br />
          <span className="text-primary text-neon">Not Just Sights.</span>
        </h1>
        <p className="text-lg md:text-xl text-on-surface-variant max-w-2xl mx-auto mb-12 font-medium">
          Your personal AI historian for immersive, eyes-up exploration. Hear
          the stories behind the stones.
        </p>
        <div className="flex flex-wrap justify-center gap-4">
          <button className="bg-primary text-white px-8 py-4 rounded-full font-black flex items-center gap-3 transition-all hover:bg-primary-fixed-dim hover:scale-105 active:scale-95">
            <span
              className="material-symbols-outlined"
              style={{ fontVariationSettings: "'FILL' 1" }}
            >
              ios
            </span>
            App Store
          </button>
          <button className="glass-card text-white px-8 py-4 rounded-full font-black flex items-center gap-3 transition-all hover:bg-white/20 hover:scale-105 active:scale-95">
            <span
              className="material-symbols-outlined"
              style={{ fontVariationSettings: "'FILL' 1" }}
            >
              play_store_installed
            </span>
            Play Store
          </button>
        </div>
      </div>

      {/* Decorative bounce arrow */}
      <div className="absolute bottom-10 left-1/2 -translate-x-1/2 animate-bounce opacity-40">
        <span className="material-symbols-outlined text-4xl">
          keyboard_double_arrow_down
        </span>
      </div>
    </header>
  );
}
