# Reel 縮短長度 + 零秒 Hook Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 讓每日 reel 目標長度收到 20–30 秒，並在 cover 第一幀就以拋問句抓住觀眾（零秒 hook），同時確保縮短後片尾下載 CTA 仍讀得完。

**Architecture:** 三處協同：(1) `lorescape-daily-reel` skill 的 Step 2 文案規則改為挑 5–6 拍、精煉旁白、寫 cover hook 句；(2) `Cinematic.tsx` 的 cover layout 讓 `lines[0]` 成為最大、最早出現的 hook，地區/地名降級小字；(3) ending 拍設最短停留下限，讓 CTA 不被短旁白切掉——下限需同步寫進 `reel_voiceover.py`（建 voice.wav 時間軸的一方）與 `story.ts`（music-only 路徑），兩者是刻意保持鏡像的一組。

**Tech Stack:** Remotion（React/TS）、Python（reel_voiceover，uv + pytest）、ffmpeg/ffprobe。

## Global Constraints

- 目標 reel 長度 **20–30 秒**（積極）；不設硬性程式上限，靠旁白長度自然收斂。
- Hook 形式固定為**零秒拋問句**：cover `lines[0]` 一句講完反轉/懸念，render 時最大、最先淡入；`kicker`（地區）與 `subtitle`（英文名）降為小字後置。
- 範圍**只改 pipeline**；**不重做** 2026-07-13 已送審的 `marketing/outputs/daily_video/2026-07-13/final.mp4`（103 秒版）。驗證用的 render 一律寫到 scratch 路徑，不得覆蓋 `daily_video/2026-07-13/`。
- `reel_voiceover.py` 的 `text_default_frames()` 是 `story.ts` `beatFrames()` 的手工 port，兩者的 ending 下限與 cover/beat 值必須**保持一致**。
- FPS = 30；`TRANSITION = 18`；CTA 淡入時序在 `Cinematic.tsx` 為 `delay = 22 + revealCount*7 + 18`（frames）。
- carousel（wander 9 拍）、`prepare_story.mjs` scaffold 行為**不動**（仍輸出全 9 拍，由 Claude 在 Step 2 挑子集）。

---

### Task 1: Ending 拍最短停留下限（CTA 不被切）

在 `reel_voiceover.py`（建 voice.wav 時間軸）與 `story.ts`（music-only）兩邊，把 ending 拍的 text-default 從 150/195 提高到共同常數 `ENDING_MIN_FRAMES = 210`（7 秒），確保即使 ending 旁白很短，CTA 也有足夠停留。因 `duration_frames = max(text_default, voice)`，旁白長時仍以旁白為準、音畫同步不變。

**Files:**
- Modify: `scripts/reel_voiceover.py:38-46`（`text_default_frames`）
- Modify: `scripts/tests/test_reel_voiceover.py:12-14`（既有斷言 150 → 210）
- Modify: `marketing/tools/reel-remotion/src/data/story.ts:19-25`（`beatFrames` ending 下限）

**Interfaces:**
- Produces: 常數 `ENDING_MIN_FRAMES = 210`（兩檔各自定義、值相同）；`text_default_frames({"layout":"ending",...}) == 210`；`beatFrames({layout:"ending"})` ≥ 210，即使帶 `durationFrames` 也套下限。

- [ ] **Step 1: 改既有 pytest 斷言為新下限（先讓它失敗）**

`scripts/tests/test_reel_voiceover.py:12-14` 改成：

```python
def test_text_default_frames_cover_and_ending():
    assert rv.text_default_frames({"layout": "cover", "lines": ["a", "b"]}) == 140
    assert rv.text_default_frames({"layout": "ending", "lines": ["a"]}) == 210
```

新增一個確認「帶短 voice 時 ending 仍守住下限」的測試（接在同函式後）：

```python
def test_ending_holds_floor_even_with_short_voice():
    # 3 秒旁白 → ceil(3*30)+LEAD+TAIL 遠小於 210，ending 應守住 210
    assert rv.duration_frames(rv.text_default_frames({"layout": "ending", "lines": ["a"]}), 3.0) == 210
```

