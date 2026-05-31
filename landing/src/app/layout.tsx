import type { Metadata } from "next";
import { Noto_Serif_TC, Noto_Sans_TC } from "next/font/google";
import { GoogleAnalytics } from "@next/third-parties/google";
import "./globals.css";

const gaId = process.env.NEXT_PUBLIC_GA_ID;

const notoSerifTc = Noto_Serif_TC({
  subsets: ["latin"],
  weight: ["400", "600", "700"],
  variable: "--font-noto-serif-tc",
  display: "swap",
});

const notoSansTc = Noto_Sans_TC({
  subsets: ["latin"],
  weight: ["400", "500", "600", "700"],
  variable: "--font-noto-sans-tc",
  display: "swap",
});

export const metadata: Metadata = {
  title: "Lorescape — 讓每一處風景，開口說它的故事",
  description:
    "AI 隨行的旅行說書人。走到哪，就把那裡的來歷、傳說與歷史，為你即時編寫成值得細讀的故事，還能化作語音邊走邊聽。",
  keywords: [
    "AI 導覽",
    "旅行說書人",
    "在地故事",
    "語音導覽",
    "文化旅遊",
    "Lorescape",
    "讀景",
  ],
  openGraph: {
    title: "Lorescape — 讓每一處風景，開口說它的故事",
    description: "AI 隨行的旅行說書人，為每一處風景備好屬於它的故事。",
    type: "website",
    locale: "zh_TW",
    siteName: "Lorescape",
  },
  twitter: {
    card: "summary_large_image",
    title: "Lorescape — 讓每一處風景，開口說它的故事",
    description: "AI 隨行的旅行說書人，為每一處風景備好屬於它的故事。",
  },
  robots: {
    index: true,
    follow: true,
  },
};

const jsonLd = {
  "@context": "https://schema.org",
  "@type": "SoftwareApplication",
  name: "Lorescape",
  applicationCategory: "TravelApplication",
  operatingSystem: "iOS, Android",
  description:
    "AI 隨行的旅行說書人，為眼前的地標、古蹟與山林即時編寫在地故事，還能化作語音邊走邊聽。",
  offers: {
    "@type": "Offer",
    price: "0",
    priceCurrency: "USD",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="zh-Hant"
      className={`${notoSerifTc.variable} ${notoSansTc.variable}`}
    >
      <head>
        <link
          href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&display=swap"
          rel="stylesheet"
        />
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
        />
      </head>
      <body className="bg-paper text-ink font-sans antialiased selection:bg-clay/20">
        {children}
      </body>
      {gaId ? <GoogleAnalytics gaId={gaId} /> : null}
    </html>
  );
}
