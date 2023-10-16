Import-Module (Join-Path $PSScriptRoot "Helpers.ps1") -Force

AddToStatus -color Green "Current File: SetupHybridCloudServerFinal.ps1"

. (Join-Path $PSScriptRoot "settings.ps1")

if ($enableTranscription) {
    Enable-Transcription
}

if (Get-ScheduledTask -TaskName FinishHybridSetup -ErrorAction Ignore) {
    schtasks /DELETE /TN FinishHybridSetup /F | Out-Null
}

AddToStatus "Who is running this: $(whoami)"
AddToStatus "Finishing the Hybrid Cloud Components installation"
Set-Location $HCCProjectDirectory

Start-Sleep -Seconds 30 # wait for 30 seconds before next attempt, for IIS (US Server) and other services to start, avoiding connection issues when running the UpdatePosMaster.ps1
AddToStatus "Installing the POS Master (this might take a while)"
& .\UpdatePosMaster.ps1

. "c:\demo\SetupDataDirectorConfig.ps1"

AddToStatus -color Green "Current File: Back to SetupHybridCloudServerFinal.ps1"

AddToStatus "Installation finished successfully."
AddToStatus "The hybrid cloud setup is now finished."
AddToStatus "Will restart now."
# Move-Item -path "c:\demo\status.txt" "c:\demo\status-archive.txt" -Force -ErrorAction SilentlyContinue

shutdown -r -t 30