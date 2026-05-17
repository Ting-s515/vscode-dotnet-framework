#Requires -Version 5.1

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$WspPath,
    [string]$SolutionName,
    [switch]$DeployToGac,
    [switch]$Force,
    [switch]$Local,
    [string]$Time
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Import-SharePointPowerShell {
    if ($null -ne (Get-Command -Name Update-SPSolution -ErrorAction SilentlyContinue)) {
        return
    }

    $registeredSnapIn = Get-PSSnapin -Registered -Name "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue
    if ($null -ne $registeredSnapIn) {
        Add-PSSnapin -Name "Microsoft.SharePoint.PowerShell" -ErrorAction Stop
    }

    if ($null -eq (Get-Command -Name Update-SPSolution -ErrorAction SilentlyContinue)) {
        throw "找不到 SharePoint PowerShell。請先在公司電腦安裝或啟用 SharePoint Management Shell。"
    }
}

function Resolve-WspFilePath {
    if (-not (Test-Path -LiteralPath $WspPath -PathType Leaf)) {
        throw "找不到 WSP：$WspPath"
    }

    return (Resolve-Path -LiteralPath $WspPath).ProviderPath
}

function Resolve-SolutionIdentity {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResolvedWspPath
    )

    if (-not [string]::IsNullOrWhiteSpace($SolutionName)) {
        return $SolutionName
    }

    return [System.IO.Path]::GetFileName($ResolvedWspPath)
}

function New-UpdateParameters {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Identity,
        [Parameter(Mandatory = $true)]
        [string]$LiteralPath
    )

    $parameters = @{
        Identity = $Identity
        LiteralPath = $LiteralPath
        Confirm = $false
    }

    if ($DeployToGac) {
        $parameters["GACDeployment"] = $true
    }

    if ($Force) {
        $parameters["Force"] = $true
    }

    if ($Local) {
        $parameters["Local"] = $true
    }

    if (-not [string]::IsNullOrWhiteSpace($Time)) {
        $parameters["Time"] = $Time
    }

    return $parameters
}

Import-SharePointPowerShell
$resolvedWspPath = Resolve-WspFilePath
$solutionIdentity = Resolve-SolutionIdentity -ResolvedWspPath $resolvedWspPath
$updateParameters = New-UpdateParameters -Identity $solutionIdentity -LiteralPath $resolvedWspPath

if ($PSCmdlet.ShouldProcess($solutionIdentity, "Update SharePoint solution")) {
    Update-SPSolution @updateParameters -ErrorAction Stop
}
