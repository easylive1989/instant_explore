const entries = [
  {
    no: "I",
    icon: "menu_book",
    title: "走過即成冊",
    description: "每到一個地方，都自動收進你的旅程，串成一條屬於你的時間軸。",
  },
  {
    no: "II",
    icon: "auto_stories",
    title: "故事留得住",
    description: "回家後仍能重讀那些深度長文與在地傳說，旅行的餘韻不會散去。",
  },
  {
    no: "III",
    icon: "explore",
    title: "足跡會生長",
    description: "從山林到聖地，你讀過的每一種風景，慢慢拼成自己的探索版圖。",
  },
];

export default function KnowledgeJourney() {
  return (
    <section id="journey" className="scroll-mt-24 text-center">
      <div className="eyebrow mb-4 text-clay">收藏你的旅行歷程</div>
      <h2 className="mx-auto mb-14 max-w-2xl font-serif text-3xl font-bold leading-tight tracking-wide text-ink md:text-5xl">
        每段旅程，都值得被寫下
      </h2>

      <div className="grid grid-cols-1 gap-6 md:grid-cols-3">
        {entries.map((entry) => (
          <div key={entry.no} className="paper-card p-10 text-left">
            <div className="mb-6 flex items-center justify-between">
              <div className="flex h-12 w-12 items-center justify-center rounded-md bg-clay-tint text-clay-deep">
                <span className="material-symbols-outlined text-3xl">
                  {entry.icon}
                </span>
              </div>
              <span className="font-serif text-3xl font-bold text-line-strong">
                {entry.no}
              </span>
            </div>
            <h3 className="font-serif text-xl font-bold text-ink">
              {entry.title}
            </h3>
            <p className="mt-3 text-sm leading-relaxed text-ink-2">
              {entry.description}
            </p>
          </div>
        ))}
      </div>
    </section>
  );
}
