import Navbar from "@/components/Navbar";
import Hero from "@/components/Hero";
import EyesUpDiscovery from "@/components/EyesUpDiscovery";
import AINarration from "@/components/AINarration";
import PhotoIdentify from "@/components/PhotoIdentify";
import KnowledgePassport from "@/components/KnowledgePassport";
import FinalCTA from "@/components/FinalCTA";
import Footer from "@/components/Footer";

export default function Home() {
  return (
    <>
      <Navbar />
      <Hero />
      <main className="max-w-7xl mx-auto px-8 py-24 space-y-32">
        <EyesUpDiscovery />
        <AINarration />
        <PhotoIdentify />
        <KnowledgePassport />
        <FinalCTA />
      </main>
      <Footer />
    </>
  );
}
