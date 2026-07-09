import "./index.css";
import { Composition } from "remotion";
import { FPS, totalFrames } from "./data/story";
import { Cinematic } from "./styles/Cinematic";
import { Editorial } from "./styles/Editorial";
import { Collage } from "./styles/Collage";
import { Focus } from "./styles/Focus";

const WIDTH = 1080;
const HEIGHT = 1920;

export const RemotionRoot: React.FC = () => {
  return (
    <>
      <Composition
        id="Cinematic"
        component={Cinematic}
        durationInFrames={totalFrames(18)}
        fps={FPS}
        width={WIDTH}
        height={HEIGHT}
      />
      <Composition
        id="Editorial"
        component={Editorial}
        durationInFrames={totalFrames(14)}
        fps={FPS}
        width={WIDTH}
        height={HEIGHT}
      />
      <Composition
        id="Collage"
        component={Collage}
        durationInFrames={totalFrames(12)}
        fps={FPS}
        width={WIDTH}
        height={HEIGHT}
      />
      <Composition
        id="Focus"
        component={Focus}
        durationInFrames={totalFrames(16)}
        fps={FPS}
        width={WIDTH}
        height={HEIGHT}
      />
    </>
  );
};
