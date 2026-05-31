import DownloadLink from "./DownloadLink";

export default function FinalCTA() {
  return (
    <section className="relative overflow-hidden rounded-xl text-center shadow-e3">
      {/* Background */}
      <div className="absolute inset-0 z-0">
        <img
          className="h-full w-full object-cover"
          src="/images/cta-bokeh.jpg"
          alt=""
        />
        <div className="absolute inset-0 bg-gradient-to-br from-ink-bg-2/95 to-ink-bg/95" />
      </div>

      {/* Content */}
      <div className="relative z-10 mx-auto max-w-2xl px-8 py-28">
        <div className="mb-6 flex justify-center text-clay">
          <span className="material-symbols-outlined text-5xl">
            menu_book
          </span>
        </div>
        <h2 className="font-serif text-3xl font-bold leading-tight tracking-wide text-on-dark md:text-5xl">
          城市是一本書，
          <br />
          翻開它的下一頁
        </h2>
        <p className="mx-auto mt-6 max-w-md leading-relaxed text-on-dark-2">
          帶上你的隨行說書人，讓每一處風景，都為你開口說它的故事。
        </p>
        <div className="mt-10 flex flex-wrap justify-center gap-4">
          <DownloadLink
            platform="ios"
            location="final_cta"
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
            location="final_cta"
            className="flex items-center gap-2.5 rounded-full border border-white/20 bg-white/10 px-7 py-3.5 text-base font-semibold text-on-dark backdrop-blur-md transition-all hover:bg-white/20 active:scale-95"
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
      </div>
    </section>
  );
}
