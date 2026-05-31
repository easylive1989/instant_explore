export default function VideoShowcase() {
  return (
    <section id="intro-video" className="relative scroll-mt-24">
      <div className="mb-10 text-center">
        <div className="eyebrow mb-4 text-clay">30 秒，看 Lorescape 怎麼說故事</div>
        <h2 className="font-serif text-3xl font-bold leading-tight tracking-wide text-ink md:text-5xl">
          翻開風景的<span className="text-clay">第一頁</span>
        </h2>
      </div>

      <div className="relative mx-auto max-w-5xl">
        <div className="overflow-hidden rounded-xl border border-line bg-paper-sunk shadow-e3">
          <video
            className="block aspect-video h-auto w-full bg-paper-sunk"
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