- [ ] **Step 2: 跑測試確認失敗**

Run: `cd scripts && uv run python -m pytest tests/test_reel_voiceover.py -k "ending or cover_and_ending" -v`
Expected: FAIL（目前 ending 回 150，斷言期望 210）

- [ ] **Step 3: 在 reel_voiceover.py 加常數並套用下限**

`scripts/reel_voiceover.py`：在檔案上方常數區（`FPS = 30` 附近）加：

```python
ENDING_MIN_FRAMES = 210  # ending 拍最短停留，確保片尾下載 CTA 淡入後讀得完
```

把 `text_default_frames`（38-46 行）ending 分支改為：

```python
def text_default_frames(beat: dict) -> int:
    """Port of story.ts beatFrames() — text-derived on-screen duration."""
    layout = beat.get("layout")
    if layout == "cover":
        return 140
    if layout == "ending":
        return ENDING_MIN_FRAMES
    nonempty = len([l for l in beat.get("lines", []) if l != ""])
    return max(116, min(170, 66 + 27 * nonempty))
```

- [ ] **Step 4: 跑測試確認通過**

Run: `cd scripts && uv run python -m pytest tests/test_reel_voiceover.py -v`
Expected: PASS（全部）

- [ ] **Step 5: 鏡像到 story.ts 的 beatFrames**

`marketing/tools/reel-remotion/src/data/story.ts`：把 `beatFrames`（19-25 行）改成——ending 下限即使已帶 `durationFrames` 也要套用（故不能走最前面的 early return）：

```typescript
export const ENDING_MIN_FRAMES = 210;

export const beatFrames = (beat: Beat): number => {
  // Ending holds ≥ ENDING_MIN_FRAMES so the burned-in download CTA has time to
  // fade in and stay readable, even when its narration is short. Applied even
  // when durationFrames is set, so it survives the voiceover pipeline's rewrite.
  if (beat.layout === "ending") {
    return Math.max(beat.durationFrames ?? ENDING_MIN_FRAMES, ENDING_MIN_FRAMES);
  }
  if (typeof beat.durationFrames === "number") return beat.durationFrames;
  if (beat.layout === "cover") return 140;
  const byText = 66 + 27 * nonEmptyLines(beat);
  return Math.max(116, Math.min(170, byText));
};
```

- [ ] **Step 6: 型別檢查**

Run: `cd marketing/tools/reel-remotion && npm run ensure-story --silent && npx tsc --noEmit`
Expected: 無錯誤輸出（exit 0）

- [ ] **Step 7: Commit**

```bash
git add scripts/reel_voiceover.py scripts/tests/test_reel_voiceover.py marketing/tools/reel-remotion/src/data/story.ts
git commit -m "feat(reel): ending 拍設 210f 最短停留，確保片尾 CTA 讀得完"
```

---

### Task 2: Cover 零秒 Hook 版面

`Cinematic.tsx` 的 cover layout 目前是 kicker(小) → title(128px 大) → lines。改成：cover 時 `lines[0]` 成為最大、最早淡入的 hook；其餘 `lines` 中字級接續；`kicker`（地區）與 `title`（地名中文）+ `subtitle`（英文名）降成小字、排在 hook 之後。beat / bright / ending 版面不動。

**Files:**
- Modify: `marketing/tools/reel-remotion/src/styles/Cinematic.tsx:50-107`（BeatScene 的文字區塊）

**Interfaces:**
- Consumes: `beat.lines`（cover `lines[0]` = hook 句）、`beat.kicker`、`beat.title`、`beat.subtitle`、`beat.highlights`、`Reveal`、`HighlightedLine`、`serifFamily`、`sansFamily`、`HIGHLIGHT`（皆已 import）。
- Produces: cover 首幀即見 hook 大字；非 cover 版面與現狀一致。

- [ ] **Step 1: 把文字區塊拆成 cover 分支與其餘分支**

