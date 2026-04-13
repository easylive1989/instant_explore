export default function EyesUpDiscovery() {
  return (
    <section
      id="discovery"
      className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-stretch"
    >
      {/* Large image card */}
      <div className="lg:col-span-7 glass-card rounded-xl overflow-hidden relative group min-h-[400px]">
        <img
          className="absolute inset-0 w-full h-full object-cover opacity-50 group-hover:scale-110 transition-transform duration-700"
          src="/images/discovery-gate.jpg"
          alt="Ancient weathered wooden gate with soft bokeh of temple gardens behind"
        />
        <div className="absolute inset-0 bg-gradient-to-r from-surface-container via-surface-container/60 to-transparent p-12 flex flex-col justify-end">
          <div className="mb-4 text-primary font-black tracking-widest text-xs uppercase">
            Feature 01
          </div>
          <h2 className="text-4xl font-black mb-4 tracking-tighter leading-none">
            Eyes-Up Discovery
          </h2>
          <p className="text-on-surface-variant max-w-md">
            Our &apos;Free Roam&apos; mode uses spatial audio to narrate
            history as you walk. Put your phone away and let the city speak to
            you.
          </p>
        </div>
      </div>

      {/* Two stacked feature cards */}
      <div className="lg:col-span-5 flex flex-col gap-8">
        <div className="glass-card p-10 rounded-xl flex-1 flex flex-col justify-center">
          <div className="w-12 h-12 rounded-lg bg-primary/20 flex items-center justify-center mb-6">
            <span className="material-symbols-outlined text-primary text-3xl">
              spatial_audio_off
            </span>
          </div>
          <h3 className="text-2xl font-bold mb-3 tracking-tight">
            Immersive Spatial Flow
          </h3>
          <p className="text-on-surface-variant text-sm leading-relaxed">
            Audio cues adapt to your walking speed and orientation, creating a
            seamless narrative that feels part of the environment.
          </p>
        </div>
        <div className="glass-card p-10 rounded-xl flex-1 flex flex-col justify-center border-primary/20">
          <div className="w-12 h-12 rounded-lg bg-primary flex items-center justify-center mb-6 shadow-lg shadow-primary/20">
            <span className="material-symbols-outlined text-white text-3xl">
              visibility_off
            </span>
          </div>
          <h3 className="text-2xl font-bold mb-3 tracking-tight">
            Zero-Screen Interaction
          </h3>
          <p className="text-on-surface-variant text-sm leading-relaxed">
            Stop looking at maps. Our AI directs you using historical landmarks
            as waypoints.
          </p>
        </div>
      </div>
    </section>
  );
}
