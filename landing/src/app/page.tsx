import Navbar from "@/components/Navbar";
import Hero from "@/components/Hero";
import VideoShowcase from "@/components/VideoShowcase";
import AINarration from "@/components/AINarration";
import EyesUpDiscovery from "@/components/EyesUpDiscovery";
import PhotoIdentify from "@/components/PhotoIdentify";
import KnowledgeJourney from "@/components/KnowledgeJourney";
import FinalCTA from "@/components/FinalCTA";
import Footer from "@/components/Footer";

export default function Home() {
  return (
    <>
      <Navbar />
      <Hero />
      <main className="mx-auto max-w-7xl space-y-28 px-6 py-24 md:px-8 md:space-y-36">
        <VideoShowcase />
        <AINarration />
        <EyesUpDiscovery />
        <PhotoIdentify />
        <KnowledgeJourney />
        <FinalCTA />
      </main>
      <Footer />
    </>
  );
}
