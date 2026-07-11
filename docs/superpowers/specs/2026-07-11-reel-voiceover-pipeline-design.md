# Reel 語音旁白 pipeline 產品化設計

日期：2026-07-11
狀態：設計已核可，待實作

## 背景

每日故事 reel 由 `marketing/tools/reel-remotion/`（Remotion Cinematic）
在本地渲染。近期已在 `Beat` 型別加了 `durationFrames?` 覆寫欄位
（commit `377edf1e`），設計意圖是「語音旁白 pipeline 用實測 TTS 長度
回寫此值，讓各 beat 畫面拉長到旁白唸得完，逐 beat 同步」——但把
「TTS → 測長 → 回寫 durationFrames → 組對齊 voice.wav → 重渲染 → 混音」
串起來的膠水**從未被提交**。2026-07-11 富士山那支 reel 的語音是靠
scratchpad 的一次性腳本完成的。

本設計把那條一次性 pipeline 產品化成 repo 內的正式指令。

## 目標

- 一句指令產出「帶 zh-TW 語音旁白、逐 beat 同步」的 reel `final.mp4`。
- 重用既有 TTS（`scripts/daily_video_post.py` 的 Gemini/`say` 引擎、
  key fallback、空回應重試），不重造。
- 尊重 Gemini 免費層 **10 req/day/key** 的配額：逐拍快取，改一句只重唸一句。
- `build_video.sh`（音樂版 `cinematic.mp4` 路徑）維持不變。

## 非目標

- 不支援 Cinematic 以外的 style（`--style Editorial|Collage|Focus` 是 one-off）。
  對齊常數依 Cinematic 的 `TRANSITION=18` 寫死。
- 不做逐字（word-level）字幕對齊；同步是逐 beat（畫面時長 ≥ 該拍語音）。
- 不碰發布 / 上傳流程（`upload_reel_to_vps.sh` 仍照舊）。

## 介面

新增 `scripts/reel_voiceover.py`（`python -m reel_voiceover` 可執行模組）：

```bash
cd scripts && uv run python -m reel_voiceover <YYYY-MM-DD> \
   [--engine gemini|say] [--voice Despina] [--style "..."] [--force-tts]
```

一句跑完五步（見資料流）。旗標語意與 `daily_video_post` 一致：
- `--engine`：預設 `gemini`（免費層吃配額）；`say` 走離線 Meijia、不吃配額。
- `--voice` / `--style`：透傳給 TTS 引擎，預設同 `daily_video_post`
  （`Despina` / 溫暖稍快紀錄片語氣）。
- `--force-tts`：忽略快取，全部重唸。

## 資料流

```
story.json（每拍 narration + lines + durationFrames）
 │ 1. 逐拍：讀 beat.narration → TTS → beat_<id>.wav；ffprobe 量長度 d_i
 │        （快取命中則跳過，見「TTS 配額」）
 │ 2. durationFrames_i = max(文字推導預設, ceil(d_i·FPS)+LEAD+TAIL)
 │        → 回寫 story.json 每拍的 durationFrames
 │ 3. 依 durationFrames + TRANSITION 算每拍起始幀，
 │        用 adelay+amix 組出整段對齊的 voice.wav（全片長）
 │ 4. subprocess：build_video.sh <date> --lufs -28
 │        （重渲染 Cinematic + 安靜 BGM 底）→ cinematic.mp4
 │ 5. ffmpeg：voice loudnorm I=-16 → sidechaincompress ducking
 │        → amix(voice, ducked-BGM) → final.mp4
 ▼
marketing/outputs/daily_video/<date>/{final.mp4, voice.wav}
```

### 對齊細節

- `FPS=30`、`TRANSITION=18`、`LEAD=20`、`TAIL=18`（frames）。
  `TRANSITION` 註明對應 `src/styles/Cinematic.tsx` 的 `TRANSITION` 常數。
