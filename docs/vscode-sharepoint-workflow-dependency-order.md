# VS Code SharePoint 工作流依賴步驟順序

## 目的

本文件記錄從「可行性評估」推進到「公司 SharePoint 環境實測」之前的依賴順序。

目前限制是本機沒有 Windows Server / SharePoint Server 環境，因此不在本機驗證 SharePoint 是否可建置、打包或部署。現階段只先產出可攜式工作流模板與操作規格，等到公司電腦或公司伺服器環境再進行 PoC 驗證。

## 決策前提

1. 主要目標是保留 VS Code 輕量工作流。
2. 目標專案是 SharePoint Server / `.NET Framework` 專案。
3. 需要支援 build、package `.wsp`、deploy、update、retract。
4. 不需要 WinForms、WPF、Razor 或其他視覺化 Designer。
5. 本機不驗證 SharePoint runtime，SharePoint 相關驗證移到公司電腦執行。
6. 優先建立命令列與 VS Code tasks 流程，不優先開發 VS Code extension。
7. 不預設公司電腦已具備 SharePoint PowerShell；安裝或確認 SharePoint PowerShell 可用是公司端前置步驟。

## 依賴順序總覽

```mermaid
flowchart TD
    A[確認目標工作流] --> B[設計可攜式參數]
    B --> C[建立 scripts 模板]
    C --> D[建立 VS Code tasks]
    D --> E[撰寫操作文件]
    E --> F[帶到公司電腦設定環境]
    F --> G[安裝或確認 SharePoint PowerShell]
    G --> H[使用真實 SharePoint 專案 PoC]
    H --> I{PoC 是否穩定}
    I -->|是| J[整理共用模板]
    I -->|否| K[修正 scripts 與 tasks]
    K --> H
    J --> L[評估是否開發 VS Code extension]
```

## 步驟 1：確認目標工作流

執行位置：本機。

目的：先定義 VS Code 要承接哪些操作，避免把範圍擴大成完整 Visual Studio 替代品。

輸出：

1. VS Code 負責編輯。
2. MSBuild 負責 build。
3. MSBuild target 負責 package `.wsp`。
4. PowerShell / SharePoint Management Shell 負責 deploy、update、retract。
5. VS Code tasks 負責把常用命令整合成可執行任務。

此步驟完成後，才能進入參數設計。

## 步驟 2：設計可攜式參數

執行位置：本機。

目的：避免腳本硬編碼公司電腦路徑、伺服器 URL 或專案名稱。

建議參數：

1. `SolutionPath`
2. `ProjectPath`
3. `Configuration`
4. `Platform`
5. `MsBuildPath`
6. `PackageOutputPath`
7. `WspPath`
8. `SolutionName`
9. `WebApplicationUrl`
10. `DeployToGac`
11. `Force`

此步驟完成後，才能開始建立 scripts 模板。

## 步驟 3：建立 scripts 模板

執行位置：本機。

目的：先把 SharePoint 工作流拆成可重複執行的 PowerShell 腳本。這些腳本在本機只做語法與參數設計，不驗證 SharePoint 實際行為。

建議檔案：

```text
scripts/
  build.ps1
  package.ps1
  validate-package.ps1
  deploy-wsp.ps1
  update-wsp.ps1
  retract-wsp.ps1
```

腳本職責：

1. `build.ps1`：呼叫 MSBuild 執行專案或 solution build。
2. `package.ps1`：呼叫 MSBuild `/t:Package` 產生 `.wsp`。
3. `validate-package.ps1`：呼叫 MSBuild `/t:ValidatePackage` 驗證 package。
4. `deploy-wsp.ps1`：呼叫 SharePoint PowerShell 新增與安裝 solution。
5. `update-wsp.ps1`：呼叫 SharePoint PowerShell 更新既有 solution。
6. `retract-wsp.ps1`：呼叫 SharePoint PowerShell 解除安裝與移除 solution。

此步驟完成後，才能建立 VS Code tasks。

## 步驟 4：建立 VS Code tasks

執行位置：本機。

目的：讓 VS Code 可透過 command palette 或 task runner 執行 scripts。

建議檔案：

```text
.vscode/
  settings.json
  tasks.json
```

建議 tasks：

1. `SharePoint: Build`
2. `SharePoint: Package WSP`
3. `SharePoint: Validate Package`
4. `SharePoint: Deploy WSP`
5. `SharePoint: Update WSP`
6. `SharePoint: Retract WSP`

此步驟依賴 scripts 模板，因為 tasks 只負責呼叫腳本，不直接承擔部署邏輯。

## 步驟 5：撰寫操作文件

執行位置：本機。

目的：讓公司電腦驗證時可以照文件準備環境與執行 PoC。

操作文件需包含：

1. 必要工具清單。
2. VS Code extension 建議。
3. `.NET Framework Developer Pack` 版本對應方式。
4. `MSBuild.exe` 尋找方式。
5. SharePoint PowerShell / SharePoint Management Shell 安裝或啟用步驟。
6. 部署帳號權限前提。
7. 第一次 PoC 的執行順序。
8. 常見失敗點與排查方向。

