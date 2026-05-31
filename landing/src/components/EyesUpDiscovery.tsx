export default function EyesUpDiscovery() {
  return (
    <section
      id="explore"
      className="grid scroll-mt-24 grid-cols-1 items-stretch gap-6 lg:grid-cols-12"
    >
      {/* Large image card */}
      <div className="group relative min-h-[400px] overflow-hidden rounded-lg border border-line shadow-e2 lg:col-span-7">
        <img
          className="absolute inset-0 h-full w-full object-cover transition-transform duration-700 group-hover:scale-105"
          src="/images/discovery-gate.jpg"
          alt="古老的木造山門，後方是寺院庭園的柔焦"
        />
        <div className="absolute inset-0 flex flex-col justify-end bg-gradient-to-t from-[#0f0b07]/90 via-[#0f0b07]/30 to-transparent p-10">
          <div className="eyebrow mb-3 text-[11px] text-white/75">
            Feature 01
          </div>
          <h2 className="font-serif text-3xl font-bold leading-tight text-white md:text-4xl">
            探索身邊的風景
          </h2>
          <p className="mt-3 max-w-md text-sm leading-relaxed text-[#f7f1e6]/85">
            依距離與主題，發現方圓之內值得停留的每一個角落。
            把地圖收起來，讓城市自己開口。
          </p>
        </div>
      </div>

      {/* Two stacked feature cards */}
      <div className="flex flex-col gap-6 lg:col-span-5">
        <div className="paper-card flex flex-1 flex-col justify-center p-9">
          <div className="mb-5 flex h-12 w-12 items-center justify-center rounded-md bg-clay-tint text-clay-deep">
            <span className="material-symbols-outlined text-3xl">explore</span>
          </div>
          <h3 className="font-serif text-xl font-bold text-ink">
            就近發現
          </h3>
          <p className="mt-2 text-sm leading-relaxed text-ink-2">
            自動帶出你身邊值得一聽的地點，距離、類型一目了然，隨走隨探。
          </p>
        </div>
        <div className="paper-card flex flex-1 flex-col justify-center p-9">
          <div className="mb-5 flex h-12 w-12 items-center justify-center rounded-md bg-clay text-white shadow-e1">
            <span className="material-symbols-outlined text-3xl">tune</span>
          </div>
          <h3 className="font-serif text-xl font-bold text-ink">
            依你而選
          </h3>
          <p className="mt-2 text-sm leading-relaxed text-ink-2">
            設定想走的距離與想看的主題，只留下真正會讓你停下腳步的風景。
          </p>
        </div>
      </div>
    </section>
  );
}
