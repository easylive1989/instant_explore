import SiteHtml from "@/components/SiteHtml";

export default function LegalLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return <SiteHtml lang="en">{children}</SiteHtml>;
}
