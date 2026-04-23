export default function VideoShowcase() {
  return (
    <section id="intro-video" className="relative">
      <div className="text-center mb-10">
        <div className="inline-block mb-4 px-4 py-1.5 glass-card rounded-full text-[10px] uppercase tracking-[0.2em] font-bold text-primary">
          Watch the 30-second intro
        </div>
        <h2 className="text-4xl md:text-6xl font-black tracking-tighter leading-[0.95]">
          See Lorescape <br />
          <span className="text-primary text-neon">in motion.</span>
        </h2>
      </div>

      <div className="relative mx-auto max-w-5xl">
        {/* Soft glow behind the video */}
        <div
          aria-hidden
          className="absolute -inset-6 rounded-[28px] bg-primary/25 blur-3xl opacity-60"
        />
        <div className="relative rounded-2xl overflow-hidden glass-card shadow-2xl shadow-primary/10">
          <video
            className="block w-full h-auto aspect-video bg-surface"
            src="/videos/lorescape-intro.mp4"
            poster="/videos/lorescape-intro-poster.jpg"
            autoPlay
            muted
            loop
            playsInline
            preload="metadata"
          />
        </div>
      </div>
    </section>
  );
}
