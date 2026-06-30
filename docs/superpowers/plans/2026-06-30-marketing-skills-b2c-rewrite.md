# Lorescape 行銷 skill 套件改寫 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把 47 個壞掉的 `kai-*` 行銷 skill 收斂成 15 個自包含、B2C、接上真實 pipeline 的 `marketing-*` skill。

**Architecture:** 刪除 32 個不適用的 skill;保留的 15 個逐一改名 `kai-X`→`marketing-X`,移除 Windows 路徑與 python 腳本依賴,改用內文 checklist 與專案根目錄 `MARKETING.md` 作共用脈絡,並把資料來源接到 lorescape-metrics / daily-story / publish-reel。先改 `marketing-gate`(共用品質基準),其餘內容類 skill 引用它。

**Tech Stack:** Markdown skill 檔(`.claude/skills/<name>/SKILL.md`)、git、grep 驗證。設計來源:`docs/superpowers/specs/2026-06-30-marketing-skills-b2c-rewrite-design.md`。

## Global Constraints

- 命名前綴一律 `marketing-`;每個 `SKILL.md` 的 `name:` frontmatter 必須等於目錄名。
- 改寫後檔案內**不得**出現:`E:\`、`kai-cmo-harness`、`/kai-`、`python .*scripts/quality_gates`、`data/learning/`。
- 共用產品/品牌脈絡一律指向專案根目錄 `MARKETING.md`,不得引用外部 playbook/persona 檔。
- 內容類 skill 的品質檢查一律引用 `marketing-gate`,不得呼叫 python 腳本。
- B2C 語境:用 App 使用者(非公司)、App Store / Google Play、RevenueCat 訂閱、IG/ASO 通路;套用 MARKETING.md 品牌語氣(沉靜知性、第二人稱「你」、emoji ≤3、禁誇張行銷語)。
- description 觸發詞同時保留繁體中文與英文。
- 已在分支 `chore/marketing-skills-b2c-rewrite`;每個 Task 結束 commit,最後開 PR。
- 真實接線常數:`METRICS_SHEET_ID`、`GA4_PROPERTY_ID_APP`、`GA4_PROPERTY_ID_WEB`(在 `scripts/.env`);metrics 流程見 `.claude/skills/lorescape-metrics` 與 `docs/init/metrics-setup.md`;landing 文案 `landing/src/i18n/dictionaries.ts`;daily-story → reel 流程見 `.claude/skills/lorescape-manual-daily-story` 與 `.claude/skills/publish-reel`。

### 共用驗證指令(多個 Task 會用到,代稱 VERIFY)

```bash
# 在 repo 根目錄執行。應無任何輸出(全部通過)。
grep -rIn -e 'E:\\' -e 'kai-cmo-harness' -e '/kai-' -e 'scripts/quality_gates' -e 'data/learning/' .claude/skills/marketing-* ;
for d in .claude/skills/marketing-*/ ; do n=$(basename "$d"); grep -q "^name: $n$" "$d/SKILL.md" || echo "FRONTMATTER MISMATCH: $d"; done
```

---

### Task 1: 刪除 34 個不適用的 skill

實際 kai-cmo 目錄共 49 個:47 個 `kai-*` + `kai`(router)+ `kaicalls-design`(無 kai- 前綴的獨立目錄)。保留 15 個 → 刪除 34 個。`kai-audit`(全通路審計,與 monthly-audit 重疊且含 ads/email)與 `kai-brief`(餵給已刪的 write/email-system)亦在刪除之列。

**Files:**
- Delete(32 個 `kai-*`):`.claude/skills/kai-{abm,ad-campaign,audit,brand-pulse,brief,budget,case-study,cold-outreach,daily-ad-review,data-dashboard,email-system,growth-hacker,html-presentation,influencer,newsletter,partnership,podcast,product-maker,reddit-listen,retarget,retro,sales-meeting-prep,sdr-operator,sdr-reply-triage,start,surround-sound,taste,topical-map,video,video-production,webinar,write}`
- Delete: `.claude/skills/kai`(router)
- Delete: `.claude/skills/kaicalls-design`

**Interfaces:**
- Produces:刪除後 `.claude/skills/` 只剩 15 個 `kai-*`(待改名)與既有 `lorescape-*` 等 skill;無 `kai` router、無 `kaicalls-design`。

- [ ] **Step 1: 確認刪除前的總數**

```bash
cd /Users/paulwu/Documents/Github/instant_explore
ls -d .claude/skills/kai-* .claude/skills/kai .claude/skills/kaicalls-design 2>/dev/null | wc -l   # 預期 49
```
Expected: `49`

- [ ] **Step 2: 刪除 34 個目錄**

```bash
cd /Users/paulwu/Documents/Github/instant_explore/.claude/skills
git rm -r kai-abm kai-ad-campaign kai-audit kai-brand-pulse kai-brief kai-budget \
  kai-case-study kai-cold-outreach kai-daily-ad-review kai-data-dashboard \
  kai-email-system kai-growth-hacker kai-html-presentation kai-influencer \
  kai-newsletter kai-partnership kai-podcast kai-product-maker kai-reddit-listen \
  kai-retarget kai-retro kai-sales-meeting-prep kai-sdr-operator kai-sdr-reply-triage \
  kai-start kai-surround-sound kai-taste kai-topical-map kai-video kai-video-production \
  kai-webinar kai-write kai kaicalls-design
