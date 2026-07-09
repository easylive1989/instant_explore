import type { Locale } from "@/i18n/config";

/// Per-locale content for a single place landing page.
///
/// These pages target high-intent, long-tail SEO queries such as
/// "羅浮宮 導覽app" / "Louvre audio guide". Each place gets one indexable page
/// per locale with a real story excerpt plus a download CTA — the same shape
/// the app delivers, so the page previews the product while ranking.
export interface PlaceContent {
  /// SEO <title>. Front-load the searched term (place + 導覽/audio guide).
  metaTitle: string;

  /// SEO meta description. Woven with the target keywords, still readable.
  metaDescription: string;

  /// <meta name="keywords"> terms mined from Google autocomplete.
  keywords: string[];

  /// Small uppercase label above the title.
  eyebrow: string;

  placeName: string;
  placeLocation: string;
  era: string;

  /// Editorial headline for the story excerpt.
  title: string;

  /// One-line pull quote setting the hook.
  hook: string;

  /// Body paragraphs of the excerpt (wiki-grounded, concise).
  paragraphs: string[];

  /// Closing line that bridges into the download CTA.
  continueCta: string;
}

export type Place = Record<Locale, PlaceContent> & { slug: string };

const places: Place[] = [
  {
    slug: "louvre",
    zh: {
      metaTitle: "羅浮宮語音導覽 App｜用中文聽羅浮宮的故事 — Lorescape 讀景",
      metaDescription:
        "走進羅浮宮前，先聽它的來歷。Lorescape 讀景用中文即時為你講述羅浮" +
        "宮從堡壘、王宮到世界最大美術館的八百年故事，不必租導覽機，手機就" +
        "能邊走邊聽。",
      keywords: [
        "羅浮宮 導覽app",
        "羅浮宮 語音導覽",
        "羅浮宮 導覽 中文",
        "羅浮宮 導覽機",
        "巴黎 景點導覽",
        "語音導覽",
      ],
      eyebrow: "Lorescape 景點導覽 · 巴黎",
      placeName: "羅浮宮",
      placeLocation: "法國巴黎",
      era: "1793 開館 · 建築始於 12 世紀",
      title: "從防禦堡壘到世界的美術館：羅浮宮的八百年",
      hook: "同一片石牆，曾經擋過敵軍、住過國王，如今擁抱著全人類的藝術。",
      paragraphs: [
        "羅浮宮最早不是美術館，而是一座堡壘。約 1190 年，法王腓力二世為守" +
          "衛巴黎而興建；隨著城市擴張，它逐漸失去軍事作用，在 14 世紀被改建" +
          "為王室居所。",
        "真正的轉捩點在 1793 年。法國大革命後，昔日的王宮向公眾敞開，成為" +
          "國家美術館。從此《蒙娜麗莎》的微笑、斷臂的《米洛的維納斯》、展翅" +
          "的《薩莫色雷斯的勝利女神》都在此與世人相遇。",
        "1989 年，貝聿銘設計的玻璃金字塔在拿破崙中庭落成，古典宮殿與現代" +
          "幾何的並置一度引發爭議，如今卻成了羅浮宮最鮮明的標誌。",
      ],
      continueCta:
        "這只是開場。用 Lorescape，走到羅浮宮的每一個展廳，都聽得到它自己" +
        "的故事。",
    },
    en: {
      metaTitle: "Louvre Audio Guide App｜Hear the Louvre's Story — Lorescape",
      metaDescription:
        "Before you step into the Louvre, hear where it came from. Lorescape " +
        "narrates the Louvre's 800-year journey from fortress to royal palace " +
        "to the world's largest art museum — no rented headset, just your " +
        "phone.",
      keywords: [
        "Louvre audio guide",
        "Louvre app",
        "Louvre tour guide",
        "Paris audio guide",
        "museum audio guide",
      ],
      eyebrow: "Lorescape Places · Paris",
      placeName: "Louvre Museum",
      placeLocation: "Paris, France",
      era: "Opened 1793 · built from the 12th c.",
      title: "From Fortress to the World's Museum: 800 Years of the Louvre",
      hook:
        "The same stone walls once held off armies and housed kings — now " +
        "they hold the art of all humanity.",
      paragraphs: [
        "The Louvre began not as a museum but as a fortress. Around 1190, " +
          "King Philip II built it to defend Paris; as the city grew, it lost " +
          "its military role and was rebuilt as a royal residence in the 14th " +
          "century.",
        "The turning point came in 1793. After the French Revolution, the " +
          "former palace opened to the public as a national museum. The smile " +
          "of the Mona Lisa, the armless Venus de Milo, and the winged Victory " +
          "of Samothrace have met the world here ever since.",
        "In 1989, I. M. Pei's glass pyramid rose in the Napoleon Courtyard. " +
          "The clash of classical palace and modern geometry stirred " +
          "controversy — yet it has become the Louvre's most recognizable " +
          "emblem.",
      ],
      continueCta:
        "This is only the opening. With Lorescape, every hall of the Louvre " +
        "has a story you can hear.",
    },
  },
  {
    slug: "national-palace-museum",
    zh: {
      metaTitle: "故宮導覽 App｜手機聽故宮語音導覽 — Lorescape 讀景",
      metaDescription:
        "逛故宮不必排隊租導覽機。Lorescape 讀景用中文為你講述國立故宮博物" +
        "院近七十萬件皇室珍藏背後的故事，翠玉白菜、肉形石的來歷，手機一開" +
        "就能邊看邊聽。",
      keywords: [
        "故宮 導覽app",
        "故宮 導覽",
        "故宮 語音導覽",
        "故宮 導覽機",
        "台北 景點導覽",
        "故宮 導覽 英文",
      ],
      eyebrow: "Lorescape 景點導覽 · 台北",
      placeName: "國立故宮博物院",
      placeLocation: "台灣台北",
      era: "1965 開館 · 藏品橫跨數千年",
      title: "半個中國的皇室收藏，如何落腳台北",
      hook: "近七十萬件文物，裝的是一整部橫跨數千年的中華文明。",
      paragraphs: [
        "故宮的收藏源自北京紫禁城的皇室舊藏。歷經戰亂與遷徙，一批批文物在" +
          " 20 世紀中葉輾轉來到台灣，最終在 1965 年於台北外雙溪落成的院區向" +
          "公眾開放。",
        "這裡收藏近七十萬件書畫、器物與典籍，時間跨越新石器時代到清末。其" +
          "中翠玉白菜以一塊天然玉料的青白，巧雕成菜葉與螽斯；肉形石則像一塊" +
          "晶瑩的東坡肉，是最受歡迎的鎮館之寶。",
        "因為藏品太多，故宮採輪展方式，每次只能看到一小部分——這也是為什" +
          "麼，懂得每件文物背後的故事，才真正看懂故宮。",
      ],
      continueCta:
        "別讓珍寶只是玻璃櫃裡的標籤。用 Lorescape，站在每一件文物前，都聽" +
        "得到它走過的路。",
    },
    en: {
      metaTitle: "National Palace Museum Audio Guide App — Lorescape",
      metaDescription:
        "Skip the rented headset at Taipei's National Palace Museum. " +
        "Lorescape narrates the stories behind its nearly 700,000 imperial " +
        "treasures — the Jadeite Cabbage, the Meat-shaped Stone — right from " +
        "your phone.",
      keywords: [
        "National Palace Museum audio guide",
        "National Palace Museum app",
        "Taipei museum guide",
        "故宮 audio guide",
        "Taipei audio guide",
      ],
      eyebrow: "Lorescape Places · Taipei",
      placeName: "National Palace Museum",
      placeLocation: "Taipei, Taiwan",
      era: "Opened 1965 · millennia of artifacts",
      title: "How Half of China's Imperial Collection Came to Taipei",
      hook:
        "Nearly 700,000 artifacts — an entire civilization spanning thousands " +
        "of years.",
      paragraphs: [
        "The museum's collection began in the imperial holdings of Beijing's " +
          "Forbidden City. Through war and upheaval, crates of treasures made " +
          "their way to Taiwan in the mid-20th century, finally opening to the " +
          "public in 1965 at its home in Taipei's Waishuangxi.",
        "It holds nearly 700,000 paintings, artifacts, and texts spanning the " +
          "Neolithic to the late Qing. Among them, the Jadeite Cabbage — " +
          "carved from a single piece of jade into leaves and a katydid — and " +
          "the Meat-shaped Stone, resembling a piece of braised pork, are its " +
          "most beloved treasures.",
        "Because the collection is so vast, works are shown in rotation; you " +
          "only ever see a fraction at once. Which is why knowing the story " +
          "behind each piece is what it means to truly see the museum.",
      ],
      continueCta:
        "Don't let treasures be labels behind glass. With Lorescape, every " +
        "artifact has a story you can hear as you stand before it.",
    },
  },
  {
    slug: "british-museum",
    zh: {
      metaTitle:
        "大英博物館導覽 App｜用中文聽大英博物館的故事 — Lorescape 讀景",
      metaDescription:
        "走進大英博物館前，先聽它的來歷。Lorescape 讀景用中文即時講述羅塞" +
        "塔石碑、埃及木乃伊、帕德嫩神廟大理石雕背後的故事，不必租導覽機，" +
        "手機就能邊走邊聽。",
      keywords: [
        "大英博物館 導覽app",
        "大英博物館 語音導覽",
        "大英博物館 導覽 中文",
        "大英博物館 導覽機",
        "倫敦 景點導覽",
        "語音導覽",
      ],
      eyebrow: "Lorescape 景點導覽 · 倫敦",
      placeName: "大英博物館",
      placeLocation: "英國倫敦",
      era: "1759 開館 · 世界最早的公共博物館之一",
      title: "把全世界搬進一棟建築：大英博物館的兩百年",
      hook:
        "從羅塞塔石碑到帕德嫩神廟的大理石，這裡收藏著人類文明的關鍵碎片。",
      paragraphs: [
        "大英博物館成立於 1753 年，源自醫師漢斯·斯隆爵士捐出的龐大收藏，" +
          "1759 年正式向公眾免費開放，是世界上最早的國家公共博物館之一。",
        "館內近八百萬件藏品橫跨兩百萬年的人類歷史。羅塞塔石碑讓學者破解了" +
          "古埃及象形文字；帕德嫩神廟的大理石雕、埃及木乃伊與亞述的獅子浮" +
          "雕，都是最受矚目的鎮館之寶。",
        "也因為許多藏品來自昔日殖民與遠征的年代，它們的歸屬至今仍是全球爭" +
          "論的話題——每一件文物，都牽著一段複雜的來時路。",
      ],
      continueCta:
        "這只是開場。用 Lorescape，走到大英博物館的每一間展廳，都聽得到它" +
        "自己的故事。",
    },
    en: {
      metaTitle: "British Museum Audio Guide App｜Hear the Story — Lorescape",
      metaDescription:
        "Before you step into the British Museum, hear where its treasures " +
        "came from. Lorescape narrates the stories behind the Rosetta Stone, " +
        "Egyptian mummies, and the Parthenon marbles — no rented headset, " +
        "just your phone.",
      keywords: [
        "British Museum audio guide",
        "British Museum app",
        "British Museum tour guide",
        "London audio guide",
        "museum audio guide",
      ],
      eyebrow: "Lorescape Places · London",
      placeName: "British Museum",
      placeLocation: "London, UK",
      era: "Opened 1759 · one of the first public museums",
      title: "The World Under One Roof: Two Centuries of the British Museum",
      hook:
        "From the Rosetta Stone to the Parthenon marbles, it holds the " +
        "pivotal fragments of human civilization.",
      paragraphs: [
        "The British Museum was founded in 1753 around the vast collection " +
          "bequeathed by the physician Sir Hans Sloane, and opened free to " +
          "the public in 1759 — one of the world's first national public " +
          "museums.",
        "Its nearly eight million objects span two million years of human " +
          "history. The Rosetta Stone let scholars finally decipher Egyptian " +
          "hieroglyphs; the Parthenon marbles, Egyptian mummies, and Assyrian " +
          "lion reliefs are among its most celebrated treasures.",
        "Because many pieces arrived in an age of empire and expedition, " +
          "their rightful ownership remains debated around the world — every " +
          "artifact carries a complicated journey behind it.",
      ],
      continueCta:
        "This is only the opening. With Lorescape, every gallery of the " +
        "British Museum has a story you can hear.",
    },
  },
  {
    slug: "sagrada-familia",
    zh: {
      metaTitle: "聖家堂導覽 App｜用中文聽高第聖家堂的故事 — Lorescape 讀景",
      metaDescription:
        "站在聖家堂前，先聽懂高第的巧思。Lorescape 讀景用中文即時講述這座" +
        "蓋了一百多年、仍未完工的教堂背後的故事，不必租導覽機，手機就能邊" +
        "走邊聽。",
      keywords: [
        "聖家堂 導覽app",
        "聖家堂 語音導覽",
        "聖家堂 導覽 中文",
        "巴塞隆納 景點導覽",
        "高第 建築",
        "語音導覽",
      ],
      eyebrow: "Lorescape 景點導覽 · 巴塞隆納",
      placeName: "聖家堂",
      placeLocation: "西班牙巴塞隆納",
      era: "1882 動工 · 迄今仍在興建",
      title: "蓋了一百四十年，還沒蓋完的教堂",
      hook: "高第說：「我的客戶並不急。」——因為他指的，是上帝。",
      paragraphs: [
        "聖家堂於 1882 年動工，隔年由建築師安東尼·高第接手。他把後半生完" +
          "全獻給這座教堂，直到 1926 年車禍離世時，工程也才完成不到四分之" +
          "一。",
        "高第從自然汲取靈感，把樹木、骨骼與幾何融進結構，讓石柱像森林般向" +
          "上分枝、光線穿過彩色玻璃灑落如林間。這種前所未見的形式，讓聖家堂" +
          "在 2005 年列入世界遺產。",
        "一百多年來，工程靠門票與捐款緩慢推進，預計在高第逝世百年的 2026 " +
          "年前後迎來主塔完工——你正好見證它最後的成形。",
      ],
      continueCta:
        "別只是仰頭讚嘆。用 Lorescape，站在聖家堂的每一道立面前，都聽得到" +
        "高第藏在石頭裡的心意。",
    },
    en: {
      metaTitle:
        "Sagrada Família Audio Guide App｜Hear Gaudí's Story — Lorescape",
      metaDescription:
        "Standing before the Sagrada Família, understand Gaudí's vision " +
        "first. Lorescape narrates the story of the church that has been " +
        "under construction for over a century — no rented headset, just " +
        "your phone.",
      keywords: [
        "Sagrada Familia audio guide",
        "Sagrada Familia app",
        "Sagrada Familia tour guide",
        "Barcelona audio guide",
        "Gaudi architecture",
      ],
      eyebrow: "Lorescape Places · Barcelona",
      placeName: "Sagrada Família",
      placeLocation: "Barcelona, Spain",
      era: "Begun 1882 · still under construction",
      title: "The Church That Has Been Rising for 140 Years",
      hook:
        'Gaudí once said, "My client is not in a hurry" — because he meant ' +
        "God.",
      paragraphs: [
        "Construction of the Sagrada Família began in 1882, and a year later " +
          "the architect Antoni Gaudí took over. He devoted the rest of his " +
          "life to it; when he died in a tram accident in 1926, less than a " +
          "quarter was complete.",
        "Gaudí drew from nature, weaving trees, bones, and geometry into the " +
          "structure so that columns branch upward like a forest and light " +
          "pours through stained glass as if through leaves. This " +
          "unprecedented form earned it World Heritage status in 2005.",
        "For over a century, the work has crept forward on ticket sales and " +
          "donations, with the main towers expected around 2026 — the " +
          "centenary of Gaudí's death. You are witnessing its final shape " +
          "emerge.",
      ],
      continueCta:
        "Don't just gaze up in awe. With Lorescape, before every façade of " +
        "the Sagrada Família you can hear the intention Gaudí hid in the " +
        "stone.",
    },
  },
  {
    slug: "chiang-kai-shek-memorial-hall",
    zh: {
      metaTitle:
        "中正紀念堂導覽 App｜手機聽中正紀念堂的故事 — Lorescape 讀景",
      metaDescription:
        "逛中正紀念堂不必租導覽機。Lorescape 讀景用中文講述這座地標的建" +
        "築、儀隊交接與周邊自由廣場的故事，手機一開就能邊走邊聽。",
      keywords: [
        "中正紀念堂 導覽",
        "中正紀念堂 語音導覽",
        "中正紀念堂 歷史",
        "台北 景點導覽",
        "自由廣場",
        "語音導覽",
      ],
      eyebrow: "Lorescape 景點導覽 · 台北",
      placeName: "中正紀念堂",
      placeLocation: "台灣台北",
      era: "1980 落成",
      title: "白牆藍頂之下：一座紀念堂的多重身影",
      hook: "同一片廣場，站過儀隊、辦過演唱會，也走過無數場改變台灣的集會。",
      paragraphs: [
        "中正紀念堂於 1980 年落成，是為紀念前總統蔣中正而建。主體以白色大" +
          "理石牆與藍色琉璃八角頂構成，八角呼應「八德」，正門到堂體共 89 " +
          "階，象徵他享壽的年歲。",
        "大廳裡的銅像與整點的儀隊交接是遊客必看的一景；而堂前遼闊的廣場，" +
          "1990 年代起見證了野百合學運等多場改變台灣民主進程的集會，後來被" +
          "命名為「自由廣場」。",
        "這座建築因此有了多重身影——它既是威權時代的紀念堂，也是民主化的" +
          "見證場，關於它的定位，至今仍是台灣社會持續對話的題目。",
      ],
      continueCta:
        "別讓地標只是一張到此一遊的照片。用 Lorescape，站在中正紀念堂前，" +
        "聽得到它走過的每一個身影。",
    },
    en: {
      metaTitle: "Chiang Kai-shek Memorial Hall Audio Guide App — Lorescape",
      metaDescription:
        "Skip the rented headset at Taipei's Chiang Kai-shek Memorial Hall. " +
        "Lorescape narrates the story of the landmark, its honor-guard " +
        "changing ceremony, and Liberty Square around it — right from your " +
        "phone.",
      keywords: [
        "Chiang Kai-shek Memorial Hall audio guide",
        "Chiang Kai-shek Memorial Hall guide",
        "Taipei audio guide",
        "Liberty Square Taipei",
        "Taipei attractions",
      ],
      eyebrow: "Lorescape Places · Taipei",
      placeName: "Chiang Kai-shek Memorial Hall",
      placeLocation: "Taipei, Taiwan",
      era: "Completed 1980",
      title: "Beneath the White Walls and Blue Roof: A Memorial's Many Faces",
      hook:
        "The same plaza has held honor guards, concerts, and countless " +
        "rallies that changed Taiwan.",
      paragraphs: [
        "Completed in 1980, the hall was built to commemorate former " +
          "president Chiang Kai-shek. Its white marble walls rise to a blue " +
          "octagonal roof — the eight sides echoing the \"eight virtues\" — " +
          "and 89 steps lead up to the main chamber, marking the years of his " +
          "life.",
        "The bronze statue in the great hall and the hourly changing of the " +
          "honor guard are must-sees; the vast plaza in front witnessed the " +
          "Wild Lily student movement of the 1990s and other gatherings that " +
          "shaped Taiwan's democracy, and was later named Liberty Square.",
        "The building thus carries many faces — a memorial of the " +
          "authoritarian era and a stage of democratization at once. Its " +
          "meaning remains a subject of ongoing conversation in Taiwanese " +
          "society.",
      ],
      continueCta:
        "Don't let a landmark be just a photo stop. With Lorescape, standing " +
        "before the hall, you can hear every face it has worn.",
    },
  },
];

/// Every place slug, for static generation and the sitemap.
export function placeSlugs(): string[] {
  return places.map((p) => p.slug);
}

/// Looks up a place by slug. Returns null when the slug is unknown so the
/// page can 404 on the static host.
export function getPlace(slug: string): Place | null {
  return places.find((p) => p.slug === slug) ?? null;
}
