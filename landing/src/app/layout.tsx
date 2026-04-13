import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";

const inter = Inter({
  subsets: ["latin"],
  variable: "--font-inter",
  display: "swap",
});

export const metadata: Metadata = {
  title: "Conexture — Experience History, Not Just Sights",
  description:
    "Your personal AI historian for immersive, eyes-up exploration. Hear the stories behind the stones with spatial audio narration.",
  keywords: [
    "AI tour guide",
    "historical narration",
    "travel app",
    "spatial audio",
    "photo identify",
    "cultural exploration",
    "Conexture",
  ],
  openGraph: {
    title: "Conexture — Experience History, Not Just Sights",
    description:
      "Your personal AI historian for immersive, eyes-up exploration.",
    type: "website",
    locale: "en_US",
    siteName: "Conexture",
  },
  twitter: {
    card: "summary_large_image",
    title: "Conexture — Experience History, Not Just Sights",
    description:
      "Your personal AI historian for immersive, eyes-up exploration.",
  },
  robots: {
    index: true,
    follow: true,
  },
};

const jsonLd = {
  "@context": "https://schema.org",
  "@type": "SoftwareApplication",
  name: "Conexture",
  applicationCategory: "TravelApplication",
  operatingSystem: "iOS, Android",
  description:
    "AI-powered historical tour guide with spatial audio narration and photo identification.",
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
    <html lang="en" className={inter.variable}>
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
      <body className="bg-surface text-on-surface font-sans antialiased selection:bg-primary/30">
        {children}
      </body>
    </html>
  );
}
