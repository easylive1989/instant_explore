---
name: marketing-gate
description: Lorescape 內容品質檢查 — 對內容執行完整品質關卡。評分 Four U's（Unique/Useful/Ultra-specific/Urgent），檢查禁用字與 AI slop，執行語氣 regex，對搜尋內容跑 SEO lint。Use when "score this", "quality check", "run quality gates", "check this content", "four u's score", "banned word check", "SEO lint", "品質檢查", "跑 gate", "禁用字檢查", "Four U 分數", or any request to validate content quality before publishing.
---

對一段內容執行 Lorescape 品質關卡流程。

## Gate Pipeline

依序執行所有檢查：

### 1. Four U's Score

每個維度評 1–4 分：

| U | Question | Score |
|---|----------|-------|
| **Unique** | 只有我們寫得出來嗎？有原始資料、視角或經驗？ | 1–4 |
| **Useful** | 讀者能立即採取行動嗎？ | 1–4 |
| **Ultra-specific** | 有數字、具名工具、具體例子嗎？ | 1–4 |
| **Urgent** | 今天就要讀的理由？ | 1–4 |

**門檻：** 12/16（部落格 / SEO 文章）；10/16（社群貼文 / IG caption）。

### 2. Banned Word Check

**即拒（Tier 1）：** leverage, utilize, synergy, innovative, deep dive, circle back, touch base, moving forward, at the end of the day

**AI slop（同樣即拒）：** "In conclusion", "It's important to note", "In today's rapidly evolving", "This comprehensive guide", "Without further ado", "It's worth noting that"

標示每個違規的確切位置（行號）。

**中文內容補充：** 中文貼文/文章同樣禁止使用誇張行銷語氣詞（「最強」「最好」「革命性」）以及條目式功能堆砌，呼應 MARKETING.md Brand Voice Don't 第 1、2 條。

### 3. Voice Pattern Check（程式化 — 不可跳過）

二元對立句型（"X-not-Y" / "It's not X, it's Y" / "isn't X — it's Y"）讀來像 LinkedIn 廢話，主觀評分無法捕捉。用 Grep 工具對內容執行以下 regex。任何符合 = FAIL。

**主要適用英文內容（landing en、IG en caption）。**

| Pattern | Catches |
|---|---|
| `, not [a-z]` | "X, not Y" |
| `— not [a-z]` | "X — not Y" |
| `\bisn'?t [a-z][^.\n]+ — it'?s\b` | "isn't X — it's Y" |
| `\baren'?t [a-z][^.\n]+ — they'?re\b` | "aren't X — they're Y" |
| `\bIt'?s (a\|the\|an) [^.\n]+, not (a\|the\|an)\b` | "It's a/the X, not a/the Y" |
| `\bThat'?s (a\|the\|an) [^.\n]+, not (a\|the\|an)\b` | "That's a/the X, not a/the Y" |
| `\bIf you [a-z][^,.]+, [a-z]` | "If you X, Y" rhetorical |
| `\bHere'?s the thing\b` | LinkedIn slop |
| `\bI'?ll be honest\b` | LinkedIn slop |
| `\bLet that sink in\b` | LinkedIn slop |
| `\bHot take\b` | LinkedIn slop |

略過 HTML 注解（`<!-- ... -->`）與程式碼圍欄（```` ``` ````）內的符合結果——這些是評分卡 / 元資料區塊。

**有效替換方式：**
- 收斂成單一核心主張。
- 使用平行正向對比，讓兩邊都是正面陳述：*"Description is passive. State is something the agent can act on."*
- 用比喻代替對稱反轉：*"expensive webhook"*，而非對稱倒裝。

**Project hook 整合：** 若本專案有對應 hook（如 `.claude/hooks/voice-gate.py`），則一併觸發；gate 步驟仍會執行 regex——雙重保險。

### 4. SEO Lint（僅限搜尋內容）

僅對目標為搜尋引擎的內容適用。檢查下列 Algorithmic Authorship 規則（共 5 條，全部內聯於此）：

1. **條件子句放句末**：主要指令/結論先出，條件（if/when/because）放後面，避免讀者需掃到最後才知道重點。
2. **指示句以動詞起始**：步驟說明的句子直接以動詞開頭（例：「點擊設定」而非「請用戶點擊設定」）。
3. **句子不超過 20 字**：英文 20 words；中文以 40 個字元為準。過長句拆分。
4. **粗體標記答案，不標記查詢詞**：把讀者最需要的答案/結論加粗，而非將標題關鍵字重複加粗。
5. **段落首句不置連結**：每段的第一句話不放超連結，讓搜尋引擎抓到乾淨的段落摘要。

### 5. Optional Panel Scoring（僅供參考）

只在使用者要求第二意見或內容屬高風險時使用。不取代主要 gate，無法推翻禁用字、缺少來源、政策風險或缺少審核批准所導致的 hard fail。

建議評審角色：
- **Audience reviewer**：檢查 persona 契合度與易讀性
- **Channel reviewer**：檢查平台適配性、格式與平台規範
- **Proof reviewer**：檢查來源位置、歸因與未佐證主張
- **Conversion reviewer**：檢查 CTA 清晰度與異議處理

Panel 評分以諮詢性備注輸出：

| Reviewer | Score | Concern | Suggested fix |
|----------|-------|---------|---------------|
| Audience | 1–5 | … | … |

治理規則：
- 將 panel 輸出標記為模擬評審，絕非專家驗證。
- 不得捏造資歷、背書或具名評審人。
- 將缺少來源位置視為 gate 問題，而非 panel 偏好。
- Panel 評分用於草稿；發佈仍需審核批准。

## Output Format

```
## Quality Gate Results

**Four U's:** [X]/16 [PASS/FAIL]
- Unique: [X]/4 — [reason]
- Useful: [X]/4 — [reason]
- Ultra-specific: [X]/4 — [reason]
- Urgent: [X]/4 — [reason]

**Banned Words:** [PASS/FAIL]
- [list violations with line numbers, or "None found"]

**AI Slop:** [PASS/FAIL]
- [list violations with line numbers, or "None found"]

**Voice Patterns:** [PASS/FAIL]
- [list X-not-Y / LinkedIn-slop violations with line numbers, or "None found"]

**SEO Lint:** [PASS/FAIL/SKIPPED]
- [list violations, or "All rules pass"]

**Overall:** [PASS/FAIL]
```

若 FAIL：列出具體需修正項目。提供自動修正並重新評分的選項。
