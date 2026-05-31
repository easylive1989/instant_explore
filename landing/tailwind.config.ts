import type { Config } from "tailwindcss";

// Lorescape "Field Journal" design tokens (see docs/design/project/app/ls2.css).
const config: Config = {
  content: [
    "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        // Paper (light surfaces)
        paper: {
          DEFAULT: "#F7F1E6",
          raised: "#FDFAF3",
          sunk: "#ECE3D3",
        },
        line: {
          DEFAULT: "#E4DAC8",
          strong: "#CDBFA6",
        },
        // Ink (text on paper)
        ink: {
          DEFAULT: "#221C14",
          2: "#5E5341",
          3: "#918471",
        },
        // Clay (brand / terracotta)
        clay: {
          DEFAULT: "#BC5E3E",
          deep: "#97442A",
          soft: "#F1DDCE",
          tint: "#F7E8DD",
        },
        // Dark surfaces (immersive sections)
        "ink-bg": {
          DEFAULT: "#1B1611",
          2: "#251E17",
          3: "#312820",
        },
        "on-dark": {
          DEFAULT: "#F7F1E6",
          2: "#C3B7A4",
          3: "#8C8170",
        },
        // Category palette
        "cat-nature": { ink: "#4E6138", bg: "#E6E8D5" },
        "cat-heritage": { ink: "#8A6320", bg: "#F0E5CC" },
        "cat-urban": { ink: "#44597A", bg: "#DFE4EC" },
        "cat-sacred": { ink: "#6E4A63", bg: "#ECDCE6" },
      },
      fontFamily: {
        serif: ["var(--font-noto-serif-tc)", "Songti TC", "serif"],
        sans: [
          "var(--font-noto-sans-tc)",
          "-apple-system",
          "Helvetica Neue",
          "sans-serif",
        ],
      },
      borderRadius: {
        sm: "8px",
        md: "12px",
        lg: "16px",
        xl: "22px",
        img: "10px",
      },
      boxShadow: {
        e1: "0 1px 2px rgba(40,30,18,.06)",
        e2: "0 6px 18px rgba(40,30,18,.09)",
        e3: "0 18px 44px rgba(28,20,10,.20)",
      },
      letterSpacing: {
        eyebrow: "0.2em",
      },
    },
  },
  plugins: [],
};
export default config;
