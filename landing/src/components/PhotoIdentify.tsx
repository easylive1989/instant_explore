export default function PhotoIdentify() {
  const features = [
    "Artifact Recognition",
    "Real-time Translation of Scripts",
    "Style & Era Estimation",
  ];

  return (
    <section className="glass-card rounded-[2rem] overflow-hidden">
      <div className="flex flex-col lg:flex-row">
        {/* Image */}
        <div className="lg:w-1/2 h-[400px] lg:h-auto relative">
          <img
            className="absolute inset-0 w-full h-full object-cover"
            src="/images/photo-identify.jpg"
            alt="User holding a smartphone to photograph a red torii gate with a scanning overlay"
          />
          <div className="absolute inset-0 bg-primary/20 mix-blend-overlay" />
        </div>

        {/* Content */}
        <div className="lg:w-1/2 p-12 lg:p-24 flex flex-col justify-center">
          <h2 className="text-4xl font-black mb-6 tracking-tighter leading-none">
            Photo Identify
          </h2>
          <p className="text-lg text-on-surface-variant mb-10 leading-relaxed">
            Encountered something mysterious? Snap a photo. Our advanced
            computer vision identifies the era, architect, and historical
            significance instantly, launching a tailored tour for you.
          </p>
          <ul className="space-y-4">
            {features.map((feature) => (
              <li key={feature} className="flex items-center gap-4">
                <span
                  className="material-symbols-outlined text-primary"
                  style={{ fontVariationSettings: "'FILL' 1" }}
                >
                  check_circle
                </span>
                <span className="text-sm font-bold">{feature}</span>
              </li>
            ))}
          </ul>
        </div>
      </div>
    </section>
  );
}
