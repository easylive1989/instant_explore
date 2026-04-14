export default function FinalCTA() {
  return (
    <section className="relative py-32 rounded-[3rem] overflow-hidden text-center">
      {/* Background */}
      <div className="absolute inset-0 z-0">
        <img
          className="w-full h-full object-cover"
          src="/images/cta-bokeh.jpg"
          alt="Blurred glowing city lights creating a dreamy bokeh with deep blue and gold tones"
        />
        <div className="absolute inset-0 bg-surface/80 backdrop-blur-md" />
      </div>

      {/* Content */}
      <div className="relative z-10 max-w-2xl mx-auto px-8">
        <h2 className="text-5xl font-black mb-8 tracking-tighter leading-[0.9]">
          The city is a book. <br />
          Start reading.
        </h2>
        <p className="text-on-surface-variant mb-12 font-medium">
          Join 50,000+ explorers uncovering the hidden narratives of our world.
        </p>
        <div className="flex flex-wrap justify-center gap-4">
          <a
            href="https://apps.apple.com/tw/app/%E8%AE%80%E6%99%AF/id6751904060"
            target="_blank"
            rel="noopener noreferrer"
            className="bg-primary text-white px-8 py-4 rounded-full font-black flex items-center gap-3 transition-all hover:bg-primary-fixed-dim hover:scale-105 active:scale-95 shadow-2xl shadow-primary/40"
          >
            <span
              className="material-symbols-outlined"
              style={{ fontVariationSettings: "'FILL' 1" }}
            >
              ios
            </span>
            App Store
          </a>
          <a
            href="https://play.google.com/store/apps/details?id=com.paulchwu.instantexplore&hl=zh_TW"
            target="_blank"
            rel="noopener noreferrer"
            className="glass-card text-white px-8 py-4 rounded-full font-black flex items-center gap-3 transition-all hover:bg-white/20 hover:scale-105 active:scale-95"
          >
            <span
              className="material-symbols-outlined"
              style={{ fontVariationSettings: "'FILL' 1" }}
            >
              android
            </span>
            Play Store
          </a>
        </div>
      </div>
    </section>
  );
}
