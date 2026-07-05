import React from "react";
import { colors } from "../theme";

type Props = {
  children: React.ReactNode;
  width?: number;
  height?: number;
  statusDark?: boolean;
};

// Light-theme iPhone mockup: warm bezel, white screen, dynamic island.
// Pure CSS/SVG — no external assets.
export const PhoneFrame: React.FC<Props> = ({
  children,
  width = 430,
  height,
  statusDark = true,
}) => {
  const radius = 62;
  const bezel = 14;
  const resolvedHeight = height ?? Math.round(width / 0.462);
  const statusColor = statusDark ? colors.ink : colors.onDark;

  return (
    <div
      style={{
        width,
        height: resolvedHeight,
        borderRadius: radius,
        padding: bezel,
        background: `linear-gradient(160deg, #2c241c 0%, #15110c 55%, #2c241c 100%)`,
        boxShadow:
          "0 40px 110px rgba(28,20,10,0.45), 0 0 0 1px rgba(255,255,255,0.04)",
        position: "relative",
      }}
    >
      <div
        style={{
          width: "100%",
          height: "100%",
          borderRadius: radius - bezel,
          overflow: "hidden",
          position: "relative",
          background: colors.paperRaised,
        }}
      >
        {children}
        <div
          style={{
            position: "absolute",
            top: 0,
            left: 0,
            right: 0,
            height: 54,
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
            padding: "0 30px",
            zIndex: 20,
            fontFamily: "-apple-system, sans-serif",
            fontSize: 17,
            fontWeight: 600,
            color: statusColor,
          }}
        >
          <span>8:20</span>
          <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
            {/* Signal bars */}
            <svg width="18" height="12" viewBox="0 0 18 12" fill="none">
              <rect x="0" y="7" width="3" height="5" rx="0.5" fill={statusColor} />
              <rect x="5" y="5" width="3" height="7" rx="0.5" fill={statusColor} />
              <rect x="10" y="3" width="3" height="9" rx="0.5" fill={statusColor} />
              <rect x="15" y="0" width="3" height="12" rx="0.5" fill={statusColor} />
            </svg>
            {/* Wi-Fi glyph */}
            <svg width="16" height="12" viewBox="0 0 16 12" fill="none">
              <path
                d="M8 10.5a1.1 1.1 0 1 1 0-2.2 1.1 1.1 0 0 1 0 2.2Z"
                fill={statusColor}
              />
              <path
                d="M4.6 6.6a4.8 4.8 0 0 1 6.8 0"
                stroke={statusColor}
                strokeWidth="1.4"
                strokeLinecap="round"
                fill="none"
              />
              <path
                d="M1.8 3.8a8.6 8.6 0 0 1 12.4 0"
                stroke={statusColor}
                strokeWidth="1.4"
                strokeLinecap="round"
                fill="none"
              />
            </svg>
            {/* Battery */}
            <div
              style={{
                display: "flex",
                alignItems: "center",
                gap: 2,
              }}
            >
              <div
                style={{
                  width: 22,
                  height: 11,
                  borderRadius: 3,
                  border: `1.4px solid ${statusColor}`,
                  padding: 1.5,
                  boxSizing: "border-box",
                }}
              >
                <div
                  style={{
                    width: "82%",
                    height: "100%",
                    borderRadius: 1,
                    background: statusColor,
                  }}
                />
              </div>
              <div
                style={{
                  width: 1.5,
                  height: 4,
                  borderRadius: 1,
                  background: statusColor,
                  opacity: 0.9,
                }}
              />
            </div>
          </div>
        </div>
        <div
          style={{
            position: "absolute",
            top: 14,
            left: "50%",
            transform: "translateX(-50%)",
            width: 110,
            height: 30,
            borderRadius: 999,
            background: "#000",
            zIndex: 10,
          }}
        />
      </div>
    </div>
  );
};