```

- [ ] **Step 3: 驗證只剩 15 個保留項**

```bash
cd /Users/paulwu/Documents/Github/instant_explore
ls -d .claude/skills/kai-* | sort
ls -d .claude/skills/kai-* | wc -l                                   # 預期 15
ls -d .claude/skills/kai .claude/skills/kaicalls-design 2>/dev/null | wc -l   # 預期 0
```
Expected: 15 個,正好是 brand · competitors · content-calendar · cro · gate · growth-plan · launch · landing-page · monthly-audit · analytics · repurpose · retention · seo-audit · social · weekly-audit;且 router/kaicalls-design 為 0

- [ ] **Step 4: Commit**

```bash
git commit -q -m "chore(skills): delete 34 non-B2C kai marketing skills

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: 補完 MARKETING.md 的 [TODO]

**Files:**
- Modify: `MARKETING.md`(專案根目錄)

**Interfaces:**
- Consumes:無。
- Produces:更完整的 `MARKETING.md`,作為後續所有 skill 的共用脈絡。

- [ ] **Step 1: 蒐集可推導的資料**

```bash
cd /Users/paulwu/Documents/Github/instant_explore
# 訂閱方案 / 價格線索
grep -rn "rc_weekly\|rc_monthly\|rc_annual\|Premium\|subscription" frontend/lib --include="*.dart" | head
# App Store / bundle id 線索
grep -rn "appstore\|apps.apple.com\|com.paulchwu" frontend/ios landing 2>/dev/null | head
```
記下找到的 App Store URL、價格;找不到的標為 `[需使用者確認]`。

- [ ] **Step 2: 填入可推導項,並為「僅使用者知道」項寫草稿**

編輯 `MARKETING.md`:
- `App Store:` → 填入找到的 iOS URL(找不到則保留 `[TODO]` 並在 Step 4 回報)。
- `Premium Weekly/Monthly/Yearly` 價格 → 填入找到的值,否則 `[需使用者確認]`。
- `Proof points:` → 寫一行說明「是否公開真實數字待使用者決定」,先放 `[需使用者確認:是否公開下載數/生成次數/轉換率]`。
- `Planned channels:` → 依現況提草稿:`YouTube Shorts、SEO 部落格(lorescape.app/blog)、TikTok 短影音、旅遊社群 KOL 合作`,標 `[草稿,待使用者確認]`。

- [ ] **Step 3: 驗證無殘留未標註的 TODO**

```bash
grep -n "TODO" MARKETING.md
```
Expected:剩下的 `TODO`/`[需使用者確認]` 都是已知、待使用者回覆的項目。

- [ ] **Step 4: Commit 並回報待確認項給使用者**

```bash
git add MARKETING.md
git commit -q -m "docs(marketing): fill derivable MARKETING.md TODOs, draft the rest

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```
在 commit 後,用一段話列出所有 `[需使用者確認]` 項請使用者回覆。

---

### Task 3: 改寫 marketing-gate(共用品質基準,必須最先做)

**Files:**
- Create: `.claude/skills/marketing-gate/SKILL.md`
- Delete: `.claude/skills/kai-gate/`

**Interfaces:**
- Produces:`marketing-gate` skill。後續內容類 skill 以「執行 marketing-gate 品質檢查」引用它。其輸出格式含 Four U's 分數、禁用字、AI slop、語氣 regex、SEO lint。

- [ ] **Step 1: 讀來源**

```bash
cat .claude/skills/kai-gate/SKILL.md
```

