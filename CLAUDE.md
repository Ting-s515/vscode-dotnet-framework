# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 專案目的

這個 repo 是「用 VS Code 取代紫色 Visual Studio 開發 SharePoint Server / .NET Framework 專案」的工作流模板庫。目標不是完整複製 Visual Studio，而是建立可重複執行的命令列工作流：**VS Code 負責編輯、MSBuild 負責 build/package、PowerShell 負責 deploy/update/retract**。

## 腳本使用方式

所有腳本位於 `scripts/`，執行環境需要 PowerShell 5.1+。

**MSBuild 腳本（本機可執行，不需要 SharePoint 環境）：**

```powershell
# build .sln 或 .csproj
.\scripts\build.ps1 -SolutionPath "path/to/Solution.sln" -Configuration Release

# 打包 .wsp（只能指定 project，不能指定 solution）
.\scripts\package.ps1 -ProjectPath "path/to/Project.csproj" -Configuration Release

# 驗證 package
.\scripts\validate-package.ps1 -ProjectPath "path/to/Project.csproj"
```

**SharePoint PowerShell 腳本（需要公司電腦 / SharePoint Management Shell）：**

```powershell
# 新增並安裝 solution
.\scripts\deploy-wsp.ps1 -WspPath "path/to/Package.wsp" -WebApplicationUrl "http://sharepoint-server"

# 更新既有 solution
.\scripts\update-wsp.ps1 -WspPath "path/to/Package.wsp"

# 解除安裝（並可選擇從 Farm 移除）
.\scripts\retract-wsp.ps1 -SolutionName "Package.wsp" -AllWebApplications -RemoveFromFarm
```

所有腳本都用 `-WhatIf` 可以預覽操作而不實際執行（deploy / update / retract 支援 `SupportsShouldProcess`）。

## 架構與腳本設計原則

- **不硬編碼路徑**：所有路徑、伺服器 URL、solution 名稱都是參數，部署時才帶入。
- **MSBuild 路徑自動偵測**：預設使用 PATH 中的 `msbuild.exe`；若需指定完整路徑，用 `-MsBuildPath`。
- **SharePoint PowerShell 懶加載**：腳本先檢查 cmdlet 是否存在，不存在才嘗試載入 snap-in；環境不支援時拋出明確錯誤。
- **`build.ps1` 可接受 `-SolutionPath` 或 `-ProjectPath`，兩者只能擇一**；`package.ps1` 和 `validate-package.ps1` 只接受 `-ProjectPath`（MSBuild Package target 需要 project 層級）。
- **`deploy-wsp.ps1` 的 `-WebApplicationUrl` 與 `-AllWebApplications` 只能擇一**；`retract-wsp.ps1` 同理。

## 目前進度

依 `docs/vscode-sharepoint-workflow-dependency-order.md` 的交接任務表：

| 任務 | 狀態 |
|------|------|
| `scripts/` 六個腳本模板 | `[x]` 已完成 |
| `.vscode/tasks.json` | `[ ]` 待建立 |
| 公司電腦 PoC 操作文件 | `[ ]` 待撰寫 |
| 公司電腦實測 | `[blocked]` 等待 SharePoint 環境 |

**下一步**應建立 `.vscode/tasks.json`，讓每個 task 呼叫對應的 `scripts/*.ps1`，task 名稱為：`SharePoint: Build`、`SharePoint: Package WSP`、`SharePoint: Validate Package`、`SharePoint: Deploy WSP`、`SharePoint: Update WSP`、`SharePoint: Retract WSP`。

## 不在範圍內

- WinForms / WPF / Razor 視覺化 Designer
- SharePoint Project Template UI、Package Designer、Feature Designer
- VS Code extension 開發（等 scripts/tasks 穩定後才評估）
- 本機執行 SharePoint deploy/update/retract（需要公司 SharePoint Server 環境）
