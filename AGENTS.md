# Repository Guidelines

## Project Structure & Module Organization

This repository documents and prototypes a lightweight VS Code workflow for legacy SharePoint / `.NET Framework` development.

- `docs/`: planning, feasibility notes, dependency order, and PoC handoff documentation.
- `scripts/`: PowerShell templates for MSBuild packaging and SharePoint WSP operations.
- `.vscode/`: not yet present; future VS Code task definitions should live here.

There is currently no application source tree or formal test directory. Add new implementation files only when they support the documented workflow.

## Build, Test, and Development Commands

This project is mostly documentation plus PowerShell templates. Do not run SharePoint deployment locally unless the machine is a prepared company SharePoint environment.

Useful checks:

```powershell
git status --short
git diff --check
```

Validate PowerShell syntax without executing deployment logic:

```powershell
$files = Get-ChildItem scripts -Filter *.ps1
foreach ($file in $files) {
  $tokens = $null
  $errors = $null
  [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$errors) | Out-Null
  if ($errors.Count -gt 0) { throw "PowerShell syntax error in $($file.Name)" }
}
```

Actual SharePoint build/package/deploy validation belongs on the company machine after MSBuild, `.NET Framework Developer Pack`, and SharePoint PowerShell are available.

## Coding Style & Naming Conventions

Use concise PowerShell 5.1-compatible scripts. Keep parameters explicit and avoid hardcoded company paths, server URLs, or project names. Prefer names that describe the workflow action, such as `build.ps1`, `package.ps1`, and `deploy-wsp.ps1`.

Comments should explain why a non-obvious decision exists, not restate simple code.

## Testing Guidelines

No automated test framework is configured yet. For scripts, minimum validation is PowerShell parser syntax checking. SharePoint behavior must be verified through a company-environment PoC and documented in `docs/`.

## Commit & Pull Request Guidelines

Use Conventional Commits, as seen in history:

- `docs: 擴充 SharePoint 執行清單狀態`
- `feat: 新增 SharePoint 工作流腳本模板`

PRs should include a short purpose statement, changed files, validation performed, and any blocked validation. For workflow changes, link the relevant document in `docs/` and explain whether company SharePoint validation is still pending.

## Agent-Specific Instructions

Before changing files, check current status and avoid staging unrelated work. Commit only files changed for the current task. Pure documentation changes may skip build and code review; script or workflow changes require syntax validation and review before commit.
