# VS Code 支援 SharePoint / .NET Framework 開發可行性評估

## 背景

本評估延續 `docs/framework.md` 的問題脈絡：希望保留藍色 Visual Studio Code 的輕量工作流，避免依賴紫色 Visual Studio 作為日常主要 IDE，同時仍能支援公司 Windows Server / SharePoint Server 專案所需的 `.NET Framework` 開發、打包與部署流程。

補充需求如下：

1. 主要場景是 SharePoint Server / Windows Server 相關開發。
2. 需要支援建置、`.wsp` 打包、部署或更新。
3. 不需要 WinForms / WPF / Razor 視覺化設計器。
4. 目標不是重做完整 Visual Studio，而是讓 VS Code 承接日常開發流程。

## 結論

可行，但定位應是「VS Code + MSBuild + PowerShell 的 SharePoint 開發工作流」，不是「VS Code 完整取代 Visual Studio SharePoint IDE」。

VS Code 可以作為主要編輯器，負責 C#、XML、PowerShell、設定檔與部署腳本維護；建置與打包應交給 MSBuild；部署應交給 SharePoint Management Shell / PowerShell cmdlet。

此方案適合目前需求，因為本案明確不需要 WinForms、WPF、Razor 或拖拉式 Designer。若未來需求包含 Visual Studio SharePoint Project Template、Package Designer、Feature Designer、Server Explorer 等視覺化工具，VS Code 方案會明顯不足。

## 可行範圍

VS Code 可承接下列工作：

1. 編輯 `.sln`、`.csproj`、C# 原始碼、Feature XML、Elements XML、Package XML。
2. 透過 C# extension / OmniSharp 提供 legacy `.NET Framework` 專案的基本 IntelliSense、跳轉、重構與診斷。
3. 透過 `.vscode/tasks.json` 包裝建置、打包、驗證與部署命令。
4. 透過 MSBuild target 執行 SharePoint package：
   - `msbuild /t:Package ProjectFileName.csproj`
   - `msbuild /t:ValidatePackage ProjectFileName.csproj`
   - `msbuild /t:CleanPackage ProjectFileName.csproj`
5. 透過 PowerShell / SharePoint Management Shell 部署 `.wsp`：
   - `Add-SPSolution`
   - `Install-SPSolution`
   - `Update-SPSolution`
   - `Uninstall-SPSolution`
   - `Remove-SPSolution`
6. 將建置、打包、部署流程版本化，降低對個人 IDE 設定的依賴。

## 不建議承諾的範圍

VS Code 不應承諾完整取代下列 Visual Studio SharePoint 工具：

1. SharePoint 專案範本 UI。
2. Package Designer / Feature Designer。
3. Server Explorer 與 SharePoint 站台瀏覽 UI。
4. Visual Studio 內建的 Deploy command 完整體驗。
5. 依賴 Visual Studio Designer 的 Windows UI 開發。

這些功能即使可以部分用 XML、PowerShell 或自製 extension 補足，也不應視為短期內能低成本完整復刻。

## 建議技術路線

第一階段先建立可重複執行的命令列工作流，不急著開發 VS Code extension。

建議優先產出：

1. `.vscode/settings.json`
   - 啟用 OmniSharp legacy 模式。
   - 避免 C# Dev Kit 對 `.NET Framework` 專案造成不相容接管。
2. `.vscode/tasks.json`
   - `build`
   - `package`
   - `validate-package`
   - `deploy-wsp`
   - `update-wsp`
   - `retract-wsp`
3. `scripts/`
   - `build.ps1`
   - `package.ps1`
   - `deploy-wsp.ps1`
   - `update-wsp.ps1`
   - `retract-wsp.ps1`
4. 專案 README 或操作手冊
   - 記錄必要工具、環境變數、SharePoint 伺服器權限與部署步驟。

第二階段再評估是否開發 VS Code extension。extension 的價值應集中在「把穩定的 tasks / scripts 包成按鈕與 Command Palette 命令」，而不是重做 Visual Studio Designer。

## 必要環境

Windows 開發機或可連到 SharePoint Server 的部署環境需要具備：

1. Visual Studio Code。
2. `ms-dotnettools.csharp` extension。
3. `.NET Framework Developer Pack`，版本需符合專案 Target Framework。
4. Visual Studio Build Tools 或其他可提供 `MSBuild.exe` 的工具鏈。
5. SharePoint Server 開發/部署所需 assembly、targets 或相關 SDK。
6. SharePoint Management Shell 或可載入 SharePoint PowerShell snap-in/module 的 PowerShell 環境。
7. 足夠部署權限，例如 Farm Administrator 或被授權執行 solution 部署的帳號。

建議 VS Code workspace 設定：

```json
{
  "dotnet.server.useOmnisharp": true,
  "omnisharp.useModernNet": false
}
```

## 決策理由

此方案可行的原因：

1. SharePoint `.wsp` 打包可由 MSBuild target 執行，不必只能透過 Visual Studio UI。
2. SharePoint solution 部署可由 PowerShell cmdlet 執行，不必只能透過 Visual Studio Deploy command。
3. 本案不需要 Windows 桌面 UI Designer，因此 VS Code 最大缺口不影響主要目標。
4. 以 script / task 固化流程，比依賴 IDE UI 更適合公司專案標準化與 CI/CD 延伸。

主要風險：

1. Legacy `.NET Framework` 專案在 VS Code 的 C# 體驗不如現代 SDK-style `.NET` 專案。
2. C# Dev Kit 明確不支援 `.NET Framework` projects，需改用 C# extension / OmniSharp legacy 模式。
3. SharePoint 專案可能依賴 Visual Studio 安裝的 SharePoint targets 或特定 registry/path 設定，需要逐案驗證。
4. 部署 SharePoint solution 牽涉 IIS、GAC、Feature activation、Timer Service 等伺服器狀態，需用腳本清楚處理錯誤與回滾。

## 建議決策

採用 VS Code 作為主要工作流是合理的，但應採「命令列驅動」策略：

1. 短期：建立 VS Code tasks + PowerShell scripts，先讓 build / package / deploy 可重複執行。
2. 中期：整理公司專案通用腳本模板與環境檢查腳本。
3. 長期：若多個專案都使用同一套流程，再開發 VS Code extension 封裝命令與狀態提示。

不建議第一步就開發大型 extension。因為真正高風險的部分不是 VS Code UI，而是 SharePoint legacy build targets、部署權限、伺服器狀態與 `.wsp` 更新流程是否穩定。

## 參考依據

1. VS Code C# 官方文件：`https://code.visualstudio.com/docs/languages/csharp`
2. C# Dev Kit FAQ：`https://code.visualstudio.com/docs/csharp/cs-dev-kit-faq`
3. 官方 C# extension repository：`https://github.com/dotnet/vscode-csharp`
4. MSBuild 官方文件：`https://learn.microsoft.com/en-us/visualstudio/msbuild/msbuild`
5. SharePoint solution package MSBuild tasks：`https://learn.microsoft.com/en-us/visualstudio/sharepoint/how-to-create-a-sharepoint-solution-package-by-using-msbuild-tasks`
6. SharePoint solution deploy / publish：`https://learn.microsoft.com/en-us/visualstudio/sharepoint/deploying-publishing-and-upgrading-sharepoint-solution-packages`
7. SharePoint `Install-SPSolution` PowerShell：`https://learn.microsoft.com/en-us/powershell/module/sharepoint-server/install-spsolution`
