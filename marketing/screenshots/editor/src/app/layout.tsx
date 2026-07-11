import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";

const font = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "App Store Screenshots",
  description: "Design and export App Store + Google Play screenshots.",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <head>
        {/* Script-accent + CJK fonts for the hand-drawn editorial style. */}
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <link
          href="https://fonts.googleapis.com/css2?family=Caveat:wght@700&family=Lilita+One&family=Fredoka:wght@500;600;700&family=Ma+Shan+Zheng&family=Noto+Sans+TC:wght@500;700;900&family=Noto+Serif+TC:wght@600;700;900&display=swap"
          rel="stylesheet"
        />
      </head>
      <body className={font.className}>{children}</body>
    </html>
  );
}
