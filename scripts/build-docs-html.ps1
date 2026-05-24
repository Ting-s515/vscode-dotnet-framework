#Requires -Version 5.1
<#
.SYNOPSIS
    將 docs/*.md 與 docs/*.mdx 全部轉成 docs/html/*.html，供使用者以瀏覽器閱讀。

.DESCRIPTION
    呼叫 scripts/build-docs-html/build.mjs（Node.js + markdown-it）執行轉換：
    - 處理 GFM 表格、程式碼區塊
    - Mermaid 區塊用 CDN 渲染
    - github-markdown-css 排版
    - 內部 .md / .mdx 連結自動改寫為 .html
    - 左側產生文件目錄導覽
    - 右側依目前文件標題產生可點擊內容大綱
    - 額外輸出 docs/html/index.html 跳轉至 README.html

    第一次執行會自動 npm install 安裝相依套件至 scripts/build-docs-html/node_modules/。

.PARAMETER SkipInstall
    略過 npm install 檢查（已知 node_modules 存在時可加速）。

.EXAMPLE
    .\scripts\build-docs-html.ps1

.EXAMPLE
    .\scripts\build-docs-html.ps1 -SkipInstall
#>
[CmdletBinding()]
param(
    [switch]$SkipInstall
)

$ErrorActionPreference = 'Stop'

$buildDir = Join-Path $PSScriptRoot 'build-docs-html'
if (-not (Test-Path $buildDir)) {
    throw "找不到 build 目錄：$buildDir"
}

# 確認 node 可用
$node = Get-Command node -ErrorAction SilentlyContinue
if (-not $node) {
    throw "找不到 node.exe。請先安裝 Node.js (https://nodejs.org/) 後重試。"
}

# 安裝相依套件（如果 node_modules 不存在）
$nodeModules = Join-Path $buildDir 'node_modules'
if (-not $SkipInstall -and -not (Test-Path $nodeModules)) {
    Write-Host '[1/2] 安裝 npm 相依套件 (markdown-it, markdown-it-anchor)...' -ForegroundColor Cyan
    Push-Location $buildDir
    try {
        npm install --no-audit --no-fund
        if ($LASTEXITCODE -ne 0) {
            throw "npm install 失敗 (exit code $LASTEXITCODE)"
        }
    } finally {
        Pop-Location
    }
} else {
    Write-Host '[1/2] 略過 npm install（node_modules 已存在或指定 -SkipInstall）' -ForegroundColor DarkGray
}

# 執行轉換
Write-Host '[2/2] 轉換 docs/*.md / docs/*.mdx -> docs/html/*.html ...' -ForegroundColor Cyan
Push-Location $buildDir
try {
    node build.mjs
    if ($LASTEXITCODE -ne 0) {
        throw "build.mjs 執行失敗 (exit code $LASTEXITCODE)"
    }
} finally {
    Pop-Location
}

$outDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'docs\html'
Write-Host ""
Write-Host "完成。輸出位置：$outDir" -ForegroundColor Green
Write-Host "首頁：docs/html/index.html（會跳轉至 README.html）"
