export default function AINarration() {
  return (
    <section id="narration" className="relative">
      <div className="flex flex-col md:flex-row items-center gap-16">
        {/* Text content */}
        <div className="md:w-1/2 order-2 md:order-1">
          <div className="inline-block mb-6 px-4 py-1 bg-primary/20 border border-primary/30 rounded-full text-[10px] uppercase tracking-widest font-bold text-primary">
            Dynamic Intelligence
          </div>
          <h2 className="text-5xl font-black mb-8 tracking-tighter leading-none">
            AI Narration: <br />
            Choose Your Depth
          </h2>
          <div className="space-y-8">
            <div className="flex gap-6">
              <div className="flex-shrink-0 mt-1">
                <span className="material-symbols-outlined text-primary text-3xl">
                  shutter_speed
                </span>
              </div>
              <div>
                <h4 className="text-xl font-bold tracking-tight mb-2">
                  Brief Mode
                </h4>
                <p className="text-on-surface-variant text-sm">
                  Perfect for high-level highlights. Get the 60-second essential
                  history of any monument you pass.
                </p>
              </div>
            </div>
            <div className="flex gap-6">
              <div className="flex-shrink-0 mt-1">
                <span className="material-symbols-outlined text-primary text-3xl">
                  auto_stories
                </span>
              </div>
              <div>
                <h4 className="text-xl font-bold tracking-tight mb-2">
                  Deep Dive
                </h4>
                <p className="text-on-surface-variant text-sm">
                  For the true scholar. 15-minute immersive sagas detailing
                  political intrigue, architectural secrets, and lost legends.
                </p>
              </div>
            </div>
          </div>
        </div>

        {/* Phone mockup */}
        <div className="md:w-1/2 order-1 md:order-2 flex justify-center">
          <div className="relative w-full max-w-sm aspect-[9/19] rounded-[3rem] border-[12px] border-surface-container-high bg-surface-container shadow-2xl overflow-hidden">
            <div className="absolute inset-0">
              <img
                className="w-full h-full object-cover"
                src="/images/phone-mockup.jpg"
                alt="Dark minimalist music player interface with a pulsing blue play button"
              />
              <div className="absolute inset-0 bg-black/60 backdrop-blur-sm p-8 flex flex-col justify-between">
                {/* Top bar */}
                <div className="flex justify-between items-center pt-4">
                  <span className="material-symbols-outlined">
                    expand_more
                  </span>
                  <span className="text-[10px] uppercase tracking-widest font-bold">
                    Now Playing
                  </span>
                  <span className="material-symbols-outlined">more_vert</span>
                </div>

                {/* Center content */}
                <div className="text-center">
                  <div className="text-xs text-primary font-bold uppercase tracking-widest mb-2">
                    Yasaka Shrine
                  </div>
                  <h3 className="text-2xl font-black tracking-tight leading-tight">
                    The Fire of Gion
                  </h3>
                  <div className="mt-8 flex justify-center items-center gap-8">
                    <span className="material-symbols-outlined text-3xl">
                      replay_10
                    </span>
                    <div className="w-16 h-16 rounded-full bg-primary flex items-center justify-center">
                      <span
                        className="material-symbols-outlined text-white text-3xl"
                        style={{ fontVariationSettings: "'FILL' 1" }}
                      >
                        play_arrow
                      </span>
                    </div>
                    <span className="material-symbols-outlined text-3xl">
                      forward_30
                    </span>
                  </div>
                </div>

                {/* Progress bar */}
                <div className="pb-4">
                  <div className="h-1 bg-white/10 w-full rounded-full overflow-hidden mb-2">
                    <div className="h-full bg-primary w-1/3" />
                  </div>
                  <div className="flex justify-between text-[10px] font-bold opacity-40">
                    <span>04:12</span>
                    <span>12:45</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
