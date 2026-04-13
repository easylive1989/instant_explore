import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        surface: {
          DEFAULT: "#101922",
          dim: "#0d141b",
          bright: "#222d39",
          container: {
            DEFAULT: "#1c2630",
            low: "#151e27",
            high: "#27313c",
            highest: "#323c48",
            lowest: "#0b1117",
          },
          variant: "rgba(255, 255, 255, 0.08)",
          tint: "#137fec",
        },
        primary: {
          DEFAULT: "#137fec",
          fixed: "#d5e3ff",
          "fixed-dim": "#a8c8ff",
          container: "rgba(19, 127, 236, 0.2)",
        },
        secondary: {
          DEFAULT: "#adc8f7",
          fixed: "#d5e3ff",
          "fixed-dim": "#adc8f7",
          container: "#2c4770",
        },
        tertiary: {
          DEFAULT: "#ffb68c",
          container: "#e47019",
        },
        error: {
          DEFAULT: "#ffb4ab",
          container: "#93000a",
        },
        "on-surface": {
          DEFAULT: "#ffffff",
          variant: "#c1c6d5",
        },
        "on-primary": "#ffffff",
        "on-secondary": "#123158",
        "on-error": "#690005",
        outline: {
          DEFAULT: "#8b919f",
          variant: "rgba(255, 255, 255, 0.1)",
        },
        "inverse-surface": "#e0e2ec",
        "inverse-on-surface": "#2d3038",
        "inverse-primary": "#005eb4",
        background: "#101922",
      },
      fontFamily: {
        sans: ["var(--font-inter)", "Inter", "sans-serif"],
      },
      borderRadius: {
        DEFAULT: "0.25rem",
        lg: "0.5rem",
        xl: "0.75rem",
        full: "9999px",
      },
    },
  },
  plugins: [],
};
export default config;