`Cinematic.tsx` 的 50-107 行（`<div>` 內從 kicker 的 `<Reveal>` 到 lines.map 結束）整段替換成下面內容（保留外層 `<div>` 與其後的 `{isEnding ? ... }` 區塊不動）：

```tsx
        <div>
          {isCover ? (
            <>
              {/* Zero-second hook: the first line, largest, first to appear. */}
              <Reveal delay={6} fromY={18}>
                <div
                  style={{
                    fontFamily: serifFamily,
                    fontWeight: 800,
                    fontSize: 78,
                    lineHeight: 1.35,
                    color: "#fff",
                    textShadow: "0 4px 30px rgba(0,0,0,0.65)",
                    marginBottom: 26,
                  }}
                >
                  <HighlightedLine
                    line={beat.lines[0] ?? ""}
                    highlights={beat.highlights}
                    highlightColor={HIGHLIGHT}
                    highlightStyle="color"
                  />
                </div>
              </Reveal>
              {beat.lines.slice(1).map((line, i) => {
                if (line === "") return <div key={i} style={{ height: 18 }} />;
                const delay = 18 + revealCount * 7;
                revealCount += 1;
                return (
                  <Reveal key={i} delay={delay} fromY={18}>
                    <div
                      style={{
                        fontFamily: serifFamily,
                        fontWeight: 700,
                        fontSize: 46,
                        lineHeight: 1.5,
                        color: "#f5f1e9",
                        textShadow: "0 2px 22px rgba(0,0,0,0.8)",
                      }}
                    >
                      <HighlightedLine
                        line={line}
                        highlights={beat.highlights}
                        highlightColor={HIGHLIGHT}
                        highlightStyle="color"
                      />
                    </div>
                  </Reveal>
                );
              })}
              {/* Demoted place tag: region + place name, small, after the hook. */}
              <Reveal delay={18 + revealCount * 7 + 8} fromY={12}>
                <div style={{ marginTop: 34 }}>
                  <div
                    style={{
                      fontFamily: sansFamily,
                      fontWeight: 500,
                      letterSpacing: "0.35em",
                      fontSize: 26,
                      color: HIGHLIGHT,
                      marginBottom: 10,
                    }}
                  >
                    {beat.kicker}
                  </div>
                  <div
                    style={{
                      fontFamily: serifFamily,
                      fontWeight: 900,
                      fontSize: 46,
                      lineHeight: 1.1,
                      color: "#fff",
                      textShadow: "0 4px 30px rgba(0,0,0,0.6)",
                    }}
                  >
                    {beat.title}
                    {beat.subtitle ? (
                      <span
                        style={{
                          fontFamily: sansFamily,
                          fontWeight: 400,
                          fontSize: 26,
                          letterSpacing: "0.08em",
                          color: "rgba(245,241,233,0.7)",
                          marginLeft: 16,
                        }}
                      >
                        {beat.subtitle}
                      </span>
                    ) : null}
                  </div>
                </div>
              </Reveal>
            </>
          ) : (
            <>
              <Reveal delay={6}>
                <div
                  style={{
                    fontFamily: sansFamily,
                    fontWeight: 500,
                    letterSpacing: "0.35em",
                    fontSize: 29,
                    color: HIGHLIGHT,
                    marginBottom: 22,
                  }}
                >
                  {beat.kicker}
                </div>
              </Reveal>
              {beat.title ? (
                <Reveal delay={12}>
                  <div
                    style={{
                      fontFamily: serifFamily,
                      fontWeight: 900,
                      fontSize: 74,
                      lineHeight: 1.1,
                      color: "#fff",
                      marginBottom: 30,
                      textShadow: "0 4px 30px rgba(0,0,0,0.6)",
                    }}
                  >
                    {beat.title}
                  </div>
                </Reveal>
              ) : null}
              {beat.lines.map((line, i) => {
                if (line === "") return <div key={i} style={{ height: 20 }} />;
                const delay = 22 + revealCount * 7;
                revealCount += 1;
                return (
                  <Reveal key={i} delay={delay} fromY={18}>
                    <div
                      style={{
                        fontFamily: serifFamily,
                        fontWeight: 700,
                        fontSize: 50,
                        lineHeight: 1.5,
                        color: "#f5f1e9",
                        textShadow: "0 2px 22px rgba(0,0,0,0.8)",
                      }}
                    >
                      <HighlightedLine
                        line={line}
                        highlights={beat.highlights}
                        highlightColor={HIGHLIGHT}
                        highlightStyle="color"
                      />
                    </div>
                  </Reveal>
                );
              })}
            </>
          )}
```

