import "./index.css";
import { Composition } from "remotion";
import { Main } from "./Main";

export const RemotionRoot: React.FC = () => {
  return (
    <Composition
      id="LorescapeIntro"
      component={Main}
      durationInFrames={900}
      fps={30}
      width={1920}
      height={1080}
    />
  );
};
