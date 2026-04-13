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
        <button className="bg-primary hover:bg-primary-fixed-dim text-white text-lg px-12 py-5 rounded-full font-black transition-all shadow-2xl shadow-primary/40 active:scale-95">
          Download for iOS / Android
        </button>
      </div>
    </section>
  );
}
