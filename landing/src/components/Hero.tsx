import DownloadLink from "./DownloadLink";

export default function Hero() {
  return (
    <header
      id="top"
      className="relative flex min-h-screen items-center overflow-hidden"
    >
      {/* Immersive photo */}
      <div className="absolute inset-0 z-0">
        <img
          className="h-full w-full object-cover"
          src="/images/hero-bg.jpg"
          alt="燈火映照的歷史聖殿夜景"
        />
        {/* Warm scrim fading into the paper page below */}
        <div className="absolute inset-0 bg-gradient-to-b from-[#0f0b07]/55 via-[#0f0b07]/25 to-[#0f0b07]/92" />
        <div className="absolute inset-x-0 bottom-0 h-40 bg-gradient-to-b from-transparent to-paper" />
      </div>

      {/* Content */}
      <div className="relative z-10 mx-auto w-full max-w-5xl px-6 pt-24 md:px-8">
        <div className="eyebrow mb-6 flex items-center gap-3 text-white/85">
          <span className="h-px w-7 bg-white/50" />
          LORESCAPE
        </div>
        <h1 className="max-w-3xl font-serif text-4xl font-bold leading-[1.2] tracking-wide text-white drop-shadow-[0_2px_24px_rgba(0,0,0,0.45)] md:text-6xl">
          讓每一處風景，
          <br />
          開口說它的故事
        </h1>
        <p className="mt-7 max-w-xl text-base leading-relaxed text-[#f7f1e6]/85 md:text-lg">
          AI 隨行的旅行說書人。走到哪，就把那裡的來歷、傳說與歷史，
          說給你聽——還能化作語音，邊走邊聽。
        </p>

        <div className="mt-10 flex flex-wrap gap-4">
          <DownloadLink
            platform="ios"
            location="hero"
            className="btn-clay flex items-center gap-2.5 rounded-full px-7 py-3.5 text-base font-semibold"
          >
            <span
              className="material-symbols-outlined"
              style={{ fontVariationSettings: "'FILL' 1" }}
            >
              ios
            </span>
            App Store
          </DownloadLink>
          <DownloadLink
            platform="android"
            location="hero"
            className="flex items-center gap-2.5 rounded-full border border-white/30 bg-white/10 px-7 py-3.5 text-base font-semibold text-white backdrop-blur-md transition-all hover:bg-white/20 active:scale-95"
          >
            <span
              className="material-symbols-outlined"
              style={{ fontVariationSettings: "'FILL' 1" }}
            >
              android
            </span>
            Play Store
          </DownloadLink>
        </div>

        <div className="mt-12 flex items-center gap-2 text-xs tracking-[0.08em] text-[#f7f1e6]/60">
          <span className="material-symbols-outlined text-[15px]">place</span>
          聖伯多祿大殿 · VATICAN
        </div>
      </div>
    </header>
  );
}
