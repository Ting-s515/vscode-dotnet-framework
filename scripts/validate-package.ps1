#Requires -Version 5.1

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
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

function Resolve-ProjectFilePath {
    if (-not (Test-Path -LiteralPath $ProjectPath -PathType Leaf)) {
        throw "找不到 project：$ProjectPath"
    }

    return (Resolve-Path -LiteralPath $ProjectPath).ProviderPath
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
$resolvedProjectPath = Resolve-ProjectFilePath
$arguments = @(
    $resolvedProjectPath,
    "/t:ValidatePackage",
    "/p:Configuration=$Configuration",
    "/p:Platform=$Platform"
)
$arguments += Convert-ToMsBuildProperties -Properties $AdditionalProperties
$arguments += $AdditionalArguments

Write-Host "MSBuild: $resolvedMsBuild"
Write-Host "Project: $resolvedProjectPath"

& $resolvedMsBuild @arguments
if ($LASTEXITCODE -ne 0) {
    throw "MSBuild validate package 失敗，exit code：$LASTEXITCODE"
}
