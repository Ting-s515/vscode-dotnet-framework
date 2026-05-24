# Code Review 紀錄 — 2026-05-24（第 1 輪）

## 📋 Code Review 摘要

**審查範圍：** 本次 `git diff HEAD` 中的 docs HTML 產生器、三欄式 HTML 模板、PowerShell 入口腳本、操作文件與重新產生的 `docs/html/*.html`。
**整體評估：** ✅ 符合需求可提交。

---

### 📐 規格符合度

#### ✅ 符合規格的項目

- 三欄式頁面：`scripts/build-docs-html/template.html` 已改為左側文件目錄、中間內容、右側內容大綱。
- 左側檔案目錄：`scripts/build-docs-html/build.mjs` 維持 README 優先排序，並支援 `.md` / `.mdx` 文件進入導覽。
- 右側內容大綱：`markdown-it-anchor` callback 會收集 H1 到 H4 標題，輸出可點擊的 `#heading-id` anchor。
- HTML 轉換腳本：`scripts/build-docs-html.ps1` 與 `npm run build` 都可重新產生 `docs/html/*.html`。
- 文件說明：`docs/README.md` 與 `docs/build-docs-html-guide.md` 已補上三欄式 HTML 與 `.mdx` 來源說明。

#### ❌ 不符合或缺漏的項目

- 無。

---

### 🔴 必須修正（Critical）

無。

---

### 🟠 建議改善（Warning）

無。

---

### ⚪ 使用者自行決定（註解類問題）

無。
