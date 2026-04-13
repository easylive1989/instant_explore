const stats = [
  {
    value: "120+",
    label: "Historical Logs",
    description:
      "Automatically curate a diary of every site you've visited across the globe.",
  },
  {
    value: "500+",
    label: "Stories Unlocked",
    description:
      "Review deep-dive scripts and rare historical photos even after you return home.",
  },
  {
    value: "84",
    label: "Cultural Badges",
    description:
      "Gamify your exploration. Earn recognition for mastering specific dynasties or regions.",
  },
];

export default function KnowledgePassport() {
  return (
    <section id="passport" className="text-center">
      <h2 className="text-4xl font-black mb-16 tracking-tighter">
        Your Knowledge Passport
      </h2>
      <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
        {stats.map((stat) => (
          <div
            key={stat.label}
            className="glass-card p-12 rounded-xl text-center group hover:bg-primary/5 transition-colors"
          >
            <div className="text-5xl font-black text-primary mb-4">
              {stat.value}
            </div>
            <div className="text-xs uppercase tracking-[0.3em] font-bold text-on-surface-variant mb-6">
              {stat.label}
            </div>
            <p className="text-sm opacity-60">{stat.description}</p>
          </div>
        ))}
      </div>
    </section>
  );
}