- 文字推導預設 = 複製 `story.ts` 的 `beatFrames` 邏輯
  （cover=140、ending=150、其它 `max(116,min(170,66+27·非空行數))`），
  取 `max()` 確保「畫面至少讓文字讀得完」也「至少讓語音唸得完」。
- 第 i 拍視覺起始幀 `start_i = cumsum(durationFrames)[<i] − i·TRANSITION`
  （TransitionSeries 每個轉場把後續 sequence 前拉 `TRANSITION` 幀）。
- 該拍語音在 `voice.wav` 的延遲 = `(start_i + LEAD)/FPS` 秒
  （LEAD 對齊 Cinematic 首行 reveal 的 `delay=22` 起點附近）。
- `voice.wav` 用 `adelay`（逐拍前置靜音）+ `amix(normalize=0)` +
  `apad,atrim=0:總長` 組出全片長單軌；各拍不重疊（durationFrames 已含 pad）。

### 混音（第 5 步 ffmpeg filter）

```
[1:a]loudnorm=I=-16:TP=-1.5:LRA=11,aresample=48000[vtmp];
[vtmp]asplit=2[v1][v2];
[0:a][v1]sidechaincompress=threshold=0.03:ratio=8:attack=5:release=300[bgd];
[bgd][v2]amix=inputs=2:normalize=0:duration=first[a]
```
`[0:a]` = cinematic.mp4 的 −28 LUFS BGM；語音出現時 sidechain 壓下 BGM。

## TTS 配額與快取

- Gemini 免費層 10 req/day/key；一支 reel 7 拍＝7 次。
- **逐拍快取**：在輸出資料夾存 `voice_cache.json`
  （`{beat_id: sha256(narration_text)}`）與 `beat_<id>.wav`。
  跑 TTS 前，若某拍 hash 未變且 wav 仍在 → 跳過該拍。
- 沿用 `daily_video_post` 的 key1→`GEMINI_API_KEY_2` fallback 與
  空回應重試（透過重用 `_GeminiSynth` / `_make_synth`）。
- `--force-tts` 清快取全部重唸；`--engine say` 完全不吃配額。

## 檔案變更清單

| 檔案 | 變更 |
|---|---|
| `scripts/reel_voiceover.py` | 新增：編排器（TTS＋durationFrames＋voice.wav＋render＋mux） |
| `marketing/tools/reel-remotion/src/types.ts` | `Beat` 加 `narration?: string` |
| `marketing/tools/reel-remotion/scripts/prepare_story.mjs` | scaffold 時每拍種 `narration`（預設＝非空 lines 串接草稿） |
| `.claude/skills/lorescape-daily-reel/SKILL.md` | 把「加語音」步驟改寫成正式指令；文案規則加「每拍寫 narration 口說版」 |

`build_video.sh`、`src/data/story.ts` 不改。

## 邊界情況

- 某拍 `narration` 為空 → 該拍不產語音（voice.wav 該段留白），
  `durationFrames` 退回文字推導值，不報錯。
- 整份都沒 `narration`（舊資料）→ 等同無語音；提示使用者先補 narration
  或直接用 `build_video.sh` 音樂版。
- `final.mp4` > Discord 9.5MB → 由發布 bot 產 720p 預覽（現狀，不處理）。
- TTS 全數配額用罄且無 `--engine say` → 沿用 `daily_video_post` 的
  `PostProductionError` 明確報錯（含「等台北 15:00 重置」訊息）。

## 測試 / 驗收

- `--engine say` 端到端跑一天（不吃配額）：產出 `final.mp4`，
  時長＝story.ts `totalFrames` 換算、音軌非靜音、無爆音（max < 0 dB）。
- 快取：不改 narration 二次執行 → 不發任何 TTS 請求（log 顯示全 skip）。
- 改一拍 narration → 只該拍重唸，其餘 skip。
- `durationFrames` 回寫後，`totalFrames(18)` 與 `voice.wav` 長度一致
  （±1 幀）。