註：非 cover 分支的 `fontSize: isCover ? 128 : 74` 因已進 else 分支，直接寫死 `74`。

- [ ] **Step 2: 型別檢查**

Run: `cd marketing/tools/reel-remotion && npx tsc --noEmit`
Expected: 無錯誤（exit 0）

- [ ] **Step 3: 準備一個帶 hook 句的 cover 測試素材並渲染首幀**

用現成的 07-13 story.json（已有泰姬瑪哈陵 cover），把 cover `lines[0]` 暫時設成 hook 句以驗證版面。渲染 cover 中段一幀到 scratch（**不碰 daily_video**）：

```bash
cd marketing/tools/reel-remotion && npm run ensure-story --silent
npx remotion still Cinematic \
  "/private/tmp/claude-501/-Users-paulwu-Documents-PLRepo-instant-explore/f4a65546-c11c-4dcb-8e54-63474eb4dbfa/scratchpad/cover_hook_check.png" \
  --frame=60
```

Expected: 指令成功、輸出 png 路徑。

- [ ] **Step 4: 目視確認零秒 hook**

用 Read 開啟 `cover_hook_check.png`，確認：hook 句（lines[0]）是畫面最大、最上方的文字；地區標籤與地名為其下小字。若比例不對，微調字級後重渲染。

- [ ] **Step 5: Commit**

```bash
git add marketing/tools/reel-remotion/src/styles/Cinematic.tsx
git commit -m "feat(reel): cover 改零秒 hook 版面（拋問句最大最先，地名降級）"
```

---

### Task 3: skill Step 2 文案規則（長度 + 挑拍 + hook）

改 `lorescape-daily-reel` skill 的 Step 2，指示 Claude：目標 20–30 秒、從 9 拍挑 5–6 拍、每拍一句短 clause、cover 寫零秒拋問句放 `lines[0]`。

**Files:**
- Modify: `.claude/skills/lorescape-daily-reel/SKILL.md:67-83`（Step 2 段落）

**Interfaces:**
- Produces: 純文件；無程式介面。

- [ ] **Step 1: 改寫 Step 2 段落**

把 `.claude/skills/lorescape-daily-reel/SKILL.md` 的 67-83 行替換成：

```markdown
### Step 2 — condensing narration（目標 20–30 秒，do NOT skip）

`prepare_story.mjs` 會把 carousel 全 9 拍的完整 lines 搬進來——那對 reel
太長（實測會到 60–100 秒，壓低完播與觸及）。目標是**成片 20–30 秒**。
編輯 `src/data/story.json`：

- **挑拍**：只留 **hook cover ＋ 3–4 個最強拍 ＋ ending**（合計 5–6 拍），
  其餘整拍刪掉。保留反轉/懸念/彩蛋，丟掉鋪陳與次要細節。（carousel 仍是
  9 拍，reel 用子集不影響圖組。）
- **零秒 hook（cover）**：cover 的 `lines[0]` 寫成一句話講完反轉/懸念的
  **拋問句或反轉句**（例：「全世界最著名的建築，其實是一座墳墓。」）。
  render 會讓 `lines[0]` 第一幀就以最大字級出現，地區/地名自動降為小字，
  所以 hook 句要能獨立抓住人、別依賴標題。cover `lines` 儘量只留 hook 句
  ＋最多一句補充。
- **每拍精煉**：非 cover 拍收成 **1–2 句短 clause**（口說唸完約 3–4 秒），
  不要複句。
- 每個 `highlights` 必須是某句 `lines` 的**精確子字串**，否則不會highlight。
- `narration`（口說旁白）每拍填一句，比畫面 `lines` 完整一點即可；
  `reel_voiceover` 會逐拍 TTS、用實測長度回寫 `durationFrames`。因此
  **寫短旁白＝片子自然短**，不需另設上限。
- 算下來若仍超過 ~35 秒（beats × 各拍旁白秒數相加），再砍一拍或縮句。
- ending 拍會自動保留 ≥7 秒讓片尾下載 CTA 讀得完（`ENDING_MIN_FRAMES`），
  ending 旁白寫 1–2 句收尾即可，不用硬撐長度。
```

