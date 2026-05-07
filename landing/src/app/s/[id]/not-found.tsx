import Link from "next/link";
import Navbar from "@/components/Navbar";
import Footer from "@/components/Footer";

export default function SharedJourneyNotFound() {
  return (
    <>
      <Navbar />
      <main className="max-w-2xl mx-auto px-8 pt-32 pb-24 text-center">
        <h1 className="text-4xl font-black mb-4">Story not found</h1>
        <p className="text-on-surface-variant mb-10">
          This shared story may have been removed, or the link is invalid.
        </p>
        <Link
          href="/"
          className="inline-block bg-primary text-white px-8 py-4 rounded-full font-black hover:bg-primary-fixed-dim transition-colors"
        >
          Explore Lorescape
        </Link>
      </main>
      <Footer />
    </>
  );
}
