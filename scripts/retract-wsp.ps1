#Requires -Version 5.1

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$SolutionName,
    [string]$WebApplicationUrl,
    [switch]$AllWebApplications,
    [switch]$RemoveFromFarm,
    [switch]$Local,
    [string]$Time
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Import-SharePointPowerShell {
    if ($null -ne (Get-Command -Name Uninstall-SPSolution -ErrorAction SilentlyContinue)) {
        return
    }

    $registeredSnapIn = Get-PSSnapin -Registered -Name "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue
    if ($null -ne $registeredSnapIn) {
        Add-PSSnapin -Name "Microsoft.SharePoint.PowerShell" -ErrorAction Stop
    }

    if ($null -eq (Get-Command -Name Uninstall-SPSolution -ErrorAction SilentlyContinue)) {
        throw "找不到 SharePoint PowerShell。請先在公司電腦安裝或啟用 SharePoint Management Shell。"
    }
}

function New-UninstallParameters {
    if ($AllWebApplications -and -not [string]::IsNullOrWhiteSpace($WebApplicationUrl)) {
        throw "AllWebApplications 與 WebApplicationUrl 只能擇一指定。"
    }

    if (-not $AllWebApplications -and [string]::IsNullOrWhiteSpace($WebApplicationUrl)) {
        throw "請指定 -WebApplicationUrl 或 -AllWebApplications。"
    }

    $parameters = @{
        Identity = $SolutionName
        Confirm = $false
    }

    if ($AllWebApplications) {
        $parameters["AllWebApplications"] = $true
    }
    else {
        $parameters["WebApplication"] = $WebApplicationUrl
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
$uninstallParameters = New-UninstallParameters

if ($PSCmdlet.ShouldProcess($SolutionName, "Retract SharePoint solution")) {
    Uninstall-SPSolution @uninstallParameters -ErrorAction Stop

    if ($RemoveFromFarm) {
        Remove-SPSolution -Identity $SolutionName -Confirm:$false -ErrorAction Stop
    }
}
