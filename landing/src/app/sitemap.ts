import { MetadataRoute } from "next";

export default function sitemap(): MetadataRoute.Sitemap {
  const base = "https://lorescape.app";
  return [
    { url: `${base}/zh`, changeFrequency: "monthly", priority: 1 },
    { url: `${base}/en`, changeFrequency: "monthly", priority: 1 },
    { url: `${base}/privacy`, changeFrequency: "yearly", priority: 0.5 },
    { url: `${base}/terms`, changeFrequency: "yearly", priority: 0.5 },
    { url: `${base}/support`, changeFrequency: "yearly", priority: 0.5 },
    { url: `${base}/credits`, changeFrequency: "yearly", priority: 0.3 },
  ];
}
