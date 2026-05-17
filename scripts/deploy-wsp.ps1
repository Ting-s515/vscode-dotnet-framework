#Requires -Version 5.1

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$WspPath,
    [string]$SolutionName,
    [string]$WebApplicationUrl,
    [switch]$AllWebApplications,
    [switch]$DeployToGac,
    [switch]$Force,
    [switch]$Local,
    [string]$CompatibilityLevel,
    [string]$Time
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Import-SharePointPowerShell {
    if ($null -ne (Get-Command -Name Add-SPSolution -ErrorAction SilentlyContinue)) {
        return
    }

    $registeredSnapIn = Get-PSSnapin -Registered -Name "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue
    if ($null -ne $registeredSnapIn) {
        Add-PSSnapin -Name "Microsoft.SharePoint.PowerShell" -ErrorAction Stop
    }

    if ($null -eq (Get-Command -Name Add-SPSolution -ErrorAction SilentlyContinue)) {
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

function New-InstallParameters {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Identity
    )

    if ($AllWebApplications -and -not [string]::IsNullOrWhiteSpace($WebApplicationUrl)) {
        throw "AllWebApplications 與 WebApplicationUrl 只能擇一指定。"
    }

    if (-not $AllWebApplications -and [string]::IsNullOrWhiteSpace($WebApplicationUrl)) {
        throw "請指定 -WebApplicationUrl 或 -AllWebApplications。"
    }

    $parameters = @{
        Identity = $Identity
        Confirm = $false
    }

    if ($AllWebApplications) {
        $parameters["AllWebApplications"] = $true
    }
    else {
        $parameters["WebApplication"] = $WebApplicationUrl
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

    if (-not [string]::IsNullOrWhiteSpace($CompatibilityLevel)) {
        $parameters["CompatibilityLevel"] = $CompatibilityLevel
    }

    if (-not [string]::IsNullOrWhiteSpace($Time)) {
        $parameters["Time"] = $Time
    }

    return $parameters
}

Import-SharePointPowerShell
$resolvedWspPath = Resolve-WspFilePath
$solutionIdentity = Resolve-SolutionIdentity -ResolvedWspPath $resolvedWspPath
$installParameters = New-InstallParameters -Identity $solutionIdentity

if ($PSCmdlet.ShouldProcess($solutionIdentity, "Add and install SharePoint solution")) {
    Add-SPSolution -LiteralPath $resolvedWspPath -ErrorAction Stop | Out-Null
    Install-SPSolution @installParameters -ErrorAction Stop
}
