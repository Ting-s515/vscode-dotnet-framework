#Requires -Version 5.1

[CmdletBinding()]
param(
    [string]$SolutionPath,
    [string]$ProjectPath,
    [string]$Configuration = "Debug",
    [string]$Platform = "Any CPU",
    [string]$MsBuildPath = "msbuild.exe",
    [string[]]$AdditionalProperties = @(),
    [string[]]$AdditionalArguments = @()
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Resolve-ExecutablePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if ([System.IO.Path]::IsPathRooted($Path)) {
        if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
            throw "找不到指定的 MSBuild.exe：$Path"
        }

        return (Resolve-Path -LiteralPath $Path).ProviderPath
    }

    $command = Get-Command -Name $Path -CommandType Application -ErrorAction SilentlyContinue
    if ($null -eq $command) {
        throw "找不到 MSBuild.exe，請指定 -MsBuildPath 或先安裝 Visual Studio Build Tools。"
    }

    return $command.Source
}

function Resolve-BuildTargetPath {
    if (-not [string]::IsNullOrWhiteSpace($SolutionPath) -and -not [string]::IsNullOrWhiteSpace($ProjectPath)) {
        throw "SolutionPath 與 ProjectPath 只能擇一指定。"
    }

    if (-not [string]::IsNullOrWhiteSpace($SolutionPath)) {
        if (-not (Test-Path -LiteralPath $SolutionPath -PathType Leaf)) {
            throw "找不到 solution：$SolutionPath"
        }

        return (Resolve-Path -LiteralPath $SolutionPath).ProviderPath
    }

    if (-not [string]::IsNullOrWhiteSpace($ProjectPath)) {
        if (-not (Test-Path -LiteralPath $ProjectPath -PathType Leaf)) {
            throw "找不到 project：$ProjectPath"
        }

        return (Resolve-Path -LiteralPath $ProjectPath).ProviderPath
    }

    throw "請指定 -SolutionPath 或 -ProjectPath。"
}

function Convert-ToMsBuildProperties {
    param(
        [string[]]$Properties
    )

    $items = @()
    foreach ($property in $Properties) {
        if ([string]::IsNullOrWhiteSpace($property)) {
            continue
        }

        if ($property.StartsWith("/p:", [System.StringComparison]::OrdinalIgnoreCase)) {
            $items += $property
            continue
        }

        $items += "/p:$property"
    }

    return $items
}

$resolvedMsBuild = Resolve-ExecutablePath -Path $MsBuildPath
$targetPath = Resolve-BuildTargetPath
$arguments = @(
    $targetPath,
    "/t:Build",
    "/p:Configuration=$Configuration",
    "/p:Platform=$Platform"
)
$arguments += Convert-ToMsBuildProperties -Properties $AdditionalProperties
$arguments += $AdditionalArguments

Write-Host "MSBuild: $resolvedMsBuild"
Write-Host "Target: $targetPath"

& $resolvedMsBuild @arguments
if ($LASTEXITCODE -ne 0) {
    throw "MSBuild build 失敗，exit code：$LASTEXITCODE"
}
