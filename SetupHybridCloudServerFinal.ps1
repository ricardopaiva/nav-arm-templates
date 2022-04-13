if (!(Test-Path function:AddToStatus)) {
    function AddToStatus([string]$line, [string]$color = "Gray") {
        ("<font color=""$color"">" + [DateTime]::Now.ToString([System.Globalization.DateTimeFormatInfo]::CurrentInfo.ShortDatePattern) + " " + [DateTime]::Now.ToString([System.Globalization.DateTimeFormatInfo]::CurrentInfo.ShortTimePattern.replace(":mm",":mm:ss")) + " $line</font>") | Add-Content -Path "c:\demo\status.txt" -Force -ErrorAction SilentlyContinue
        Write-Host -ForegroundColor $color $line 
    }
}

. (Join-Path $PSScriptRoot "settings.ps1")

AddToStatus "Who is running this: $(whoami)"
AddToStatus "Finishing the Hybrid Cloud Components installation"
Set-Location $HCCProjectDirectory

# AddToStatus "Creating the POS Master and POS bundle"
# & .\NewBundlePackage.ps1 -Import

AddToStatus "Installing the POS Master"
& .\UpdatePosMaster.ps1

AddToStatus "TO REMOVE: Finished installing the POS Master"

. "c:\demo\SetupDataDirectorConfig.ps1"

if (Get-ScheduledTask -TaskName FinishHybridSetup -ErrorAction Ignore) {
    AddToStatus "TO REMOVE: Will remove FinishHybridSetup task"
    schtasks /DELETE /TN FinishHybridSetup /F | Out-Null
}

# if (!($imageName)) {
#    Remove-Item -path "c:\demo\status.txt" -Force -ErrorAction SilentlyContinue
# }
AddToStatus "Installation finished successfully. Will restart now."
# Move-Item -path "c:\demo\status.txt" "c:\demo\status-archive.txt" -Force -ErrorAction SilentlyContinue

shutdown -r -t 30