- [ ] **Step 2: 建立改寫後的 marketing-gate/SKILL.md**

以 `kai-gate` 內容為底,做這些更動:
- `name: kai-gate` → `name: marketing-gate`;description 開頭去掉 "Kai CMO Harness",改「Lorescape 內容品質檢查」,觸發詞補繁中(「品質檢查」「跑 gate」「禁用字檢查」「Four U 分數」)。
- 保留 Four U's 表(門檻 12/16 部落格/SEO、10/16 email/ad → 改為 12/16 部落格/SEO、10/16 社群/IG caption)。
- 保留禁用字 Tier 1 + AI slop 清單;另加一行:中文內容比照禁止誇張行銷語(「最強/最好/革命性」)與條目式堆砌,呼應 MARKETING.md Don't。
- 保留語氣 regex 表,標註「主要適用英文內容(landing en、IG en caption)」。
- 移除 `### 4. SEO Lint` 末尾對 `knowledge/frameworks/.../algorithmic-authorship.md` 的外部引用,把該 5 條規則直接列為內文清單(已有摘要,補成完整可獨立判讀)。
- 移除整段 `## Learning hook`(`data/learning/gate_runs.jsonl`、`/kai-retro`、`memory/lessons.md`)。
- `### 3. Voice Pattern Check` 的「Project hook integration」段:把 `.claude/hooks/voice-gate.py` 描述改為「若本專案有對應 hook 則一併觸發」,不假設存在。
- 保留 Output Format 區塊。

- [ ] **Step 3: 刪除舊目錄並驗證**

```bash
cd /Users/paulwu/Documents/Github/instant_explore
git rm -r .claude/skills/kai-gate
# VERIFY(見 Global Constraints)
grep -rIn -e 'E:\\' -e 'kai-cmo-harness' -e '/kai-' -e 'scripts/quality_gates' -e 'data/learning/' .claude/skills/marketing-gate ;
grep -q "^name: marketing-gate$" .claude/skills/marketing-gate/SKILL.md && echo "name OK"
```
Expected:第一個 grep 無輸出;印出 `name OK`。

- [ ] **Step 4: Commit**

```bash
git add .claude/skills/marketing-gate
git commit -q -m "feat(skills): rewrite kai-gate as self-contained marketing-gate

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 4: 內容批次 — social / content-calendar / repurpose

**Files:**
- Create: `.claude/skills/marketing-{social,content-calendar,repurpose}/SKILL.md`
- Delete: `.claude/skills/kai-{social,content-calendar,repurpose}/`

**Interfaces:**
- Consumes:`marketing-gate`(品質檢查)、`MARKETING.md`(品牌語氣)。
- Produces:3 個內容類 skill。

每個 skill 套用「改寫範本 7 步」(見 spec),本批次的 B2C 接線重點:

- **共通**:刪除所有 `E:\`/python 引用;產品脈絡改讀 `MARKETING.md`;發佈前一律「執行 marketing-gate」;通路主軸是 IG Reels,不是 LinkedIn/X 長文。
- **social**:把多平台 B2B 文案改為以 Instagram(貼文 + Reels)為主、輔以 App Store 行銷文案;明確指出 daily-story 已自動產製每日景點故事 reel(見 `lorescape-manual-daily-story` / `publish-reel`),social 著重「人工補充貼文 / caption / hashtag 策略」,不重造每日 pipeline。
- **content-calendar**:行事曆對齊 daily-story 每日節奏 + 每週景點故事系列;內容類型限 IG 貼文/Reels、SEO 部落格、App Store 更新文案;映射到 MARKETING.md 的 ICP 與計畫通路。
- **repurpose**:來源主內容預設為「一則 daily-story 景點故事」,拆成 IG carousel、Reels 腳本、部落格段落、App Store what's-new、hashtag 組;遵守 emoji ≤3、第二人稱「你」。

- [ ] **Step 1: 讀三個來源**
```bash
for s in social content-calendar repurpose; do echo "=== kai-$s ==="; cat .claude/skills/kai-$s/SKILL.md; done
```
- [ ] **Step 2: 建立 marketing-social/SKILL.md**(套用上述重點)
- [ ] **Step 3: 建立 marketing-content-calendar/SKILL.md**
- [ ] **Step 4: 建立 marketing-repurpose/SKILL.md**
- [ ] **Step 5: 刪除三個舊目錄並 VERIFY**
```bash
cd /Users/paulwu/Documents/Github/instant_explore
git rm -r .claude/skills/kai-social .claude/skills/kai-content-calendar .claude/skills/kai-repurpose
grep -rIn -e 'E:\\' -e 'kai-cmo-harness' -e '/kai-' -e 'scripts/quality_gates' -e 'data/learning/' .claude/skills/marketing-social .claude/skills/marketing-content-calendar .claude/skills/marketing-repurpose
for d in marketing-social marketing-content-calendar marketing-repurpose; do grep -q "^name: $d$" .claude/skills/$d/SKILL.md || echo "MISMATCH $d"; done
```
Expected:兩個檢查皆無輸出。
- [ ] **Step 6: Commit**
```bash
git add .claude/skills/marketing-social .claude/skills/marketing-content-calendar .claude/skills/marketing-repurpose
git commit -q -m "feat(skills): rewrite social/content-calendar/repurpose for B2C IG pipeline

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 5: 品牌/策略批次 — brand / competitors / growth-plan / launch

