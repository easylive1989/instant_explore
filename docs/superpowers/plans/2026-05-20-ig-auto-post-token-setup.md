# IG Auto-Post Token Setup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Populate `backend/.env` with valid `IG_USER_ID` and `META_PAGE_ACCESS_TOKEN`, so `Config.from_env().instagram_enabled` is `True`.

**Architecture:** Pure ops setup. No production code changes. Existing publish pipeline (`backend/src/lorescape_backend/social/publisher.py` + `instagram.py`) already reads these env vars and gates IG publishing on them. The only blocker is that the two env-var slots are currently empty.

**Tech Stack:** Bash, `scripts/meta_token_helper.py` (Python), `uv` (Python runner for backend).

**Spec:** `docs/superpowers/specs/2026-05-20-ig-auto-post-token-setup-design.md`

---

## Pre-flight assumptions (must be true before starting)

依賴 spec「執行步驟 Step 1 前置條件」段落 — 摘要列在此處方便執行者快速確認：

- `love.lorescape` Instagram 已設為 **Business** 或 **Creator** 帳號
- IG 已連結到 Facebook Page（FB Page → Professional dashboard → Linked accounts → Instagram）
- Meta Developer App（Lorescape, App ID `1635287081082476`）已啟用以下權限：
  - `pages_show_list`
  - `pages_read_engagement`
  - `pages_manage_posts`
  - `instagram_basic`
  - `instagram_content_publish`

若任一條件不成立 → **停**，回到 `docs/init/social_publisher_setup.md` 把前置補齊再回來執行此 plan。

---

## File Structure

無新增 / 修改檔案。只動 **未入版** 的 `backend/.env`（已在 `.gitignore`）。

- Modify (untracked, gitignored): `backend/.env`
- Read-only references:
  - `backend/.env.example`
  - `backend/src/lorescape_backend/config.py`
  - `scripts/meta_token_helper.py`
  - `docs/init/social_publisher_setup.md`

本 plan 全程**不會產生 git commit**（spec 已於前一輪 commit 到 master）。

---

### Task 1: Ensure `backend/.env` exists with IG slots blank (baseline)

**Files:**
- Modify: `backend/.env` (create from `.env.example` if missing)

- [ ] **Step 1: Check whether `backend/.env` exists**

Run:
```bash
cd /Users/paulwu/Documents/PLRepo/instant_explore
test -f backend/.env && echo "EXISTS" || echo "MISSING"
```

Expected: `EXISTS` or `MISSING` — either is OK, decides next step.

- [ ] **Step 2: If MISSING, create from example**

Skip if Step 1 returned `EXISTS`.

Run:
```bash
cd /Users/paulwu/Documents/PLRepo/instant_explore
cp backend/.env.example backend/.env
```

Expected: file created, no output. After this `backend/.env` exists with all keys present but values blank/placeholder.

- [ ] **Step 3: Confirm baseline — `instagram_enabled` is currently `False`**

Run:
```bash
cd /Users/paulwu/Documents/PLRepo/instant_explore/backend
uv run --env-file=.env python -c "from lorescape_backend.config import Config; c = Config.from_env(); print('IG enabled:', c.instagram_enabled)"
```

Expected output (one of):
- `IG enabled: False` — IG vars are empty (good, this is our baseline)
- `RuntimeError: Missing required env var: SUPABASE_URL` or similar — required vars not yet filled. **Fix those first** by following `docs/init/social_publisher_setup.md`; then re-run this step until you get `IG enabled: False`.

Why this matters: confirms we can load `Config` and that the only thing keeping `instagram_enabled` `False` is the IG-token blanks (not other config errors).

---

### Task 2: Obtain `IG_USER_ID` and `META_PAGE_ACCESS_TOKEN` via helper script

**Files:**
- Read-only: `scripts/meta_token_helper.py`

This task is **interactive and browser-based**. Run the helper script and follow its prompts.

- [ ] **Step 1: Run the helper script**

Run:
```bash
cd /Users/paulwu/Documents/PLRepo/instant_explore
python scripts/meta_token_helper.py --platform instagram
```

