import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { getDictionary } from "@/i18n/dictionaries";
import { isLocale, type Locale } from "@/i18n/config";
import { getDailyStory, isValidStoryDate } from "@/lib/dailyStory";
import StoreButtons from "@/components/StoreButtons";

type Params = { locale: string; date: string };

export async function generateMetadata({
  params,
}: {
  params: Params;
}): Promise<Metadata> {
  if (!isLocale(params.locale) || !isValidStoryDate(params.date)) {
    return { robots: { index: false, follow: false } };
  }
  const d = getDictionary(params.locale);
  const story = await getDailyStory(params.locale, params.date);
  if (!story) {
    return {
      title: `${d.story.notFoundTitle} — Lorescape`,
      description: d.story.notFoundBody,
      robots: { index: false, follow: false },
    };
  }
  const title = `${story.title} — Lorescape`;
  const description = story.hook || story.paragraphs[0] || "";
  return {
    title,
    description,
    alternates: { canonical: `/${params.locale}/story/${params.date}` },
    openGraph: {
      title,
      description,
      type: "article",
      locale: params.locale === "zh" ? "zh_TW" : "en_US",
      siteName: "Lorescape",
      images: story.imageUrl ? [{ url: story.imageUrl }] : undefined,
    },
    twitter: {
      card: "summary_large_image",
      title,
      description,
      images: story.imageUrl ? [story.imageUrl] : undefined,
    },
    robots: { index: true, follow: true },
  };
}

export default async function StoryPage({ params }: { params: Params }) {
  if (!isLocale(params.locale)) notFound();
  if (!isValidStoryDate(params.date)) notFound();

  const locale = params.locale as Locale;
  const d = getDictionary(locale);
  const story = await getDailyStory(locale, params.date);

  if (!story) {
    return (
      <main className="story-page story-page--empty">
        <p className="story-eyebrow">{d.story.eyebrow}</p>
        <h1 className="story-title">{d.story.notFoundTitle}</h1>
        <p className="story-body">{d.story.notFoundBody}</p>
        <div className="story-cta">
          <StoreButtons
            location="story"
            variant="light"
            labels={d.storeButtons}
          />
        </div>
      </main>
    );
  }

  return (
    <main className="story-page">
      {story.imageUrl && (
        // eslint-disable-next-line @next/next/no-img-element
        <img
          className="story-cover"
          src={story.imageUrl}
          alt={story.placeName}
        />
      )}
      <p className="story-eyebrow">{d.story.eyebrow}</p>
      <p className="story-meta">
        {story.placeName} · {story.placeLocation} · {story.era}
      </p>
      <h1 className="story-title">{story.title}</h1>
      {story.hook && <p className="story-hook">{story.hook}</p>}
      {story.paragraphs.map((p, i) => (
        <p key={i} className="story-body">
          {p}
        </p>
      ))}
      <p className="story-continue">{d.story.continueCta}</p>
      <div className="story-cta">
        <StoreButtons location="story" variant="light" labels={d.storeButtons} />
      </div>
    </main>
  );
}