**Files:**
- Create: `.claude/skills/marketing-{brand,competitors,growth-plan,launch}/SKILL.md`
- Delete: `.claude/skills/kai-{brand,competitors,growth-plan,launch}/`

**Interfaces:**
- Consumes:`marketing-gate`、`MARKETING.md`。
- Produces:4 個策略類 skill。

B2C 接線重點:
- **brand**:Phase 0 已讀 MARKETING.md;移除三個 `E:\...` References 與 Phase 4 兩個 python 呼叫(改「執行 marketing-gate」);競品/差異化用 MARKETING.md 既有 Competitive Landscape;tagline 與定位語氣對齊品牌 Voice。
- **competitors**:對手換成 MARKETING.md 的 direct/indirect(Google Maps 語音導覽、Rick Steves、景點語音導覽、Wikipedia、Podcast 旅遊節目);battlecard 改為「App 對比」而非 SaaS 銷售 battlecard;移除 SDR/銷售用語。
- **growth-plan**:階段以「App 下載 / MAU / 訂閱數」分級(取代 MRR-only 的 B2B 階段);各階段建議聚焦 ASO、IG、SEO、KOL,明確排除廣告/SDR/cold email(因已刪該能力)。
- **launch**:把「協調其他 kai skill」的清單改為協調保留中的 `marketing-*`(landing-page、social、content-calendar、seo-audit),移除已刪的 ad/email/press 編排;launch 標的為「新功能 / App 改版 / 新市場語言」。

