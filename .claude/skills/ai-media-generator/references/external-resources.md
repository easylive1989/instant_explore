# External Resources — Upstream Prompt Repositories

**用法：** 當 [community-prompt-patterns.md](community-prompt-patterns.md) 或 [preset-packs.md](../templates/preset-packs.md) 不夠用時，去 upstream 找最新 prompts。本檔記錄高質量 open-source repos，每次更新都應該 check。

**更新節奏：** AI 模型迭代極快，建議**每 2-3 週重 pull 一次**檢查新 prompts。

---

## 🎬 影片模型 prompt repositories

### ⭐ Seedance 2.0
- **Repo：** [`YouMind-OpenLab/awesome-seedance-2-prompts`](https://github.com/YouMind-OpenLab/awesome-seedance-2-prompts)
- **Stars：** 高（active）  **License：** CC BY 4.0
- **內容：** 6 hand-picked Featured + 101 curated（共 107，3,172 tracked）
- **強項：** Bracketed labels 結構、3-shot multi-camera、Audio Profile 4-modal
- **已整合：** [seedance.md §2026-05-18](seedance.md) + [preset-packs.md S1-S10](../templates/preset-packs.md)

### ⭐ Veo 3.1
- **Repo：** [`liu-kaining/Awesome-Veo3-Prompts`](https://github.com/liu-kaining/Awesome-Veo3-Prompts)
- **Stars：** 68⭐  **License：** MIT
- **內容：** 31 JSON-structured prompts（雙語 EN+中文 JSON）
- **強項：** **JSON-structured prompt format**（8 keys：shot_name / camera / setting / subject / visual_style / composition / implied_elements / sound）
- **已整合：** [community-prompt-patterns.md §Veo 3.1](community-prompt-patterns.md)

### ⭐ Sora 2（導演 style library）
- **Repo：** [`xjpp22/awesome--sora-prompts`](https://github.com/xjpp22/awesome--sora-prompts)
- **Stars：** 102⭐（最高 stars）  **License：** check
- **內容：** 31 位世界級導演的 Visual + Editing Style Prompts + 12 strategy categories
- **強項：** 導演風格速查（Wong Kar-wai / Villeneuve / Nolan / Miyazaki / Wes Anderson 等）
- **已整合：** [director-style-library.md](director-style-library.md)（全部 31 位導演 + 中文索引 + 用法範例）

### 🌐 跨平台（Veo / Sora / Runway / Pika / Kling）
- **Repo：** [`geekjourneyx/awesome-ai-video-prompts`](https://github.com/geekjourneyx/awesome-ai-video-prompts)
- **Stars：** 53⭐  **License：** MIT
- **內容：** 跨平台 prompt engineering guide（含 cinematic glossary stub）
- **狀態：** 大部分 docs/ 仍是 stub（待補），但 README 結構清晰，作為「全景圖」用
- **未整合：** 因 stub 內容多，待 upstream 充實後再 pull

### Kling AI / Hailuo / Wan
- **狀態：** 尚未找到高 star awesome-* repo
- **替代：** 用 [community-prompt-patterns.md](community-prompt-patterns.md) 內 Kling / Hailuo / Wan section
- **找到優質 repo 時：** 加進本檔 + 寫進 patterns

---

## 🖼 圖片模型 prompt repositories

### ⭐ Midjourney V7
- **Repo：** [`Pixmind-io/awesome-midjourney-v7-example-prompts`](https://github.com/Pixmind-io/awesome-midjourney-v7-example-prompts)
- **Stars：** 新（active）  **License：** CC0
- **內容：** 63+ tested V7 prompts、雙語 EN+中文、10 大類（photography / cinematic / architecture / anime / 3D / concept art / nature / etc.）
- **強項：** **V7 default params 已驗證**（`--ar 4:5 --s 350 --v 7` 等）+ 每 category 不同 sweet spot
- **已整合：** [community-prompt-patterns.md §MJ v7](community-prompt-patterns.md)

### Midjourney V5（中文）
- **Repo：** [`HebeDich/awesome-midjourney-prompts`](https://github.com/HebeDich/awesome-midjourney-prompts)
- **Stars：** 32⭐  **License：** check
- **內容：** V5 中文提示詞助手（含視覺化 UI）
- **狀態：** **V7 已是當前主力**，V5 留作 legacy reference

### ⭐ Nano Banana Pro
- **Repo 1：** [`Banana-Prompts/awesome-nano-banana-prompts`](https://github.com/Banana-Prompts/awesome-nano-banana-prompts)
  - **Stars：** 51⭐  **內容：** 14 大類分類（Portrait / Landscape / Architecture / Sci-Fi / Cyberpunk / Fantasy / Animals / Still Life / Food / Fashion / Character / Abstract / Nature / Cityscape）
  - **強項：** 短句也能 work + style anchor 列表完整
- **Repo 2：** [`GarvitOfficial/nanoBananaPrompts`](https://github.com/GarvitOfficial/nanoBananaPrompts)
  - **Stars：** 45⭐  **內容：** Seed image + Generated image + Reference image triple comparison（57+ 條目）
  - **強項：** **每 prompt 有對應 reference + seed + 生成結果**（visual debugging）
- **已整合：** [community-prompt-patterns.md §Nano Banana Pro](community-prompt-patterns.md)

---

## 🎵 音樂模型 prompt repositories

### ⭐ Suno v5
- **Repo：** [`naqashmunir21/awesome-suno-prompts`](https://github.com/naqashmunir21/awesome-suno-prompts)
- **Stars：** 37⭐（active，1000+ entries）  **License：** CC0
- **內容：** 1000+ professional Suno prompts，按 genre 分類（Pop 200+ / Rock 150+ / Hip-Hop 120+ / Country 100+ / EDM 130+ / R&B 80+ / Indie 90+ / Jazz 60+）
- **強項：** **BPM + Key 標準格式** + per-genre vocabulary
- **已整合：** [community-prompt-patterns.md §Suno v5](community-prompt-patterns.md)

---

## 📊 抓 prompts 的 SOP（每月例行）

```bash
# 1. Clone / pull 主要 repos
cd /tmp/prompt-research
for repo in YouMind-OpenLab/awesome-seedance-2-prompts \
            liu-kaining/Awesome-Veo3-Prompts \
            xjpp22/awesome--sora-prompts \
            Pixmind-io/awesome-midjourney-v7-example-prompts \
            Banana-Prompts/awesome-nano-banana-prompts \
            naqashmunir21/awesome-suno-prompts; do
  d=$(echo "$repo" | tr '/' '_')
  if [ -d "$d" ]; then
    (cd "$d" && git pull)
  else
    git clone --depth 1 "https://github.com/$repo" "$d"
  fi
done

# 2. Diff README 看新增 prompts
cd /tmp/prompt-research/<repo>
git log --since="1 month ago" --oneline

# 3. 新 patterns 寫進 community-prompt-patterns.md + 對應 reference file
# 4. 高品質新 preset 加進 preset-packs.md
# 5. Push 新版本
```

---

## 🔍 怎麼找新 repo

```bash
# 用 gh search 找新 awesome-*-prompts repo
gh search repos "awesome <model> prompts" --limit 5 \
  --json fullName,stargazersCount,description,updatedAt \
  --template '{{range .}}{{.stargazersCount}}* {{.fullName}}{{"\n"}}{{end}}'

# 篩選：
# - Stars ≥ 30
# - Updated 6 個月內
# - License 是 CC0/CC-BY/MIT
# - 內容 ≥ 30 個 prompts
```

---

## 📋 待 explore 的 repos（下次蒐集）

- Kling 專屬 prompt repo（目前無高星，需 fork + grow）
- Wan 2.6 prompt repo（中文社群可能有）
- Hailuo 2.3 prompt repo
- Runway Gen-4 / Aleph prompt repo
- Ideogram 3 text-rendering 範本
- Flux 1.1 Pro / Kontext edit prompt 範本

**找到後**：clone → 抽 patterns → 更新本檔 + community-prompt-patterns.md + 對應 reference file → push 新版本。

---

## 🤝 致謝

本 skill v1.1.0+ 的內容大量受惠於上述 open-source 創作者。我們從這些 repo 萃取的內容遵循各 repo 的 license（CC0 / CC BY 4.0 / MIT），並在 inline 註明來源 + 作者 X handle。
