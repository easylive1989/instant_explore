import { categoryColors } from "./theme";

export type StoryOption = { no: string; title: string; desc: string };
export type ReaderStory = {
  place: string;
  latin: string;
  chapter: string;
  title: string;
  sub: string;
  dropcap: string;
  body: string[];
  quote: { q: string; by: string };
  footer: string;
  date: string;
  img: string;
};
export type NearbyPlace = {
  name: string;
  latin: string;
  dist: string;
  cat: keyof typeof categoryColors;
  img: string;
};
export type JournalEntry = {
  date: string;
  time: string;
  title: string;
  text: string;
  img?: string;
};

// 聖伯多祿大殿三種故事角度（Ⅲ 一書多章）。
export const storyOptions: StoryOption[] = [
  {
    no: "01",
    title: "摧毀與重生的百年豪賭",
    desc: "儒略二世決定拆毀君士坦丁大帝的千年古教堂，這場瘋狂重建竟耗時百餘年……",
  },
  {
    no: "02",
    title: "祭壇之下的神聖祕密",
    desc: "世界上最大的教堂並非教宗的主教座堂，因為它底下埋藏著更神聖的祕密……",
  },
  {
    no: "03",
    title: "文藝復興巨匠的接力賽",
    desc: "米開朗基羅與拉斐爾等巨匠輪番上陣，如何在一座教堂上留下各自的瘋狂印記？",
  },
];

// Ⅳ 沉浸聆聽用的完整故事。
export const stPetersStory: ReaderStory = {
  place: "聖伯多祿大殿",
  latin: "ST. PETER'S BASILICA · VATICAN",
  chapter: "Anno · I",
  title: "摧毀與重生的百年豪賭",
  sub: "儒略二世與一座教堂的瘋狂重生",
  dropcap: "一",
  body: [
    "五〇六年四月，羅馬的春風吹拂著梵蒂岡山丘。教宗儒略二世站在那座由君士坦丁大帝於四世紀建造、如今已顯得破舊不堪的老聖伯多祿大殿前。",
    "對儒略二世而言，這座古老的教堂不僅僅是一座建築，更是天主教會最神聖的象徵，因為聖傳記載著耶穌宗徒之長聖伯多祿的遺骨，就安葬於這片土地之下。",
    "為了守護這份神聖的遺產，並展現教會的權威與榮光，他做出了一個驚世駭俗的決定——拆毀這座千年古堂，在原址上重建一座前所未見的雄偉聖殿。",
  ],
  quote: { q: "拆毀，是為了一場橫跨百年的重生。", by: "—— 聖伯多祿大殿" },
  footer: "梵蒂岡 · VATICAN",
  date: "2026年5月30日",
  img: "images/stpeters.jpg",
};

// Ⅱ 地標登場的附近清單。
export const exploreChips = ["信仰聖地", "人文古蹟", "自然景觀", "城市地標"];

export const nearbyPlaces: NearbyPlace[] = [
  {
    name: "聖伯多祿大殿",
    latin: "ST. PETER'S BASILICA",
    dist: "1.2 km",
    cat: "sacred",
    img: "images/stpeters.jpg",
  },
  {
    name: "台中朝聖宮",
    latin: "CHAOSHENG TEMPLE",
    dist: "320 m",
    cat: "heritage",
    img: "images/temple.jpg",
  },
  {
    name: "馬卡龍公園",
    latin: "MACARON PARK",
    dist: "650 m",
    cat: "nature",
    img: "images/park.jpg",
  },
];

// Ⅴ 旅程成冊的手記篇章。
export const journalEntries: JournalEntry[] = [
  {
    date: "5月 16",
    time: "09:50",
    title: "彰化泰京山莊四面佛寺",
    text: "四面佛寺的故事，要從一位平凡的蚵仔麵線小販說起。民國七十四年左右，林逢永先生跟團遠赴泰國，走進了曼谷香火鼎盛的……",
    img: "images/temple.jpg",
  },
  {
    date: "5月 12",
    time: "17:24",
    title: "南觀音山",
    text: "南觀音山的稜線在暮色中起伏，像一道凝固的浪。早年採石的痕跡仍鐫刻在山腹，如今卻被綠意慢慢縫合，成為城市邊緣一處被重新看見的野地……",
  },
  {
    date: "5月 17",
    time: "08:51",
    title: "廊子公園",
    text: "漫步廊子公園，目光總會被眼前這幾株雄偉的老榕樹吸引。它們枝繁葉茂，氣根盤結，彷彿一位位歷經滄桑的長者，靜默地守護著這片土地……",
  },
];
