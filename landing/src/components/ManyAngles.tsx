import type { Dict } from "@/i18n/dictionaries";

/// Feature 02 — the same landmark, many stories. Dark section pairing the list
/// of angles with a phone mockup of the player.
export default function ManyAngles({ d }: { d: Dict["manyAngles"] }) {
  return (
    <section className="section dark" id="angles">
      <div className="wrap">
        <div className="depth-grid">
          <div className="depth-copy">
            <div className="sec-label">
              <span className="bar" />
              <span className="no">{d.no}</span>
            </div>
            <span className="over">{d.over}</span>
            <h2 className="h2" style={{ marginTop: 14 }}>
              {d.h2Top}
              <br />
              {d.h2Bottom}
            </h2>
            <p className="sec-lede">{d.lede}</p>
            <div className="depth-modes" style={{ marginTop: 36 }}>
              {d.modes.map((mode) => (
                <div className="depth-mode" key={mode.num}>
                  <span className="num">{mode.num}</span>
                  <div>
                    <h3>{mode.title}</h3>
                    <p>{mode.body}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>
          <div className="depth-phone">
            <div className="phone">
              <div className="phone__frame">
                <div className="phone__screen">
                  <span className="phone__notch" />
                  <div className="ph-img">
                    <img src="/images/stpeters.jpg" alt={d.phoneImageAlt} />
                  </div>
                  <div className="ph-top">
                    <span className="nm">{d.nowPlaying}</span>
                    <svg viewBox="0 0 24 24" fill="currentColor" width="20" height="20">
                      <circle cx="5" cy="12" r="2" />
                      <circle cx="12" cy="12" r="2" />
                      <circle cx="19" cy="12" r="2" />
                    </svg>
                  </div>
                  <div className="ph-mid">
                    <span className="badge">Anno · I</span>
                    <div className="ti">
                      {d.phoneTitleTop}
                      <br />
                      {d.phoneTitleBottom}
                    </div>
                    <div className="su">{d.phoneSubtitle}</div>
                  </div>
                  <div className="ph-bot">
                    <div className="ph-bar">
                      <i />
                    </div>
                    <div className="ph-time">
                      <span>02:31</span>
                      <span>06:38</span>
                    </div>
                    <div className="ph-ctrl">
                      <svg viewBox="0 0 24 24" fill="currentColor">
                        <polygon points="19 5 9 12 19 19" />
                        <rect x="5" y="5" width="2.4" height="14" rx="1" />
                      </svg>
                      <span className="play">
                        <svg viewBox="0 0 24 24" fill="#fff">
                          <polygon points="7 4 20 12 7 20" />
                        </svg>
                      </span>
                      <svg viewBox="0 0 24 24" fill="currentColor">
                        <polygon points="5 5 15 12 5 19" />
                        <rect x="16.6" y="5" width="2.4" height="14" rx="1" />
                      </svg>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
