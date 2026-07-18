import type { Metadata } from "next";
import { notFound } from "next/navigation";
import SiteHtml from "@/components/SiteHtml";
import { getDictionary } from "@/i18n/dictionaries";
import { isLocale, locales, type Locale } from "@/i18n/config";

export function generateStaticParams() {
  return locales.map((locale) => ({ locale }));
}

export function generateMetadata({
  params,
}: {
  params: { locale: string };
}): Metadata {
  if (!isLocale(params.locale)) return {};
  const d = getDictionary(params.locale);
  return {
    title: d.metadata.title,
    description: d.metadata.description,
    keywords: d.metadata.keywords,
    alternates: {
      canonical: `/${params.locale}`,
      languages: { "zh-Hant": "/zh", en: "/en", "x-default": "/en" },
    },
    openGraph: {
      title: d.metadata.ogTitle,
      description: d.metadata.ogDescription,
      type: "website",
      locale: params.locale === "zh" ? "zh_TW" : "en_US",
      siteName: "Lorescape",
    },
    twitter: {
      card: "summary_large_image",
      title: d.metadata.ogTitle,
      description: d.metadata.ogDescription,
    },
    robots: { index: true, follow: true },
  };
}

export default function LocaleLayout({
  children,
  params,
}: {
  children: React.ReactNode;
  params: { locale: string };
}) {
  if (!isLocale(params.locale)) notFound();
  const lang: string = (params.locale as Locale) === "zh" ? "zh-Hant" : "en";
  return <SiteHtml lang={lang}>{children}</SiteHtml>;
}
