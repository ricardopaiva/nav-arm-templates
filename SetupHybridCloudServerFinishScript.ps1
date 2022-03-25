. (Join-Path $PSScriptRoot "settings.ps1")

AddToStatus "Finishing the Hybrid Cloud Components installation"
Set-Location $HCCProjectDirectory

AddToStatus "Creating the POS Master and POS bundle"
& .\NewBundlePackage.ps1 -Import

AddToStatus "Installing the POS Master"
& .\UpdatePosMaster.ps1

if (Get-ScheduledTask -TaskName FinishHybridSetup -ErrorAction Ignore) {
    schtasks /DELETE /TN FinishHybridSetup /F | Out-Null
}
