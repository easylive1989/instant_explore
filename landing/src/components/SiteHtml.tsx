import type React from "react";
import { GoogleAnalytics } from "@next/third-parties/google";
import { notoSerifTc, notoSansTc } from "@/app/fonts";

const gaId = process.env.NEXT_PUBLIC_GA_ID;

const jsonLd = {
  "@context": "https://schema.org",
  "@type": "SoftwareApplication",
  name: "Lorescape",
  applicationCategory: "TravelApplication",
  operatingSystem: "iOS, Android",
  description:
    "AI 隨行的旅行說書人，為眼前的地標、古蹟與山林即時編寫在地故事，還能化作語音邊走邊聽。",
  offers: { "@type": "Offer", price: "0", priceCurrency: "USD" },
};

export default function SiteHtml({
  lang,
  children,
}: {
  lang: string;
  children: React.ReactNode;
}) {
  return (
    <html
      lang={lang}
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
        {gaId ? <GoogleAnalytics gaId={gaId} /> : null}
      </body>
    </html>
  );
}
