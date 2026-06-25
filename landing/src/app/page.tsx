import Navbar from "@/components/Navbar";
import Hero from "@/components/Hero";
import Manifesto from "@/components/Manifesto";
import LocalStories from "@/components/LocalStories";
import ManyAngles from "@/components/ManyAngles";
import ExploreNearby from "@/components/ExploreNearby";
import JourneyJournal from "@/components/JourneyJournal";
import FinalCTA from "@/components/FinalCTA";
import Footer from "@/components/Footer";
import { getDictionary } from "@/i18n/dictionaries";

export default function Home() {
  const d = getDictionary("zh");
  return (
    <>
      <Navbar />
      <main>
        <Hero d={d.hero} />
        <Manifesto d={d.manifesto} />
        <LocalStories d={d.localStories} />
        <ManyAngles d={d.manyAngles} />
        <ExploreNearby d={d.exploreNearby} />
        <JourneyJournal d={d.journeyJournal} />
        <FinalCTA d={d.finalCTA} />
      </main>
      <Footer />
    </>
  );
}
