if (!(Test-Path function:AddToStatus)) {
    function AddToStatus([string]$line, [string]$color = "Gray") {
        ("<font color=""$color"">" + [DateTime]::Now.ToString([System.Globalization.DateTimeFormatInfo]::CurrentInfo.ShortDatePattern) + " " + [DateTime]::Now.ToString([System.Globalization.DateTimeFormatInfo]::CurrentInfo.ShortTimePattern.replace(":mm",":mm:ss")) + " $line</font>") | Add-Content -Path "c:\demo\status.txt" -Force -ErrorAction SilentlyContinue
        Write-Host -ForegroundColor $color $line 
    }
}

AddToStatus "1: $([System.Environment]::GetEnvironmentVariable("PSModulePath", "Machine"))"

. (Join-Path $PSScriptRoot "settings.ps1")

$Folder = "C:\DOWNLOAD\HybridCloudServerComponents"
$Filename = "$Folder\ls-central-latest.exe"
New-Item $Folder -itemtype directory -ErrorAction ignore | Out-Null

if (!(Test-Path $Filename)) {
    AddToStatus "Downloading Update Service Client Installer Script"
    $WebClient = New-Object System.Net.WebClient
    $WebClient.DownloadFile("https://portal.lsretail.com/media/uiucpd5g/ls-central-latest.exe", $Filename)
}

AddToStatus "Installing GoCurrent Client module"
. "$Filename" /VERYSILENT /NORESTART /SUPPRESSMSGBOXES | Out-Null
#. "$Filename" /VERYSILENT /NORESTART /SUPPRESSMSGBOXES
# Start-Sleep -s 5  # Waits 5 seconds to continue.
if ($LASTEXITCODE -ne 0) { 
    AddToStatus -color red "Error installing GoCurrent Client module: $($LASTEXITCODE)"
    return
}
AddToStatus "2: env:PSModulePath: $($env:PSModulePath)"
AddToStatus "2: $([System.Environment]::GetEnvironmentVariable("PSModulePath", "Machine"))"

$env:PSModulePath = [System.Environment]::GetEnvironmentVariable("PSModulePath", "Machine")
Install-GocPackage -Id 'go-current-client'
# $env:PSModulePath = [System.Environment]::GetEnvironmentVariable("PSModulePath", "Machine")

AddToStatus "3: env:PSModulePath: $($env:PSModulePath)"
AddToStatus "3: $([System.Environment]::GetEnvironmentVariable("PSModulePath", "Machine"))"

# AddToStatus "Installing SQL Server Express (this might take a while)"
# Install-GocPackage -Id 'sql-server-express'

# AddToStatus "Preparing SQL Server Studio Management (SSMS) installation (this might take a while)"
# . "c:\demo\SetupSSMS.ps1"

AddToStatus "Installing LS Data Director Service"
Install-GocPackage -Id 'ls-dd-service'

AddToStatus "Enabling Web Services in LS Data Director"
$ddConfigFilename = "C:\ProgramData\LS Retail\Data Director\lsretail.config"
$dd_config = Get-Content $ddConfigFilename
$dd_config | % { $_.Replace("<WebSrv>false</WebSrv>", "<WebSrv>true</WebSrv>") } | Set-Content $ddConfigFilename

AddToStatus "Installing Update Service Server"
Install-GocPackage -Id 'go-current-server'

AddToStatus "4: env:PSModulePath: $($env:PSModulePath)"
AddToStatus "4: $([System.Environment]::GetEnvironmentVariable("PSModulePath", "Machine"))"

AddToStatus "4: $(Get-Module)"

AddToStatus "Installing Update Service Server Management"
Install-GocPackage -Id 'go-current-server-management'

AddToStatus "5: env:PSModulePath: $($env:PSModulePath)"
AddToStatus "5: $([System.Environment]::GetEnvironmentVariable("PSModulePath", "Machine"))"

$env:PSModulePath = [System.Environment]::GetEnvironmentVariable("PSModulePath", "Machine")

AddToStatus "6: env:PSModulePath: $($env:PSModulePath)"
AddToStatus "6: $([System.Environment]::GetEnvironmentVariable("PSModulePath", "Machine"))"

Import-Module GoCurrent
Import-Module GoCurrentServer
$ServerAssembly = [System.AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.FullName.StartsWith('LSRetail.GoCurrent.Server.Management')}
$ClientAssembly = [System.AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.FullName.StartsWith('LSRetail.GoCurrent.Client.Management')}
AddToStatus "ServerAssembly: $($ServerAssembly)"
AddToStatus "ClientAssembly: $($ClientAssembly)"
$ServerVersion = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($ServerAssembly.Location).ProductVersion
$ClientVersion = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($ClientAssembly.Location).ProductVersion
AddToStatus "ServerVersion: $($ServerVersion)"
AddToStatus "ClientVersion: $($ClientVersion)"
if ($ServerVersion -ne $ClientVersion)
{
    Write-Warning "Client and server version are not the same ($ServerVersion vs $ClientVersion)"
}

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
# $env:PSModulePath = [System.Environment]::GetEnvironmentVariable('PSModulePath', 'Machine')

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
    # Install-Module Az.Storage -Force
    AddToStatus "1"
    Import-Module Az.Storage

    AddToStatus "2"
    $storageAccountName = 'storagerlkhmkieze3cg'
    $containerName = 'hcs-container'
    $licenseFileName = 'DEV.flf'
    
    AddToStatus "3"
    $sasToken = '?sv=2020-08-04&ss=b&srt=o&se=2022-03-24T16%3A42%3A39Z&sp=rl&sig=fENFcm8hXng%2BJUF1QcCnWgzhOL6f%2FtqehEsEHF6ELmY%3D'
    AddToStatus "4"
    $storageAccountContext = New-AzStorageContext $storageAccountName -SasToken $sasToken
    AddToStatus "5"

    $LicenseFileSourcePath = "c:\demo\license.flf"
    $LicenseFileDestinationPath = (Join-Path $HCCProjectDirectory 'Files/License')
    AddToStatus "6"

    $DownloadBCLicenseFileHT = @{
        Blob        = $licenseFileName
        Container   = $containerName
        Destination = $LicenseFileSourcePath
        Context     = $storageAccountContext
    }
    AddToStatus "7"
    Get-AzStorageBlobContent @DownloadBCLicenseFileHT
    AddToStatus "8"
    Copy-Item -Path $LicenseFileSourcePath -Destination $LicenseFileDestinationPath -Force
    AddToStatus "9"
}
# else {
#     throw "License file not found at: ${licenseFileUri}"
# }

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
