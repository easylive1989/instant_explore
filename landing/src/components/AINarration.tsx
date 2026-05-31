const depths = [
  {
    icon: "bolt",
    title: "簡讀",
    body: "趕路也不錯過。用 60 秒，聽完眼前地標最該知道的來歷與亮點。",
  },
  {
    icon: "auto_stories",
    title: "深讀",
    body: "為真正的旅人而寫。一篇值得細讀的長文，娓娓道來建築祕密、政治糾葛與失落的傳說。",
  },
];

export default function AINarration() {
  return (
    <section id="story" className="relative scroll-mt-24">
      <div className="flex flex-col items-center gap-16 md:flex-row">
        {/* Text content */}
        <div className="order-2 md:order-1 md:w-1/2">
          <div className="eyebrow mb-5 text-clay">AI 生成的在地故事</div>
          <h2 className="font-serif text-3xl font-bold leading-tight tracking-wide text-ink md:text-4xl">
            口袋裡的旅行說書人
          </h2>
          <p className="mt-5 max-w-md leading-relaxed text-ink-2">
            為眼前的地標、古蹟與山林，即時編寫值得細讀的故事，
            還能化作語音，邊走邊聽。深淺由你決定。
          </p>

          <div className="mt-10 space-y-7">
            {depths.map((d) => (
              <div key={d.title} className="flex gap-5">
                <div className="flex h-12 w-12 flex-none items-center justify-center rounded-md bg-clay-tint text-clay-deep">
                  <span className="material-symbols-outlined text-[26px]">
                    {d.icon}
                  </span>
                </div>
                <div>
                  <h3 className="font-serif text-xl font-bold text-ink">
                    {d.title}
                  </h3>
                  <p className="mt-1.5 text-sm leading-relaxed text-ink-2">
                    {d.body}
                  </p>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Phone reader mockup */}
        <div className="order-1 flex w-full justify-center md:order-2 md:w-1/2">
          <div className="relative aspect-[9/19] w-full max-w-[300px] overflow-hidden rounded-[2.5rem] border-[10px] border-ink-bg bg-paper shadow-e3">
            {/* reader hero */}
            <div className="relative h-44 overflow-hidden">
              <img
                src="/images/discovery-gate.jpg"
                alt=""
                className="h-full w-full object-cover"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-[#0f0b07]/85 to-transparent" />
              <div className="absolute inset-x-0 bottom-0 p-5">
                <div className="eyebrow text-[10px] text-white/75">
                  Anno · I
                </div>
                <h4 className="mt-1 font-serif text-xl font-bold leading-snug text-white">
                  摧毀與重生的百年豪賭
                </h4>
              </div>
            </div>

            {/* reader body */}
            <div className="px-5 pt-4">
              <p className="font-serif text-[13px] leading-[1.85] text-ink">
                <span className="float-left pr-2 pt-1 font-serif text-4xl font-bold leading-none text-clay-deep">
                  一
                </span>
                五〇六年的春風吹拂梵蒂岡山丘，教宗站在那座千年古堂前，
                做出一個驚世駭俗的決定——
              </p>
            </div>

            {/* audio bar */}
            <div className="absolute inset-x-4 bottom-4 flex items-center gap-3 rounded-full bg-ink-bg-2 px-3 py-2.5 text-on-dark shadow-e2">
              <div className="flex h-9 w-9 flex-none items-center justify-center rounded-full bg-clay text-white">
                <span
                  className="material-symbols-outlined text-xl"
                  style={{ fontVariationSettings: "'FILL' 1" }}
                >
                  play_arrow
                </span>
              </div>
              <div className="min-w-0 flex-1">
                <div className="truncate text-xs font-semibold">
                  聖伯多祿大殿
                </div>
                <div className="mt-1 h-1 w-full overflow-hidden rounded-full bg-white/15">
                  <div className="h-full w-1/3 rounded-full bg-clay" />
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
