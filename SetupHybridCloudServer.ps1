if (!(Test-Path function:AddToStatus)) {
    function AddToStatus([string]$line, [string]$color = "Gray") {
        ("<font color=""$color"">" + [DateTime]::Now.ToString([System.Globalization.DateTimeFormatInfo]::CurrentInfo.ShortDatePattern) + " " + [DateTime]::Now.ToString([System.Globalization.DateTimeFormatInfo]::CurrentInfo.ShortTimePattern.replace(":mm",":mm:ss")) + " $line</font>") | Add-Content -Path "c:\demo\status.txt" -Force -ErrorAction SilentlyContinue
        Write-Host -ForegroundColor $color $line 
    }
}



. (Join-Path $PSScriptRoot "settings.ps1")

$Folder = "C:\DOWNLOAD\HybridCloudServerComponents"
$Filename = "$Folder\InstallGoCurrentClient.ps1"
New-Item $Folder -itemtype directory -ErrorAction ignore | Out-Null

if (!(Test-Path $Filename)) {
    AddToStatus "Downloading Update Service Client Installer Script"
    $WebClient = New-Object System.Net.WebClient
    $WebClient.DownloadFile("http://gc.lsretail.com:16551/ManagementFile/install", $Filename)
}

AddToStatus "Installing GoCurrent module"
. "$Filename"

AddToStatus "Installing SQL Server Express (this might take a while)"
Install-GocPackage -Id 'sql-server-express'

AddToStatus "Preparing SQL Server Studio Management (SSMS) installation (this might take a while)"
. "c:\demo\SetupSSMS.ps1"

AddToStatus "Installing LS Data Director Service"
Install-GocPackage -Id 'ls-dd-service'

AddToStatus "Enabling Web Services in LS Data Director"
$ddConfigFilename = "C:\ProgramData\LS Retail\Data Director\lsretail.config"
$dd_config = Get-Content $ddConfigFilename
$dd_config | % { $_.Replace("<WebSrv>false</WebSrv>", "<WebSrv>true</WebSrv>") } | Set-Content $ddConfigFilename

AddToStatus "Installing Update Service Server"
Install-GocPackage -Id 'go-current-server'

AddToStatus "Installing Update Service Server Management"
Install-GocPackage -Id 'go-current-server-management'

AddToStatus "Preparing Hybrid Cloud Components project"
$Arguments = @{
    'ls-central-hcc-project' = @{
        ProjectDir = $HCCProjectDirectory
        CompanyName = 'Cronus'
        PackageIdPrefix = 'cronus'
        Localization = $BCLocalization
        WsUri = $HCSWebServicesURL
        WsUser = $HCSWebServicesUsername
        WsPassword = $HCSWebServicesPassword
    }
}
Install-GocPackage -Id 'ls-central-hcc-project' -Arguments $Arguments

# Refresh the PS Module Path otherwise we will get "The specified module 'LsPackageTools\LicensePackageCreator' was not loaded because no valid module file was found in any module directory." when creating the license package.
$env:PSModulePath = [System.Environment]::GetEnvironmentVariable('PSModulePath', 'Machine')

AddToStatus "Installing Hybrid Cloud Components"
Set-Location $HCCProjectDirectory

AddToStatus "Loading the license"
if ($licenseFileUri) {
    $LicenseFileSourcePath = "c:\demo\license.flf"
    $LicenseFileDestinationPath = (Join-Path $HCCProjectDirectory 'Files/License')
    Download-File -sourceUrl $licensefileuri -destinationFile $LicenseFileSourcePath
    Copy-Item -Path $LicenseFileSourcePath -Destination $LicenseFileDestinationPath -Force
}
else {
    throw "License file not found at: ${licenseFileUri}"
}

AddToStatus "Creating license package"
& .\NewLicensePackage.ps1 -Import

AddToStatus "Downloading necessary package to the Update Service Server (this might take a while as the packages are downloaded from LS Retail's Update Service server)"
& .\GetLsCentralPackages.ps1
AddToStatus "Packages downloaded. You can view all packages on the server: http://localhost:8030"

AddToStatus "Updating NewBundlePackage script to include the license package"
$bundlePackage = Get-Content -Path (Join-Path $HCCProjectDirectory 'NewBundlePackage.ps1')
$newBundlePackage = $bundlePackage -replace '#@{ Id = "$($Config.PackageIdPrefix)-license"; "Version" = "1.0.0" }', '@{ Id = "$($Config.PackageIdPrefix)-license"; "Version" = "1.0.0" }'
$newBundlePackage | Set-Content -Path (Join-Path $HCCProjectDirectory 'NewBundlePackage.ps1')

# TODO: Include customer extensions

AddToStatus "Updating NewBundlePackage script to include the LS Hardware Station"
$bundlePackage = Get-Content -Path (Join-Path $HCCProjectDirectory 'NewBundlePackage.ps1')
$newBundlePackage = $bundlePackage -replace '#@{ Id = "ls-hardware-station"; Version = $Config.LsCentralVersion }', '@{ Id = "ls-hardware-station"; Version = $Config.LsCentralVersion }'
$newBundlePackage | Set-Content -Path (Join-Path $HCCProjectDirectory 'NewBundlePackage.ps1')

# TODO: Include OPOS drivers (?)

AddToStatus "Creating the POS Master and POS bundle"
& .\NewBundlePackage.ps1 -Import

AddToStatus "Installing the POS Master"
& .\UpdatePosMaster.ps1
