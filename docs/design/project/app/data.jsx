// data.jsx — Lorescape content. Exports window.LS_DATA
(function(){
  const CAT = {
    nature:   { label:"自然景觀", glyph:"mountain",  cls:"nature"  },
    heritage: { label:"人文古蹟", glyph:"columns",   cls:"heritage"},
    urban:    { label:"城市地標", glyph:"building",   cls:"urban"   },
    coast:    { label:"海岸水域", glyph:"waves",      cls:"coast"   },
    sacred:   { label:"信仰聖地", glyph:"book-marker", cls:"sacred" },
  };

  const PLACES = [
    { id:"stpeters", name:"聖伯多祿大殿", cat:"urban", img:"assets/img/stpeters.jpg",
      latin:"ST. PETER'S BASILICA · VATICAN", state:"options" },
    { id:"temple", name:"台中朝聖宮", cat:"heritage", img:"assets/img/temple.jpg",
      latin:"CHAOSHENG TEMPLE · TAICHUNG", state:"empty", saved:true },
    { id:"macaron", name:"馬卡龍公園", cat:"nature", img:"assets/img/park.jpg",
      latin:"MACARON PARK · TAICHUNG", state:"loading" },
    { id:"pinglin", name:"坪林森林公園", cat:"nature", glyph:true,
      latin:"PINGLIN FOREST PARK", state:"loading" },
    { id:"langzi", name:"廊子公園", cat:"nature", glyph:true,
      latin:"LANGZI PARK", state:"loading" },
    { id:"guanyin", name:"南觀音山", cat:"nature", glyph:true,
      latin:"NAN GUANYIN MOUNTAIN", state:"loading" },
  ];

  const STORY_OPTIONS = [
    { t:"摧毀與重生的百年豪賭", d:"儒略二世決定拆毀君士坦丁大帝的千年古教堂,這場瘋狂重建竟耗時百餘年……" },
    { t:"祭壇之下的神聖祕密", d:"世界上最大的教堂並非教宗的主教座堂,因為它底下埋藏著更神聖的祕密……" },
    { t:"文藝復興巨匠的接力賽", d:"米開朗基羅與拉斐爾等巨匠輪番上陣,如何在一座教堂上留下各自的瘋狂印記?" },
  ];

  // Full editorial stories (故事 feed + reader)
  const STORIES = [
    {
      id:"ahwar", place:"伊拉克南部阿瓦爾", img:"assets/img/ahwar.jpg",
      date:"2026年5月29日", chapter:"Anno · I",
      latin:"AHWAR OF SOUTHERN IRAQ · IRAQ",
      title:"尋找塵世的伊甸園", sub:"「阿瓦爾」沼澤與蘇美古城的文明啟示",
      dropcap:"聖",
      body:[
        "經學者們為了尋找傳說中的「伊甸園」,將目光投向底格里斯河與幼發拉底河交匯的伊拉克南部阿瓦爾。他們渴望在這片由河流滋養的土地上,證實人類文明與生命搖籃的起點。",
        "沼澤與古城的交織帶來了巨大挑戰。學者們必須在胡韋扎等四片濕地,以及烏魯克、吾珥與埃利都三座蘇美古城遺址之間,拼湊出自然生態與人類最早城市文明共生的歷史軌跡。",
        "阿瓦爾最終被證實為伊甸園的塵世遺存。這片融合了四處沼澤與三座古城的奇蹟之地,如今榮登世界遺產名錄,成為展現美索不達米亞文明起點與生物多樣性避難所的永恆見證。",
      ],
      quote:{ q:"「伊甸園」", by:"—— 聖經學者" },
      footer:"伊拉克 · IRAQ",
    },
    {
      id:"agra", place:"阿格拉紅堡", img:"assets/img/agra.jpg",
      date:"2026年5月28日", chapter:"Anno · II",
      latin:"AGRA FORT · INDIA",
      title:"帝王的紅砂岩王座", sub:"蒙兀兒王朝權力與愛恨的見證",
      dropcap:"阿",
      body:[
        "克巴皇帝在一五六五年凝視著阿格拉的舊要塞。自父親胡馬雍在此加冕後,這座古堡已顯破敗;於是他決心徹底重建,以紅砂岩砌出一座配得上帝國的雄偉王座。",
        "歷時八年,逾四千名工匠在亞穆納河畔築起這座周長兩公里半的城塞。它既是軍事堡壘,也是宮廷;其後的沙賈汗更在牆內添入白色大理石的優雅,讓剛硬的紅砂岩多了一分柔情。",
        "然而紅堡最動人的,是它最後的故事。沙賈汗晚年遭兒子奧朗則布囚禁於此,只能隔著河水,遙望他為亡妻所建、波光中的泰姬瑪哈陵,直到生命終了。",
      ],
      quote:{ q:"他只能隔著亞穆納河,遠望那座為愛而生的白色陵墓。", by:"—— 阿格拉紅堡" },
      footer:"印度 · INDIA",
    },
  ];

  // St Peter's reader (from a chosen story option) — has audio
  const STPETERS_STORY = {
    id:"stpeters-story", place:"聖伯多祿大殿", img:"assets/img/stpeters.jpg",
    date:"2026年5月30日", chapter:"Anno · I",
    latin:"ST. PETER'S BASILICA · VATICAN",
    title:"摧毀與重生的百年豪賭", sub:"儒略二世與一座教堂的瘋狂重生",
    dropcap:"一",
    body:[
      "五〇六年四月,羅馬的春風吹拂著梵蒂岡山丘。教宗儒略二世站在那座由君士坦丁大帝於四世紀建造、如今已顯得破舊不堪的老聖伯多祿大殿前。",
      "對儒略二世而言,這座古老的教堂不僅僅是一座建築,更是天主教會最神聖的象徵,因為天主教會聖傳記載著,耶穌十二宗徒之長、同時也是首任羅馬主教的聖伯多祿,其遺骨就安葬於這片土地之下。",
      "為了守護這份神聖的遺產,並展現天主教會的權威與榮光,儒略二世做出了一個驚世駭俗的決定——拆毀這座千年古堂,在原址上重建一座前所未見的雄偉聖殿。",
    ],
    quote:{ q:"拆毀,是為了一場橫跨百年的重生。", by:"—— 聖伯多祿大殿" },
    footer:"梵蒂岡 · VATICAN",
    audio:true,
  };

  const TIMELINE = [
    { date:"5月 17", time:"08:51", title:"廊子公園",
      text:"漫步廊子公園,目光總會被眼前這幾株雄偉的老榕樹吸引。它們枝繁葉茂,氣根盤結,彷彿一位位歷經滄桑的長者,靜默地守護著這片土地。然而,這些老榕樹並……" },
    { date:"5月 16", time:"09:50", title:"彰化泰京山莊四面佛寺", img:"assets/img/temple.jpg",
      text:"彰化泰京山莊四面佛寺的故事,要從一位平凡的蚵仔麵線小販說起。那是在民國七十四年(1985年)左右,林逢永先生跟團遠赴泰國旅遊,走進了曼谷香火鼎盛的……" },
    { date:"5月 12", time:"17:24", title:"南觀音山",
      text:"南觀音山的稜線在暮色中起伏,像一道凝固的浪。早年採石的痕跡仍鐫刻在山腹,如今卻被綠意慢慢縫合,成為城市邊緣一處被重新看見的野地……" },
  ];

  const TRIPS = [
    { id:"uncat", name:"未分類", count:"4 筆記錄", style:"plain" },
    { id:"oc2026", name:"2026奧捷", range:"2026/4/1 – 2026/4/9", count:"18 筆記錄", style:"clay",
      dateLabel:"2026年4月1日 – 2026年4月9日",
      items:[
        { date:"4月 9", time:"10:09", title:"克拉姆-葛拉斯宮",
          addr:"Husova 158/20, Staré Město, 110 00 Praha-Praha 1, 捷克",
          text:"各位貴賓,現在我們正站在克拉姆-葛拉斯宮前,這座氣勢恢宏的建築,不僅是布拉格巴洛克建築的瑰寶,更是一段段引人入勝的人類故事的載體。它的歷史遠不止……" },
        { date:"4月 8", time:"09:13", title:"Fountain and statue of Saint George, Prague Castle",
          addr:"Třetí nádvoří Pražského hradu, 119 00 Praha 1-Hradčany, 捷克",
          text:"漫步在這布拉格城堡的第三庭院,您眼前這座聖喬治噴泉與雕像,不僅僅是石與水的結合,更是布拉格千年歷史與信仰的縮影。它的存在,訴說著一段又一段關於……" },
      ] },
  ];

  const PLANS = [
    { id:"week",  name:"每週方案", price:"$30.00",  per:"/ 週" },
    { id:"month", name:"每月方案", price:"$150.00", per:"/ 月" },
    { id:"year",  name:"每年方案", price:"$690.00", per:"/ 年", badge:"最划算",
      feats:["無限次數使用導覽","無廣告體驗","路線規劃功能"], fine:"每年自動續訂,可隨時取消" },
  ];

  function genStory(p){
    return {
      id:"gen-"+p.id, place:p.name, img:p.img, glyph:p.glyph, cat:p.cat,
      date:"2026年5月30日", chapter:"Anno · I", latin:p.latin,
      title:"城市邊緣的綠色記憶", sub:p.name, dropcap:"沿",
      body:[
        "著步道緩緩深入,"+p.name+"在喧囂的城市邊緣闢出一方靜土。陽光穿過層層枝葉,在地面灑落斑駁的光影,空氣裡滿是草木與濕潤泥土的氣息。",
        "這片綠地的故事,往往藏在不起眼的角落——一株被刻意保留的老樹、一道整治過的河岸,或一座承載了幾代人童年的遊具。它們默默見證著,土地如何在開發與守護之間,慢慢尋得平衡。",
        "如今的"+p.name+",是居民散步、孩童嬉戲、旅人駐足的所在。它溫柔地提醒著我們:最動人的風景,有時就在離家不遠的地方。",
      ],
      quote:{ q:"最動人的風景,有時就在離家不遠的地方。", by:"—— "+p.name },
      footer:(p.latin||"").split(" · ")[0] || p.name,
    };
  }

  window.LS_DATA = { CAT, PLACES, STORY_OPTIONS, STORIES, STPETERS_STORY, TIMELINE, TRIPS, PLANS, genStory };
})();
