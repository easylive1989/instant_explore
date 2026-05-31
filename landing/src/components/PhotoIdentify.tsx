const categories = [
  {
    name: "自然景觀",
    latin: "NATURE & WILD",
    image: "/images/park.jpg",
    mark: "landscape",
  },
  {
    name: "人文古蹟",
    latin: "HERITAGE",
    image: "/images/agra.jpg",
    mark: "account_balance",
  },
  {
    name: "信仰聖地",
    latin: "SACRED PLACES",
    image: "/images/temple.jpg",
    mark: "menu_book",
  },
  {
    name: "城市地標",
    latin: "LANDMARKS",
    image: "/images/stpeters.jpg",
    mark: "apartment",
  },
];

export default function PhotoIdentify() {
  return (
    <section id="categories" className="scroll-mt-24">
      <div className="mb-12 max-w-2xl">
        <div className="eyebrow mb-4 text-clay">探索版圖</div>
        <h2 className="font-serif text-3xl font-bold leading-tight tracking-wide text-ink md:text-5xl">
          四種風景，等你細讀
        </h2>
        <p className="mt-4 max-w-md leading-relaxed text-ink-2">
          從山林到信仰聖地，Lorescape 為每一種風景，
          備好屬於它的故事。
        </p>
      </div>

      <div className="grid grid-cols-2 gap-4 md:gap-6 lg:grid-cols-4">
        {categories.map((cat) => (
          <div
            key={cat.name}
            className="group relative aspect-[1/1.2] overflow-hidden rounded-lg border border-line shadow-e1"
          >
            <img
              src={cat.image}
              alt={cat.name}
              className="absolute inset-0 h-full w-full object-cover brightness-[0.88] transition-transform duration-500 group-hover:scale-105"
            />
            <div className="absolute inset-0 bg-gradient-to-t from-[#0f0b07]/75 via-transparent to-transparent" />
            <div className="absolute left-3 top-3 flex h-8 w-8 items-center justify-center rounded-full border border-white/25 bg-[#140c08]/40 text-white backdrop-blur-sm">
              <span className="material-symbols-outlined text-[17px]">
                {cat.mark}
              </span>
            </div>
            <div className="absolute inset-x-4 bottom-4">
              <div className="font-serif text-lg font-bold leading-tight text-white drop-shadow-[0_1px_10px_rgba(0,0,0,0.4)]">
                {cat.name}
              </div>
              <div className="mt-1 text-[10px] font-semibold tracking-[0.12em] text-white/80">
                {cat.latin}
              </div>
            </div>
          </div>
        ))}
      </div>
    </section>
  );
}