The script walks 5 steps:
1. Asks for App ID (`1635287081082476`) and App Secret
2. Opens Graph API Explorer in your browser → asks you to paste a short-lived User Token (with all 5 permissions listed in Pre-flight)
3. Exchanges short → long-lived User Token (60-day)
4. Lists your Facebook Pages → asks you to pick the Lorescape Page → returns its permanent Page Access Token
5. Resolves IG Business Account ID linked to that Page

At the end it prints:
```
═══════════════════════════════════════════════════════════
  Copy these lines into  backend/.env
═══════════════════════════════════════════════════════════
  IG_USER_ID=<numeric-id>
  META_PAGE_ACCESS_TOKEN=<long-string>
═══════════════════════════════════════════════════════════
```

- [ ] **Step 2: Save the output**

Copy those two lines to a temp location (clipboard / scratchpad). You'll paste them in Task 3.

If the script errors out, the most common causes are listed in `docs/init/social_publisher_setup.md` under "Instagram Token" — handle there before retrying.

---

### Task 3: Paste values into `backend/.env`

**Files:**
- Modify: `backend/.env`

- [ ] **Step 1: Open `backend/.env` and replace the two blank lines**

Edit `backend/.env`. Find these two lines:

```dotenv
IG_USER_ID=
META_PAGE_ACCESS_TOKEN=
```

Replace with the values from Task 2 Step 1, e.g.:

```dotenv
IG_USER_ID=17841401234567890
META_PAGE_ACCESS_TOKEN=EAAXXXX...verylongstring...XXX
```

- [ ] **Step 2: Confirm `backend/.env` is still gitignored**

Run:
```bash
cd /Users/paulwu/Documents/PLRepo/instant_explore
git check-ignore -v backend/.env
```

Expected:
```
.gitignore:<line>:.env  backend/.env
```

(or similar — must report that `.env` matches the `.gitignore` rule). If the file shows up as untracked-but-not-ignored, **STOP** and fix `.gitignore` before continuing. We must not commit real tokens.

- [ ] **Step 3: Confirm `backend/.env` is not in `git status`**

Run:
```bash
cd /Users/paulwu/Documents/PLRepo/instant_explore
git status --short backend/.env
```

Expected: empty output (gitignored files don't appear).

---

### Task 4: Verify `Config.instagram_enabled` is now `True`

**Files:**
- Read-only: `backend/src/lorescape_backend/config.py`

- [ ] **Step 1: Re-run the config-load check from Task 1 Step 3**

Run:
```bash
cd /Users/paulwu/Documents/PLRepo/instant_explore/backend
uv run --env-file=.env python -c "from lorescape_backend.config import Config; c = Config.from_env(); print('IG enabled:', c.instagram_enabled)"
```

Expected output:
```
IG enabled: True
```

- [ ] **Step 2: Treat as done when output is `IG enabled: True`**

If you got `IG enabled: True` → IG token setup is complete. Code can run. Task done.

If you got `IG enabled: False` → one of the two values is empty or whitespace-only. Re-open `backend/.env`, verify both lines have non-empty values, then re-run Step 1.

If you got an exception → the Config raised on a different required field (not IG). Fix that env var first (follow error message), then re-run Step 1.

---

## Done criteria (matches spec §"成功判準")

- ✅ `Config.from_env()` 載入時不丟例外
- ✅ `Config.instagram_enabled` 為 `True`
- ✅ `backend/.env` 中 `IG_USER_ID` 與 `META_PAGE_ACCESS_TOKEN` 為非空、實際有效值（從 Meta Graph API 換出來的長效 token）
- ✅ `backend/.env` 仍被 `.gitignore` 排除，未被 `git status` 看到

## Out of scope (重申自 spec §"非目標")

- 端到端發文驗證（不會推任何 post 到 IG）
- Discord review bot 設定 — 仍是讓 21:00 cron 真正觸發 IG publish 的先決條件，但本 plan 範圍只到「IG token 填好、code 載得起來」。
- Threads token 設定
- 任何 production code 改動
