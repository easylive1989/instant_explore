import { MetadataRoute } from "next";
import { placeSlugs } from "@/lib/places";

export default function sitemap(): MetadataRoute.Sitemap {
  const base = "https://lorescape.app";
  const placePages: MetadataRoute.Sitemap = placeSlugs().flatMap((slug) => [
    {
      url: `${base}/zh/place/${slug}`,
      changeFrequency: "monthly" as const,
      priority: 0.8,
    },
    {
      url: `${base}/en/place/${slug}`,
      changeFrequency: "monthly" as const,
      priority: 0.8,
    },
  ]);
  return [
    { url: `${base}/zh`, changeFrequency: "monthly", priority: 1 },
    { url: `${base}/en`, changeFrequency: "monthly", priority: 1 },
    ...placePages,
    { url: `${base}/privacy`, changeFrequency: "yearly", priority: 0.5 },
    { url: `${base}/terms`, changeFrequency: "yearly", priority: 0.5 },
    { url: `${base}/support`, changeFrequency: "yearly", priority: 0.5 },
    { url: `${base}/credits`, changeFrequency: "yearly", priority: 0.3 },
  ];
}
