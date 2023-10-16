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

$totalRetries = 0
do {
    $Failed = $false
    $response = $null
    try {
        AddToStatus "Testing the connection to Update Service server: http://$($env:computername):8060/api/v1/Settings/server"
        $response = Invoke-WebRequest -UseBasicParsing -Uri "http://$($env:computername):8060/api/v1/Settings/server"
        $response.StatusCode
    } catch { 
        $totalRetries += 1
        AddToStatus -color red "Error connecting to the Update Service server. Status code: $($response.StatusCode). Retrying..."
        AddToStatus -color red "Error connecting to the Update Service server. Total Retries: $($totalRetries)."

        AddToStatus -color red "Error connecting to the Update Service server: $($_)."
        AddToStatus -color red "Error connecting to the Update Service server. Exception: $($_.Exception)."
        AddToStatus -color red "Error connecting to the Update Service server. ScriptStackTrace: $($_.ScriptStackTrace)."
        AddToStatus -color red "Error connecting to the Update Service server. ErrorDetails: $($_.ErrorDetails)."
        Start-Sleep -Seconds 20 # wait for 20 seconds before next attempt.
        $Failed = $true
    }
} while (($Failed) -and ($totalRetries -lt 3) -and ($response.StatusCode -eq 200))

AddToStatus "Installing the POS Master (this might take a while)"
& .\UpdatePosMaster.ps1

. "c:\demo\SetupDataDirectorConfig.ps1"

AddToStatus -color Green "Current File: Back to SetupHybridCloudServerFinal.ps1"

AddToStatus "Installation finished successfully."
AddToStatus "The hybrid cloud setup is now finished."
AddToStatus "Will restart now."
# Move-Item -path "c:\demo\status.txt" "c:\demo\status-archive.txt" -Force -ErrorAction SilentlyContinue

shutdown -r -t 30