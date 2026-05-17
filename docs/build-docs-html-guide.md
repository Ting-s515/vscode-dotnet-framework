# `docs/*.md` 轉 HTML 操作手冊

把 `docs/` 下所有 `.md` 轉成 `docs/html/*.html`，方便用瀏覽器閱讀（側邊導覽、Mermaid 圖渲染、語法高亮）。

## 1. Prerequisites

| 工具 | 版本 | 驗證指令 | 取得方式 |
|------|------|----------|----------|
| Node.js | 18+ | `node --version` | <https://nodejs.org/>（LTS） |
| PowerShell | 5.1+ | `$PSVersionTable.PSVersion` | Windows 10/11 內建 |

> 不需要全域 npm 套件，腳本第一次執行會在 `scripts/build-docs-html/` 內自動 `npm install`。

## 2. 三個常用指令

在 **repo 根目錄** 開 PowerShell 執行：

```powershell
# (1) 第一次執行（會自動 npm install，約 5 秒）
.\scripts\build-docs-html.ps1

# (2) 之後改了 docs/*.md，重新產生（跳過 npm install，約 1 秒）
.\scripts\build-docs-html.ps1 -SkipInstall

# (3) 看完整參數說明
Get-Help .\scripts\build-docs-html.ps1 -Full
```

執行完成後：

```powershell
# 用預設瀏覽器開啟首頁（自動跳轉到 README.html）
start .\docs\html\index.html
```

## 3. Troubleshoot 速查

| 症狀 | 原因 | 處理 |
|------|------|------|
| `找不到 node.exe` | 沒裝 Node.js | 安裝 Node.js LTS 後重開 PowerShell 再試 |
| `npm install` 卡住或超時 | 公司 proxy / npm registry 被擋 | 改設 npm registry：`npm config set registry https://registry.npmmirror.com/` 後重跑 |
| HTML 開啟後 Mermaid 沒渲染、字型很醜 | 公司網路擋 jsdelivr CDN | 暫時無解，需換成本地資源（後續可改 `scripts/build-docs-html/template.html`） |
| 改了 `.md` 但 HTML 沒變 | 沒重跑腳本 | 執行 `.\scripts\build-docs-html.ps1 -SkipInstall` |
| 內部連結點下去 404 | 對應 `.md` 沒被一起 build（如手動寫的 `./xxx.html` 連到不存在檔案） | 確認原 `.md` 的連結是 `./xxx.md`，腳本會自動改寫為 `.html` |

## 4. 工具檔案結構

```text
scripts/
├── build-docs-html.ps1            # PowerShell 入口（使用者只接觸這個）
└── build-docs-html/
    ├── package.json               # npm 套件定義（markdown-it、markdown-it-anchor）
    ├── package-lock.json          # 鎖版本，commit 進 repo
    ├── build.mjs                  # 實際的 Node 轉換邏輯
    ├── template.html              # HTML 模板（改排版/CDN 來源就改這裡）
    └── node_modules/              # 自動安裝，.gitignore 已排除
```

要客製排版（顏色、字型、側邊欄寬度）→ 改 `template.html` 內的 `<style>`；要改連結改寫規則或 Mermaid 處理 → 改 `build.mjs`。