- [ ] **Step 1: 讀四個來源**
```bash
for s in brand competitors growth-plan launch; do echo "=== kai-$s ==="; cat .claude/skills/kai-$s/SKILL.md; done
```
- [ ] **Step 2-5: 逐一建立 marketing-brand / marketing-competitors / marketing-growth-plan / marketing-launch/SKILL.md**(套用上述重點)
- [ ] **Step 6: 刪除四個舊目錄並 VERIFY**
```bash
cd /Users/paulwu/Documents/Github/instant_explore
git rm -r .claude/skills/kai-brand .claude/skills/kai-competitors .claude/skills/kai-growth-plan .claude/skills/kai-launch
grep -rIn -e 'E:\\' -e 'kai-cmo-harness' -e '/kai-' -e 'scripts/quality_gates' -e 'data/learning/' .claude/skills/marketing-brand .claude/skills/marketing-competitors .claude/skills/marketing-growth-plan .claude/skills/marketing-launch
for d in marketing-brand marketing-competitors marketing-growth-plan marketing-launch; do grep -q "^name: $d$" .claude/skills/$d/SKILL.md || echo "MISMATCH $d"; done
```
Expected:皆無輸出。
- [ ] **Step 7: Commit**
```bash
git add .claude/skills/marketing-brand .claude/skills/marketing-competitors .claude/skills/marketing-growth-plan .claude/skills/marketing-launch
git commit -q -m "feat(skills): rewrite brand/competitors/growth-plan/launch for B2C

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 6: 網站/轉換批次 — seo-audit / landing-page / cro

**Files:**
- Create: `.claude/skills/marketing-{seo-audit,landing-page,cro}/SKILL.md`
- Delete: `.claude/skills/kai-{seo-audit,landing-page,cro}/`

**Interfaces:**
- Consumes:`marketing-gate`、`MARKETING.md`。
- Produces:3 個 web/轉換類 skill。

B2C 接線重點:
- **seo-audit**:目標頁面 = `lorescape.app` landing(Next.js,文案在 `landing/src/i18n/dictionaries.ts`,雙語 zh/en);資料來源 = GSC(見 lorescape-metrics);移除 python `seo_lint.py`,改引用 marketing-gate 的 SEO lint 段。
- **landing-page**:撰寫/檢視對象 = lorescape.app 落地頁;CTA = App Store / Google Play 下載;沿用 MARKETING.md 的 value prop 與 differentiators;產出可直接對應 `dictionaries.ts` 的雙語段落。
- **cro**:5 層分析套到「landing → App Store 商品頁 → 安裝 → 訂閱轉換(RevenueCat)」漏斗;資料來源 GA4(`GA4_PROPERTY_ID_WEB` / `_APP`);移除 B2B signup/checkout 用語。

- [ ] **Step 1: 讀三個來源 + 參考 landing 文案**
```bash
for s in seo-audit landing-page cro; do echo "=== kai-$s ==="; cat .claude/skills/kai-$s/SKILL.md; done
sed -n '1,40p' landing/src/i18n/dictionaries.ts
```
- [ ] **Step 2-4: 逐一建立 marketing-seo-audit / marketing-landing-page / marketing-cro/SKILL.md**
- [ ] **Step 5: 刪除三個舊目錄並 VERIFY**
```bash
cd /Users/paulwu/Documents/Github/instant_explore
git rm -r .claude/skills/kai-seo-audit .claude/skills/kai-landing-page .claude/skills/kai-cro
grep -rIn -e 'E:\\' -e 'kai-cmo-harness' -e '/kai-' -e 'scripts/quality_gates' -e 'data/learning/' .claude/skills/marketing-seo-audit .claude/skills/marketing-landing-page .claude/skills/marketing-cro
for d in marketing-seo-audit marketing-landing-page marketing-cro; do grep -q "^name: $d$" .claude/skills/$d/SKILL.md || echo "MISMATCH $d"; done
```
Expected:皆無輸出。
- [ ] **Step 6: Commit**
```bash
git add .claude/skills/marketing-seo-audit .claude/skills/marketing-landing-page .claude/skills/marketing-cro
git commit -q -m "feat(skills): rewrite seo-audit/landing-page/cro for lorescape.app + ASO

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 7: 數據/留存批次 — analytics / weekly-audit / monthly-audit / retention

**Files:**
- Create: `.claude/skills/marketing-{analytics,weekly-audit,monthly-audit,retention}/SKILL.md`
- Delete: `.claude/skills/kai-{analytics,weekly-audit,monthly-audit,retention}/`

**Interfaces:**
- Consumes:`marketing-gate`、`MARKETING.md`、`lorescape-metrics` skill 的 Google Sheet。
- Produces:4 個數據類 skill。

B2C 接線重點(全部對接既有 metrics 基礎建設,不重造抓數工具):
- **共通資料源**:lorescape-metrics 累積在 Google Sheet(`METRICS_SHEET_ID`,一個來源一個分頁:GSC、GA4 landing/app、IG 帳號/貼文、App Store/Play);GA4 property `GA4_PROPERTY_ID_APP` / `_WEB`;細節見 `docs/init/metrics-setup.md`。各 skill 應「讀 Sheet 既有數據」而非自行串 API。
- **analytics**:tracking plan / UTM / 歸因改成「IG → landing(UTM)→ App Store → 安裝 → 訂閱」;事件清單對齊 GA4 既有 property;移除 B2B 多通路歸因假設。
- **weekly-audit**:拉 Sheet 最近 7 日各分頁,對比前週,輸出健康度 + 行動清單;明確列 IG 觸及/粉絲、landing/app 流量、GSC 搜尋、下載/評分。
- **monthly-audit**:同上但 30 日 + 月度策略學習 + 下月計畫;可引用 weekly-audit 結果彙整。
- **retention**:留存/流失用 GA4 留存報表 + RevenueCat 訂閱生命週期(試用→付費→續訂→流失);win-back 改為 App 內推播 / 每日故事推播養成習慣(MARKETING.md differentiator),非 email 序列(已刪 email-system)。