- [ ] **Step 2: Commit**

```bash
git add .claude/skills/lorescape-daily-reel/SKILL.md
git commit -m "docs(skill): daily-reel Step 2 改目標 20-30s + 挑拍 + 零秒 hook 規則"
```

---

### Task 4: 端到端驗證（scratch 短片，不覆蓋今天）

用 07-13 素材依新規則手動濃縮成 5–6 拍短故事，渲染到 scratch 路徑，量長度、看 hook 與 CTA。**不得寫入 `daily_video/2026-07-13/`。**

**Files:**
- Test only（scratch 輸出，不進版控）

**Interfaces:**
- Consumes: Task 1–3 的成果、既有 `src/data/story.json`（07-13）。

- [ ] **Step 1: 依新規則濃縮出測試 story.json**

保留現有 07-13 story.json，手動精簡成 5–6 拍（cover 用拋問句 hook 句放 `lines[0]` ＋ 3–4 拍 ＋ ending），每拍 `lines` 1–2 短句、`narration` 一句，其餘拍整個刪除。存回 `src/data/story.json`。

- [ ] **Step 2: 渲染 music-only cinematic 到 scratch 並量長度**

```bash
cd marketing/tools/reel-remotion && npm run ensure-story --silent
SCRATCH="/private/tmp/claude-501/-Users-paulwu-Documents-PLRepo-instant-explore/f4a65546-c11c-4dcb-8e54-63474eb4dbfa/scratchpad/reel_len_check.mp4"
npx remotion render Cinematic "$SCRATCH"
ffprobe -v error -show_entries format=duration -of csv=p=0 "$SCRATCH"
```

Expected: 長度落在 **20–30 秒**（music-only 版；加旁白後每拍以 `max(text,voice)` 撐長，故語音版會略長，但拍數已砍，仍應明顯短於舊 60–100 秒）。若超過，回 Step 1 再砍拍/縮句。

- [ ] **Step 3: 抽首幀確認零秒 hook + 抽尾幀確認 CTA**

```bash
SCR="/private/tmp/claude-501/-Users-paulwu-Documents-PLRepo-instant-explore/f4a65546-c11c-4dcb-8e54-63474eb4dbfa/scratchpad"
ffmpeg -y -v error -ss 1.5 -i "$SCR/reel_len_check.mp4" -frames:v 1 "$SCR/reel_hook_frame.png"
ffmpeg -y -v error -sseof -1.5 -i "$SCR/reel_len_check.mp4" -frames:v 1 "$SCR/reel_cta_frame.png"
```

用 Read 開兩張圖：首幀 hook 句最大最上；尾幀 CTA（lockup ＋「更多景點故事，下載 Lorescape」＋商店行）完整可讀。

- [ ] **Step 4: 還原 story.json（避免留下測試殘留）**

story.json 是 gitignored 工作檔（見 F12）；確認 `git status` 不含它即可，無需還原。確認未產生 `daily_video/2026-07-13/` 的任何新檔：

Run: `git status --short && ls marketing/outputs/daily_video/2026-07-13/`
Expected: 無 story.json 出現在 git status；daily_video/2026-07-13/ 內容與改動前一致（final.mp4 仍是原 103s 版）。

- [ ] **Step 5: 驗證總結**

把三項結果（成片秒數、hook 首幀、CTA 尾幀）回報，確認符合 spec 驗證條件。真正的成效驗證（略過率/views vs 舊片）於明日起正式 reel 累積一週後，用同 checkpoint 對比。
