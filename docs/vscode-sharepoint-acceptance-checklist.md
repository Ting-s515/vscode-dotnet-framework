# VS Code 取代 Visual Studio 開發 SharePoint：使用者驗收清單

## 0. 文件目的

本清單讓 **使用者** 照順序逐項驗證，最終回答這個問題：

> **能否以藍色 Visual Studio Code 完成 SharePoint Framework 專案的 build / package / deploy / update / retract，不再依賴紫色 Visual Studio？**

本清單為 **驗收（UAT）文件**，不是教學手冊。教學操作請看 [`vscode-sharepoint-poc-runbook.md`](./vscode-sharepoint-poc-runbook.md)；架構決策請看 [`vscode-sharepoint-dotnet-framework-feasibility.md`](./vscode-sharepoint-dotnet-framework-feasibility.md)。

### Definition of Done

只有當 **所有 Stage 1～Stage 6 必填項目 `[x]` 都勾選通過**，且 [§10 最終驗收聲明](#10-最終驗收聲明) 已簽署，才能宣告 VS Code 工作流可正式取代 Visual Studio。

任何一項 Fail，需於 [§9 失敗對策參考索引](#9-失敗對策參考索引) 找到對應排查方向，修正後重測。

### 如何使用本清單

1. 依 Stage 順序執行，不要跳關（Stage 4 依賴 Stage 3 通過）。
2. 每項驗證填寫：勾選 `[x]` / 日期 / 執行人 / 備註。
3. 失敗項目於備註欄記錄症狀與修正動作，並重測直到通過。
4. 全部完成後，在 [§8 驗收紀錄表](#8-驗收紀錄表) 與 [§10 最終驗收聲明](#10-最終驗收聲明) 簽署。

### 範圍與排除

| 範圍 | 在驗收清單內 | 不在驗收清單內 |
|------|--------------|----------------|
| SharePoint Server / Farm Solution（`.wsp`） | ✅ | — |
| Feature / Elements / Package XML 編輯 | ✅ | — |
| MSBuild build / package / validate | ✅ | — |
| PowerShell deploy / update / retract | ✅ | — |
| WinForms / WPF Designer | — | ❌ |
| Razor 視覺化編輯 | — | ❌ |
| SharePoint Add-in（SPFx / SharePoint Framework with Node） | — | ❌ |

---

## 1. Stage 0：開始前必讀

| # | 項目 | 確認 |
|---|------|------|
| 0.1 | 目標專案是 SharePoint Server / Farm Solution（會產生 `.wsp`），不是 SPFx（Node-based） | `[ x]` |
| 0.2 | 專案不依賴 WinForms / WPF Designer 與 Razor 視覺化編輯 | `[x ]` |
| 0.3 | 已閱讀 [`vscode-sharepoint-dotnet-framework-feasibility.md`](./vscode-sharepoint-dotnet-framework-feasibility.md) 「不建議承諾的範圍」一節 | `[x ]` |
| 0.4 | 驗收期間，同一份程式碼不會同時被紫色 Visual Studio 部署，避免互相覆蓋 | `[x ]` |

任何一項未確認，**請先停止**，與專案負責人對齊範圍。

---

## 2. Stage 1：本機環境驗證（無 SharePoint）

此 Stage 在開發者個人電腦執行，不需 SharePoint Server。

本 Stage 只列出 **隨個別環境變動才會發生** 的驗證項目；以下兩類事實不重複驗證：

1. **git 同步後天然成立**：資料夾存在、`tasks.json` 內容、腳本語法、`settings.json` 內容。
2. **Windows 預設安裝就有**：Windows PowerShell 5.1（內建於 Windows 10 / 11 / Server）、`cmd.exe`、`PowerShell ISE`。

| # | 驗證項目 | 執行步驟 | 預期結果 | 勾選 |
|---|----------|----------|----------|------|
| A1 | VS Code 已安裝 | terminal 執行 `code --version` | 顯示版本號 | `[x ]` |
| A2 | `ms-dotnettools.csharp` 已安裝 | VS Code Extensions 搜尋 `C#`，確認發佈者為 Microsoft | 顯示 Installed | `[x ]` |
| A3 | C# Dev Kit 未接管 | Extensions 確認 C# Dev Kit 未安裝，或已在本 workspace `Disable (Workspace)` | 不在 Enabled 清單 | `[x ]` |
| A4 | VS Code 能正確載入 tasks.json | `Ctrl+Shift+P` → `Tasks: Run Task` | 看到 10 個 `SharePoint: *` task；無 schema 錯誤提示 | `[x ]` |

**Stage 1 通過條件：** A1～A4 全部 `[x]`。

---

## 3. Stage 2：VS Code 編輯能力驗證（公司 SharePoint 專案）

此 Stage 用 **公司真實 SharePoint 專案** 開啟，驗證 VS Code 編輯體驗是否足夠承接日常工作。

| # | 驗證項目 | 執行步驟 | 預期結果 | 勾選 |
|---|----------|----------|----------|------|
| B1 | 公司 SharePoint 專案可在 VS Code 開啟 | `code <公司專案資料夾>` | 不報錯，OmniSharp output 顯示 `Loaded ... project` | `[ ]` |
| B2 | OmniSharp 載入 `.csproj` / `.sln` | VS Code 右下角狀態列等候 OmniSharp 完成 | 看到 `OmniSharp Server running` | `[ ]` |
| B3 | C# IntelliSense 運作 | 開任一 `.cs` 檔，輸入 `SPContext.` | 跳出成員自動完成清單 | `[ ]` |
| B4 | Go to Definition 運作 | 在 `SPContext.Current` 上按 F12 | 跳到 metadata 或定義 | `[ ]` |
| B5 | 變數 Rename 運作 | 對任一 local variable 按 F2 改名 | 整檔同名稱同步改名 | `[ ]` |
| B6 | Feature.xml / Elements.xml / Package.xml 有 XML 高亮 | 開啟任一 SharePoint XML 檔 | 顯示 XML 語法上色與大綱 | `[ ]` |
| B7 | Problems 面板可顯示編譯錯誤 | 故意把某 `.cs` 改成語法錯誤 | Problems 面板出現紅色錯誤 | `[ ]` |
| B8 | 編輯後存檔不破壞檔案編碼 | 修改一個含中文註解的檔案後存檔，git diff 確認 | 無 BOM 或編碼異常 | `[ ]` |

**Stage 2 通過條件：** B1～B8 全部 `[x]`。

若 B3 失敗，常見是 C# Dev Kit 干擾或 `.vscode/settings.json` 中 OmniSharp legacy 設定未生效，回 A3 重檢查並確認 settings.json 已套用。

---

## 4. Stage 3：公司電腦環境驗證

對應 PoC runbook §1～§3。

| # | 驗證項目 | 執行步驟 | 預期結果 | 勾選 |
|---|----------|----------|----------|------|
| C1 | `MSBuild.exe` 可被找到 | `& "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" -latest -requires Microsoft.Component.MSBuild -find "MSBuild\**\Bin\MSBuild.exe"` | 回傳 `MSBuild.exe` 完整路徑 | `[ ]` |
| C2 | SharePoint targets 可被找到 | 搜尋 `Microsoft.VisualStudio.SharePoint.targets` | 至少一筆結果 | `[ ]` |
| C3 | .NET Framework Developer Pack 版本符合專案 Target Framework | 控制台「程式和功能」確認 | 版本 ≥ 專案 TargetFrameworkVersion | `[ ]` |
| C4 | SharePoint snap-in 或 Module 可載入 | Windows PowerShell 5.1 執行 `Add-PSSnapin Microsoft.SharePoint.PowerShell` 或 `Import-Module Microsoft.SharePoint.Powershell` | 無錯誤 | `[ ]` |
| C5 | `Add-SPSolution` cmdlet 可用 | `Get-Command Add-SPSolution` | 回傳 cmdlet 資訊 | `[ ]` |
| C6 | 執行帳號具部署權限 | 執行 `Get-SPShellAdmin` 後檢視輸出是否包含 `$env:USERNAME`；或請 Farm Admin 確認 | 列表中含目前使用者 / Farm Admin 確認 | `[ ]` |
| C7 | PowerShell Execution Policy 不阻擋 | `Get-ExecutionPolicy -List` | 至少有一個 Scope 為 `RemoteSigned` / `Bypass` / `Unrestricted` | `[ ]` |
| C8 | PowerShell LanguageMode 為 FullLanguage | `$ExecutionContext.SessionState.LanguageMode` | `FullLanguage` | `[ ]` |
| C9 | 至少一個專案可成功被 `MSBuild.exe <project>.csproj /t:Build` 完成 | 命令列直接呼叫 MSBuild，不透過 task | exit code = 0 | `[ ]` |

**Stage 3 通過條件：** C1～C9 全部 `[x]`。

C4 / C5 失敗，**不可** 進入 Stage 5；可先做 Stage 4 的 build / package / validate。

---

## 5. Stage 4：Build / Package / Validate 驗證（不需 SharePoint runtime）

| # | 驗證項目 | 執行步驟 | 預期結果 | 勾選 |
|---|----------|----------|----------|------|
| D1 | `SharePoint: Build` 成功 | Run Task → `SharePoint: Build`，帶入 solution 路徑 | exit code 0，無紅色錯誤 | `[ ]` |
| D2 | `SharePoint: Build (Project)` 成功 | Run Task → `SharePoint: Build (Project)`，帶入 csproj | exit code 0 | `[ ]` |
| D3 | `SharePoint: Package WSP` 產生 `.wsp` | Run Task → `SharePoint: Package WSP` | `bin\<Config>\<Project>.wsp` 存在 | `[ ]` |
| D4 | `.wsp` 內容正確 | 將 `.wsp` 改副檔名為 `.cab` 或用 7-Zip 開啟 | 看到 `manifest.xml`、Feature 資料夾 | `[ ]` |
| D5 | `SharePoint: Validate Package` 無 error | Run Task → `SharePoint: Validate Package` | exit code 0，Output 無 SPDisp/SPPkg error | `[ ]` |
| D6 | 與 Visual Studio 產生的 `.wsp` 一致 | （選測）用紫色 VS 對同 commit 打包，比對 manifest.xml | 結構等價（GUID 順序可不同） | `[ ]` |

**Stage 4 通過條件：** D1～D5 必填全部 `[x]`；D6 為選測（建議至少一次）。

---

## 6. Stage 5：Deploy / Update / Retract 驗證（公司 SharePoint Server）

⚠️ 本 Stage 會 **變更 SharePoint Server 狀態**。建議於 **測試 farm** 或 **獨立測試 Web Application** 執行，不要直接打 Production。

| # | 驗證項目 | 執行步驟 | 預期結果 | 勾選 |
|---|----------|----------|----------|------|
| E1 | `SharePoint: Deploy WSP` 成功 | Run Task → `SharePoint: Deploy WSP`，帶入 wsp 路徑與 Web App URL | task 結束 exit code 0，無 PowerShell 紅字 | `[ ]` |
| E2 | Central Administration 顯示 Deployed | CA → System Settings → Manage farm solutions | 該 solution 狀態為 `Deployed` | `[ ]` |
| E3 | Feature 可啟用 / 站台行為正常 | Site Settings → Site features，啟用對應 Feature 後操作站台 | Feature 啟用成功，站台無 500 / Correlation ID 錯誤 | `[ ]` |
| E4 | ULS log 無關鍵錯誤 | `Merge-SPLogFile -Path "deploy.log" -StartTime (Get-Date).AddMinutes(-10)` 後檢視 | 無 `Unexpected` 等級之部署相關錯誤 | `[ ]` |
| E5 | `SharePoint: Update WSP` 成功 | 修改某 cs 檔 → Package → Run Task `SharePoint: Update WSP` | exit code 0，站台行為反映新版 | `[ ]` |
| E6 | `SharePoint: Retract WSP` 成功 | Run Task → `SharePoint: Retract WSP`，帶入 solution 名稱與 Web App URL | CA 中 solution 狀態變為 `Not Deployed` | `[ ]` |
| E7 | Retract + Remove from Farm 乾淨 | Run Task → `SharePoint: Retract WSP (All Web Apps + Remove from Farm)` | CA 中該 solution 完全消失 | `[ ]` |
| E8 | 移除後重新 Deploy 不殘留 | 重跑 `SharePoint: Deploy WSP` | 部署成功且無「solution already exists」之類錯誤 | `[ ]` |

**Stage 5 通過條件：** E1～E8 全部 `[x]`。

---

## 7. Stage 6：取代 Visual Studio 整體驗收

此 Stage 是「最終假設驗證」：藍色 VS Code 真的能取代紫色 Visual Studio 嗎？

| # | 驗證項目 | 執行步驟 | 預期結果 | 勾選 |
|---|----------|----------|----------|------|
| F1 | 整輪流程未啟動 `devenv.exe` | 從 Stage 4 起，全程透過工作管理員確認 devenv.exe 未啟動 | 工作管理員無 `devenv.exe` 處理程序 | `[ ]` |
| F2 | 不依賴 Visual Studio Designer | 過程中未使用 Package Designer / Feature Designer / Server Explorer UI | 無 | `[ ]` |
| F3 | 重複跑 Build → Package → Validate 三次穩定 | 連續執行三次，結果一致、`.wsp` 大小與內容相同（時間戳除外） | 三次皆通過、可重現 | `[ ]` |
| F4 | 重複跑 Deploy → Update → Retract 三輪穩定 | 同上 | 三輪皆通過 | `[ ]` |
| F5 | 第二人獨立完成 PoC | 同事或不同帳號照本清單從 Stage 1 重做一次 | 全部 `[x]` | `[ ]` |
| F6 | 已知失敗點都能照 §9 排查 | 任一 Fail 都能對應到 PoC runbook §6 的處理 | 無「無法解決」狀態 | `[ ]` |
| F7 | 與紫色 VS 的差異紀錄完成 | 列出本清單未涵蓋、仍需要紫色 VS 的場景（若有） | 差異清單已存檔 | `[ ]` |

**Stage 6 通過條件：** F1～F6 必填全部 `[x]`；F7 視專案而定，若無差異則註明「無」。

---

## 8. 驗收紀錄表

| Stage | 通過日期 | 執行人 | 環境（本機 / 公司測試 / 公司 Prod） | 備註 |
|-------|----------|--------|--------------------------------------|------|
| 1. 本機環境 |  |  |  |  |
| 2. VS Code 編輯能力 |  |  |  |  |
| 3. 公司電腦環境 |  |  |  |  |
| 4. Build / Package / Validate |  |  |  |  |
| 5. Deploy / Update / Retract |  |  |  |  |
| 6. 整體取代驗收 |  |  |  |  |

---

## 9. 失敗對策參考索引

| Stage / 項目 | 常見症狀 | 對應參考 |
|--------------|----------|----------|
| A2、A3、B2、B3 | IntelliSense 不出、無法跳轉 | `vscode-sharepoint-dotnet-framework-feasibility.md` §「建議 VS Code workspace 設定」 |
| C4、C5 | PowerShell snap-in 找不到 | `vscode-sharepoint-poc-runbook.md` §3 |
| C1、C2、C9、D1 | MSBuild 找不到 / SharePoint targets 缺失 | `vscode-sharepoint-poc-runbook.md` §2 |
| C6、C7、C8 | 部署權限 / Execution Policy / ConstrainedLanguage | `vscode-sharepoint-poc-runbook.md` §3.4、§3.5 |
| D5 | Validate Package 報錯 | `vscode-sharepoint-poc-runbook.md` §6（reference assemblies / SharePoint targets 列） |
| E1～E8 | Deploy 後狀態異常 / Update 沒生效 / Retract 殘留 | `vscode-sharepoint-poc-runbook.md` §6（Deploy/Update/Retract 列） |
| F3、F4 | 不可重現 | 回 PoC runbook §6 + 紀錄 ULS log，回填至依賴順序文件 §9「修正與模板化」 |

---

## 10. 最終驗收聲明

當以下條件全數成立時，本驗收完成：

- [ ] Stage 1 通過（A1～A4 全 `[x]`）。
- [ ] Stage 2 通過（B1～B8 全 `[x]`）。
- [ ] Stage 3 通過（C1～C9 全 `[x]`）。
- [ ] Stage 4 通過（D1～D5 全 `[x]`，D6 已紀錄結果）。
- [ ] Stage 5 通過（E1～E8 全 `[x]`）。
- [ ] Stage 6 通過（F1～F6 全 `[x]`，F7 已紀錄差異）。

驗收結論：

> 本人確認：在公司電腦與公司 SharePoint Server 環境下，藍色 Visual Studio Code 透過本 repo 的 `scripts/` 與 `.vscode/tasks.json` 工作流，**已可完整承接** SharePoint Server / `.NET Framework` 專案的編輯、build、package、validate、deploy、update、retract 流程，**不再需要紫色 Visual Studio** 作為日常 IDE。

| 角色 | 姓名 | 簽署日期 |
|------|------|----------|
| 驗收人 |  |  |
| 第二驗收人（F5 對象） |  |  |
| 專案負責人 |  |  |

---

## 附錄：本驗收清單與相關文件對應

| 文件 | 角色 |
|------|------|
| [`framework.md`](./framework.md) | 原始需求與問題 |
| [`vscode-sharepoint-dotnet-framework-feasibility.md`](./vscode-sharepoint-dotnet-framework-feasibility.md) | 可行性評估（決策依據） |
| [`vscode-sharepoint-workflow-dependency-order.md`](./vscode-sharepoint-workflow-dependency-order.md) | 工作流依賴順序與交接任務表 |
| [`vscode-sharepoint-poc-runbook.md`](./vscode-sharepoint-poc-runbook.md) | 公司電腦 PoC 操作手冊（教 **怎麼操作**） |
| **`vscode-sharepoint-acceptance-checklist.md`（本文件）** | 使用者驗收清單（驗 **能不能取代 VS**） |
