import type { Dict } from "@/i18n/dictionaries";

/// Centered editorial manifesto quote that bridges the hero and the feature
/// sections.
export default function Manifesto({ d }: { d: Dict["manifesto"] }) {
  return (
    <section className="manifesto">
      <div className="wrap">
        <div className="rule" />
        <blockquote>
          {d.line1}
          <br />
          {d.line2Lead}<span className="q">{d.line2Quote}</span>
        </blockquote>
        <cite>{d.cite}</cite>
      </div>
    </section>
  );
}