- [ ] **Step 1: 讀四個來源 + lorescape-metrics**
```bash
for s in analytics weekly-audit monthly-audit retention; do echo "=== kai-$s ==="; cat .claude/skills/kai-$s/SKILL.md; done
sed -n '1,60p' .claude/skills/lorescape-metrics/SKILL.md
```
- [ ] **Step 2-5: 逐一建立四個 marketing-*/SKILL.md**
- [ ] **Step 6: 刪除四個舊目錄並 VERIFY**
```bash
cd /Users/paulwu/Documents/Github/instant_explore
git rm -r .claude/skills/kai-analytics .claude/skills/kai-weekly-audit .claude/skills/kai-monthly-audit .claude/skills/kai-retention
grep -rIn -e 'E:\\' -e 'kai-cmo-harness' -e '/kai-' -e 'scripts/quality_gates' -e 'data/learning/' .claude/skills/marketing-analytics .claude/skills/marketing-weekly-audit .claude/skills/marketing-monthly-audit .claude/skills/marketing-retention
for d in marketing-analytics marketing-weekly-audit marketing-monthly-audit marketing-retention; do grep -q "^name: $d$" .claude/skills/$d/SKILL.md || echo "MISMATCH $d"; done
```
Expected:皆無輸出。
- [ ] **Step 7: Commit**
```bash
git add .claude/skills/marketing-analytics .claude/skills/marketing-weekly-audit .claude/skills/marketing-monthly-audit .claude/skills/marketing-retention
git commit -q -m "feat(skills): rewrite analytics/audits/retention wired to lorescape-metrics

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 8: 全套最終驗證 + 開 PR

**Files:**
- 無新增;只驗證與開 PR。

**Interfaces:**
- Consumes:Task 1–7 的全部產物。

- [ ] **Step 1: 確認正好 15 個 marketing-* 且無 kai- 殘留**
```bash
cd /Users/paulwu/Documents/Github/instant_explore
ls -d .claude/skills/marketing-* | wc -l        # 預期 15
ls -d .claude/skills/kai-* 2>/dev/null | wc -l   # 預期 0
```
Expected:`15` 與 `0`。

- [ ] **Step 2: 全套 VERIFY(禁字 + frontmatter)**
```bash
grep -rIn -e 'E:\\' -e 'kai-cmo-harness' -e '/kai-' -e 'scripts/quality_gates' -e 'data/learning/' .claude/skills/marketing-* ;
for d in .claude/skills/marketing-*/ ; do n=$(basename "$d"); grep -q "^name: $n$" "$d/SKILL.md" || echo "FRONTMATTER MISMATCH: $d"; done
```
Expected:無任何輸出。

- [ ] **Step 3: 確認 description 皆含中英觸發詞**
```bash
for d in .claude/skills/marketing-*/SKILL.md; do echo "=== $d ==="; sed -n '/^description:/p' "$d"; done
```
逐一檢視:每個 description 都同時有英文與繁中觸發詞。若缺,補上後重新 commit。

- [ ] **Step 4: 推分支並開 PR**
```bash
git push -u origin chore/marketing-skills-b2c-rewrite
gh pr create --title "重構:kai 行銷 skill 收斂為 15 個 B2C marketing-* skill" --body "$(cat <<'EOF'
## 摘要
- 刪除 32 個不適用的 kai-* 行銷 skill(B2B 業務 / 廣告 / 非本產品模式)
- 保留 15 個改名為 marketing-*,完全自包含改寫(移除 Windows 路徑與 python 腳本)
- 改為 Lorescape B2C 語境,接上 lorescape-metrics / daily-story / publish-reel
- 共用脈絡指向 MARKETING.md,品質檢查改用 marketing-gate 內文 checklist

設計與計畫:`docs/superpowers/specs/2026-06-30-marketing-skills-b2c-rewrite-design.md`、`docs/superpowers/plans/2026-06-30-marketing-skills-b2c-rewrite.md`

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

---

## Self-Review(對照 spec)

- **Spec coverage**:刪除 32(Task 1)、MARKETING.md TODO(Task 2)、marketing-gate(Task 3)、15 個保留項全部分配到 Task 3–7、命名/自包含/資料接線/觸發詞全列入 Global Constraints 並由 VERIFY 與 Task 8 把關。✅
- **Placeholder scan**:各 Task 的改寫重點以具體接線指令呈現(資料源常數、檔案路徑、要刪的段落皆指名);未用「適當處理」「之後再補」類字眼。每個 skill 的最終逐字內文為實作產物,由 marketing-gate 與 VERIFY 驗收。
- **Type consistency**:跨 Task 一致使用 `marketing-gate`(被引用名)、VERIFY 指令、`METRICS_SHEET_ID` / `GA4_PROPERTY_ID_APP|WEB`、目錄=frontmatter `name` 規則。✅