此步驟完成後，才適合切到公司電腦進行驗證。

## 步驟 6：公司電腦基礎環境設定

執行位置：公司電腦或可連到 SharePoint Server 的環境。

目的：確認公司電腦具備實際建置與打包 SharePoint solution 的條件。SharePoint PowerShell 不在此步驟假設已存在，需於下一步明確安裝或確認。

需確認：

1. `MSBuild.exe` 可用。
2. 目標 `.NET Framework Developer Pack` 已安裝。
3. SharePoint project targets / assemblies 可被找到。
4. 真實專案可在不開 Visual Studio 的情況下被命令列建置。

此步驟完成後，才能進入 SharePoint PowerShell 前置設定。

## 步驟 7：安裝或確認 SharePoint PowerShell

執行位置：公司電腦或可連到 SharePoint Server 的環境。

目的：把 SharePoint solution 部署能力當成明確前置依賴，而不是隱含假設。

需確認：

1. SharePoint PowerShell / SharePoint Management Shell 已安裝或可啟用。
2. PowerShell 可以載入 SharePoint 管理指令所需 module、snap-in 或管理工具。
3. 可執行 solution 部署相關 cmdlet，例如 `Add-SPSolution`、`Install-SPSolution`、`Update-SPSolution`、`Uninstall-SPSolution`、`Remove-SPSolution`。
4. 執行者具有部署 solution 的權限。
5. PowerShell execution policy 不會阻擋專案 scripts 執行。

此步驟完成後，才能進入真實專案 PoC。

## 步驟 8：真實 SharePoint 專案 PoC

執行位置：公司電腦或可連到 SharePoint Server 的環境。

目的：用公司真實專案驗證 VS Code 工作流是否成立。

建議順序：

1. 在 VS Code 開啟專案。
2. 執行 `SharePoint: Build`。
3. 執行 `SharePoint: Package WSP`。
4. 執行 `SharePoint: Validate Package`。
5. 執行 `SharePoint: Deploy WSP` 或 `SharePoint: Update WSP`。
6. 到 SharePoint Server 確認 solution 與 feature 狀態。

成功標準：

1. 不開紫色 Visual Studio 也能完成 build。
2. 不開紫色 Visual Studio 也能產生 `.wsp`。
3. 不開紫色 Visual Studio 也能部署或更新 solution。
4. 部署結果可在 SharePoint Server 上被確認。

## 步驟 9：修正與模板化

執行位置：本機與公司電腦都可能需要。

目的：根據 PoC 結果修正 scripts、tasks 與文件。

常見調整：

1. 補上公司專案特有的 MSBuild property。
2. 補上 SharePoint solution 更新前後的等待與狀態檢查。
3. 補上 IIS reset 或服務重啟策略。
4. 補上 Feature activation / deactivation 步驟。
5. 補上錯誤訊息與 exit code 處理。

此步驟需反覆執行，直到流程穩定。

## 步驟 10：評估 VS Code extension

執行位置：本機。

前提：只有在 scripts 與 tasks 已穩定後才評估 extension。

extension 可做的事：

1. 提供 Command Palette 指令。
2. 提供側邊欄按鈕。
3. 顯示目前 project / solution / WSP 設定。
4. 呼叫既有 PowerShell scripts。
5. 顯示 build / package / deploy 結果。

extension 不應做的事：

1. 不直接重寫 SharePoint 部署邏輯。
2. 不重做 Visual Studio Designer。
3. 不把公司環境路徑硬編碼在 extension 內。

## 目前下一步

目前應先執行：

1. 建立 scripts 模板。
2. 建立 VS Code tasks 模板。
3. 撰寫公司電腦 PoC 操作文件。
4. 在操作文件中加入 SharePoint PowerShell / SharePoint Management Shell 安裝或啟用前置步驟。

## 明確執行清單

1. 先建立 `scripts/` 模板。
   - `build.ps1`
   - `package.ps1`
   - `validate-package.ps1`
   - `deploy-wsp.ps1`
   - `update-wsp.ps1`
   - `retract-wsp.ps1`

2. 再建立 `.vscode/tasks.json`。
   - `SharePoint: Build`
   - `SharePoint: Package WSP`
   - `SharePoint: Validate Package`
   - `SharePoint: Deploy WSP`
   - `SharePoint: Update WSP`
   - `SharePoint: Retract WSP`

3. 補一份公司電腦 PoC 操作文件。
   - 安裝或確認 SharePoint PowerShell / SharePoint Management Shell。
   - 確認 `MSBuild.exe`。
   - 確認 `.NET Framework Developer Pack`。
   - 修改腳本參數。
   - 用真實專案執行 build / package / deploy。

4. 等到公司電腦或 SharePoint Server 環境再實測。
   - 不開紫色 Visual Studio 能 build。
   - 能產生 `.wsp`。
   - 能透過 PowerShell deploy / update / retract。

暫不執行：

1. 本機 SharePoint 環境檢查。
2. 本機 SharePoint build/package/deploy 驗證。
3. VS Code extension 開發。
