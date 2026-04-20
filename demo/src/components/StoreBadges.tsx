import React from "react";

const badgeStyle: React.CSSProperties = {
  display: "flex",
  alignItems: "center",
  gap: 14,
  padding: "14px 26px",
  borderRadius: 14,
  background: "#000",
  border: "1px solid rgba(255,255,255,0.15)",
  color: "#fff",
  fontFamily:
    '"Inter","Noto Sans",-apple-system,BlinkMacSystemFont,sans-serif',
  minWidth: 240,
};

const AppleLogo: React.FC = () => (
  <svg width="34" height="38" viewBox="0 0 24 24" fill="#fff">
    <path d="M17.6 13.35c-.03-3.1 2.54-4.58 2.65-4.66-1.44-2.1-3.69-2.4-4.49-2.43-1.91-.19-3.72 1.12-4.7 1.12-.96 0-2.45-1.1-4.03-1.07-2.07.03-3.98 1.2-5.05 3.06-2.15 3.74-.55 9.29 1.55 12.34 1.02 1.48 2.25 3.15 3.85 3.1 1.54-.06 2.13-1 3.99-1s2.39 1 4.03.97c1.66-.03 2.71-1.52 3.73-3.01 1.17-1.73 1.66-3.41 1.69-3.5-.04-.02-3.24-1.24-3.27-4.92zM14.8 3.82c.85-1.03 1.42-2.46 1.26-3.88-1.22.05-2.69.81-3.56 1.84-.79.91-1.48 2.37-1.29 3.76 1.36.1 2.75-.69 3.59-1.72z"/>
  </svg>
);

const PlayLogo: React.FC = () => (
  <svg width="34" height="38" viewBox="0 0 512 512">
    <defs>
      <linearGradient id="play-a" x1="0" y1="0" x2="1" y2="1">
        <stop offset="0%" stopColor="#00d2ff" />
        <stop offset="100%" stopColor="#3a7bd5" />
      </linearGradient>
      <linearGradient id="play-b" x1="0" y1="0" x2="1" y2="1">
        <stop offset="0%" stopColor="#ff6a3d" />
        <stop offset="100%" stopColor="#ffcf00" />
      </linearGradient>
      <linearGradient id="play-c" x1="0" y1="0" x2="1" y2="1">
        <stop offset="0%" stopColor="#00f260" />
        <stop offset="100%" stopColor="#0575e6" />
      </linearGradient>
      <linearGradient id="play-d" x1="0" y1="0" x2="1" y2="1">
        <stop offset="0%" stopColor="#ff0844" />
        <stop offset="100%" stopColor="#ffb199" />
      </linearGradient>
    </defs>
    <path fill="url(#play-c)" d="M62 54 L300 256 L62 458 Z" />
    <path fill="url(#play-a)" d="M62 54 L300 256 L62 458 L62 54 Z" opacity="0" />
    <path fill="url(#play-a)" d="M62 54 L380 234 L300 256 Z" />
    <path fill="url(#play-d)" d="M62 458 L380 278 L300 256 Z" />
    <path fill="url(#play-b)" d="M380 234 L452 256 L380 278 L300 256 Z" />
  </svg>
);

export const StoreBadges: React.FC = () => {
  return (
    <div style={{ display: "flex", gap: 20 }}>
      <div style={badgeStyle}>
        <AppleLogo />
        <div>
          <div
            style={{
              fontSize: 12,
              letterSpacing: 0.4,
              opacity: 0.8,
              lineHeight: 1.1,
            }}
          >
            Download on the
          </div>
          <div style={{ fontSize: 24, fontWeight: 600, lineHeight: 1.1 }}>
            App Store
          </div>
        </div>
      </div>
      <div style={badgeStyle}>
        <PlayLogo />
        <div>
          <div
            style={{
              fontSize: 12,
              letterSpacing: 0.4,
              opacity: 0.8,
              lineHeight: 1.1,
            }}
          >
            GET IT ON
          </div>
          <div style={{ fontSize: 24, fontWeight: 600, lineHeight: 1.1 }}>
            Google Play
          </div>
        </div>
      </div>
    </div>
  );
};
