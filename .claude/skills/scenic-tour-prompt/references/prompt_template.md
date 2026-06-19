# Seedance 2.0 提示詞組裝範本

來源：`_Project/影片提示詞分析/seedance_2.0_prompts_analysis.md`。
黃金公式：`[整體風格氛圍] + [一致性約束] + [分秒時間軸分鏡] + [相機軌跡與技術參數]`，前面再加一個 YAML 參數區塊。

提示詞**全英文輸出**。把下列骨架的 `<...>` 全部用看圖萃取到的內容替換。

---

## 組裝骨架

```text
format: <vertical_9x16 | horizontal_16x9>
fps: 24
total_duration: <e.g. 15s>
style: <e.g. cinematic, realistic>

<OVERALL MOOD — one or two sentences setting the atmosphere of the location and the tour, e.g. "A serene cinematic travel vlog of a young woman exploring <景點名稱>, warm golden-hour light, calm and inviting mood.">

Character reference: @image1.
Consistency: keep exact character design, same face, same hairstyle, same outfit, same body proportions, same accessories, same colors throughout all shots. <再補上看圖得到的具體外貌描述>

Timeline:
[0-Xs] @image2 — <人物動作：走入/駐足/手勢指向/回望> + <鏡頭運動> revealing <該景點圖場景特徵>.
[X-Ys] @image3 — <人物動作> + <鏡頭運動> revealing <下一個場景特徵，對應使用者故事重點，用視覺呈現>.
[Y-Zs] @image4 — <人物動作> + <鏡頭運動> revealing <...>.
<景點圖有幾張就排幾段；維持人物移動連續性>

Camera & quality: <2-4 個運鏡詞>, shallow depth of field, soft natural lighting, film grain, volumetric god rays, 8k resolution, ultra detailed.

No text, no captions, no subtitles, no on-screen words. No dialogue, no narration, silent footage.
```

> `@image1` 固定指代人物參考圖；`@image2` 起依序對應各張景點圖。實際 token 寫法依使用者所用平台微調，但「人物圖在前、景點圖依序」的對應關係要清楚。

---

## 一致性約束咒語庫（Consistency）

主咒語（每次必放）：
```text
keep exact character design, same face, same hairstyle, same outfit, same body proportions, same accessories, same colors
```

看人物圖後，再補上具體錨點（擇要描述，避免變形）：
- 臉部：臉型、膚色、五官特徵、表情基調
- 髮型：長度、顏色、造型
- 服飾：上衣/外套/下身/鞋、顏色與材質
- 配件：眼鏡、帽子、包、首飾等
- 體型：身形比例、身高感

---

## 人物動作詞庫（純視覺「導覽介紹」感）

走動與導覽：`walking into frame`, `strolling along the path`, `pausing to look around`, `gesturing toward the scenery`, `pointing at <景物>`, `turning to glance back at camera`, `running her hand along <欄杆/牆面>`, `looking up in awe`, `breathing in the view`, `inviting gesture leading the camera forward`

> 全部以肢體與視線傳達，不需任何口白或文字。

## 運鏡詞庫（Camera trajectory）

- 推進/拉遠：`slow camera push-in`, `dolly zoom`, `pull-back reveal`
- 跟拍/環繞：`tracking shot`, `orbit shot`, `360 orbit`, `follow shot`
- 角度：`low angle`, `high angle`, `eye-level`, `over-the-shoulder`
- 廣角/特寫：`wide establishing shot`, `extreme close-up`, `aerial drone shot`

## 畫質/氛圍詞庫（Quality & lighting）

`shallow depth of field`, `film grain`, `god rays`, `volumetric lighting`, `soft natural lighting`, `golden hour`, `8k resolution`, `ultra detailed`, `cinematic color grading`, `glowing highlights`

---

## 場景→運鏡對應建議

| 景點圖類型 | 建議運鏡 + 人物動作 |
|---|---|
| 開闊全景/廣場 | `wide establishing shot` / `orbit shot` + 人物走入、張開雙手感受 |
| 長廊/步道/階梯 | `tracking shot` 跟拍推進 + 人物沿路前行、回望 |
| 建築立面/地標 | `slow push-in` / `low angle` + 人物駐足、抬頭仰望、手勢指向 |
| 局部細節/紋理 | `extreme close-up` + `shallow depth of field` + 人物手撫過、湊近端詳 |
| 水景/自然 | `aerial drone shot` / `pull-back reveal` + 人物佇立、遠眺 |
