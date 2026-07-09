import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { getDictionary } from "@/i18n/dictionaries";
import { isLocale, type Locale } from "@/i18n/config";
import { getPlace, placeSlugs } from "@/lib/places";
import StoreButtons from "@/components/StoreButtons";

type Params = { locale: string; slug: string };

// Static export: only the {locale, slug} pairs listed here are generated;
// any unknown place 404s on the static host.
export const dynamicParams = false;

export function generateStaticParams() {
  return placeSlugs().flatMap((slug) => [
    { locale: "zh", slug },
    { locale: "en", slug },
  ]);
}

export function generateMetadata({ params }: { params: Params }): Metadata {
  if (!isLocale(params.locale)) return {};
  const place = getPlace(params.slug);
  if (!place) return { robots: { index: false, follow: false } };

  const locale = params.locale as Locale;
  const c = place[locale];
  const path = `/${locale}/place/${params.slug}`;
  return {
    title: c.metaTitle,
    description: c.metaDescription,
    keywords: c.keywords,
    alternates: {
      canonical: path,
      languages: {
        "zh-Hant": `/zh/place/${params.slug}`,
        en: `/en/place/${params.slug}`,
      },
    },
    openGraph: {
      title: c.metaTitle,
      description: c.metaDescription,
      type: "article",
      locale: locale === "zh" ? "zh_TW" : "en_US",
      siteName: "Lorescape",
    },
    twitter: {
      card: "summary_large_image",
      title: c.metaTitle,
      description: c.metaDescription,
    },
    robots: { index: true, follow: true },
  };
}

export default function PlacePage({ params }: { params: Params }) {
  if (!isLocale(params.locale)) notFound();
  const place = getPlace(params.slug);
  if (!place) notFound();

  const locale = params.locale as Locale;
  const c = place[locale];
  const d = getDictionary(locale);

  return (
    <main className="story-page">
      <p className="story-eyebrow">{c.eyebrow}</p>
      <p className="story-meta">
        {c.placeName} · {c.placeLocation} · {c.era}
      </p>
      <h1 className="story-title">{c.title}</h1>
      <p className="story-hook">{c.hook}</p>
      {c.paragraphs.map((p, i) => (
        <p key={i} className="story-body">
          {p}
        </p>
      ))}
      <p className="story-continue">{c.continueCta}</p>
      <div className="story-cta">
        <StoreButtons location="place" variant="light" labels={d.storeButtons} />
      </div>
    </main>
  );
}
