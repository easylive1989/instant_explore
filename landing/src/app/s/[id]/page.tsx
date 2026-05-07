import type { Metadata } from "next";
import { notFound } from "next/navigation";
import Navbar from "@/components/Navbar";
import Footer from "@/components/Footer";
import FinalCTA from "@/components/FinalCTA";
import { fetchSharedJourney, SharedJourney } from "@/lib/supabase";

type Props = { params: { id: string } };

const SHARE_BASE_URL =
  process.env.NEXT_PUBLIC_SHARE_BASE_URL ?? "https://lorescape.app";

const NARRATION_PREVIEW_LIMIT = 200;

function buildPreview(text: string): string {
  const trimmed = text.trim().replace(/\s+/g, " ");
  if (trimmed.length <= NARRATION_PREVIEW_LIMIT) return trimmed;
  return `${trimmed.slice(0, NARRATION_PREVIEW_LIMIT - 1)}…`;
}

function formatVisitedAt(iso: string, locale: string): string {
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) return "";
  return new Intl.DateTimeFormat(locale, {
    year: "numeric",
    month: "long",
    day: "numeric",
  }).format(date);
}

export async function generateMetadata({
  params,
}: Props): Promise<Metadata> {
  const journey = await fetchSharedJourney(params.id);
  if (!journey) {
    return {
      title: "Lorescape — Story not found",
      robots: { index: false, follow: false },
    };
  }

  const title = `${journey.place_name} — Lorescape`;
  const description = buildPreview(journey.narration_text);
  const url = `${SHARE_BASE_URL.replace(/\/$/, "")}/s/${journey.id}`;
  const image = journey.place_image_url ?? undefined;

  return {
    title,
    description,
    alternates: { canonical: url },
    openGraph: {
      title,
      description,
      url,
      siteName: "Lorescape",
      type: "article",
      images: image ? [{ url: image, alt: journey.place_name }] : undefined,
    },
    twitter: {
      card: image ? "summary_large_image" : "summary",
      title,
      description,
      images: image ? [image] : undefined,
    },
  };
}

export default async function SharedJourneyPage({ params }: Props) {
  const journey = await fetchSharedJourney(params.id);
  if (!journey) {
    notFound();
  }
  return <SharedJourneyView journey={journey} />;
}

function SharedJourneyView({ journey }: { journey: SharedJourney }) {
  const visitedAt = formatVisitedAt(journey.visited_at, journey.language);
  const paragraphs = journey.narration_text
    .split(/\n\s*\n/)
    .map((p) => p.trim())
    .filter(Boolean);

  return (
    <>
      <Navbar />
      <main className="max-w-3xl mx-auto px-6 sm:px-8 pt-28 pb-16">
        <article className="space-y-10">
          {journey.place_image_url ? (
            <div className="relative rounded-3xl overflow-hidden aspect-[16/10] shadow-2xl shadow-black/40">
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img
                src={journey.place_image_url}
                alt={journey.place_name}
                className="w-full h-full object-cover"
              />
            </div>
          ) : null}

          <header className="space-y-3">
            {visitedAt ? (
              <p className="text-sm uppercase tracking-[0.2em] text-on-surface-variant font-semibold">
                {visitedAt}
              </p>
            ) : null}
            <h1 className="text-4xl sm:text-5xl font-black tracking-tight leading-tight">
              {journey.place_name}
            </h1>
            {journey.place_address ? (
              <p className="text-on-surface-variant text-lg">
                {journey.place_address}
              </p>
            ) : null}
          </header>

          <section className="space-y-6 text-lg leading-relaxed text-on-surface/90">
            {paragraphs.length > 0
              ? paragraphs.map((paragraph, index) => (
                  <p key={index}>{paragraph}</p>
                ))
              : (
                <p>{journey.narration_text}</p>
              )}
          </section>
        </article>
      </main>

      <section className="max-w-7xl mx-auto px-8 pb-24">
        <FinalCTA />
      </section>
      <Footer />
    </>
  );
}
