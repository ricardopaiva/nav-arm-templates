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

# if (!($imageName)) {
#    Remove-Item -path "c:\demo\status.txt" -Force -ErrorAction SilentlyContinue
# }
AddToStatus "Installation finished successfully. Will restart now."
# Move-Item -path "c:\demo\status.txt" "c:\demo\status-archive.txt" -Force -ErrorAction SilentlyContinue

shutdown -r -t 30