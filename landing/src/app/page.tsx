import Navbar from "@/components/Navbar";
import Hero from "@/components/Hero";
import Manifesto from "@/components/Manifesto";
import LocalStories from "@/components/LocalStories";
import ManyAngles from "@/components/ManyAngles";
import ExploreNearby from "@/components/ExploreNearby";
import JourneyJournal from "@/components/JourneyJournal";
import FinalCTA from "@/components/FinalCTA";
import Footer from "@/components/Footer";

export default function Home() {
  return (
    <>
      <Navbar />
      <main>
        <Hero />
        <Manifesto />
        <LocalStories />
        <ManyAngles />
        <ExploreNearby />
        <JourneyJournal />
        <FinalCTA />
      </main>
      <Footer />
    </>
  );
}
