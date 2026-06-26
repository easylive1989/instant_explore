import type { Dict } from "@/i18n/dictionaries";

/// Centered auto-play muted video between the hero and manifesto.
/// Shows the app in action before the user reads any feature copy.
export default function VideoDemo({ d }: { d: Dict["videoDemo"] }) {
  return (
    <section className="vdemo">
      <div className="wrap">
        <div className="vdemo__frame">
          <video
            src="/videos/lorescape-intro.mp4"
            poster="/videos/lorescape-intro-poster.jpg"
            autoPlay
            muted
            loop
            playsInline
            aria-label={d.ariaLabel}
            className="vdemo__video"
          />
        </div>
        <p className="vdemo__cap">{d.caption}</p>
      </div>
    </section>
  );
}
