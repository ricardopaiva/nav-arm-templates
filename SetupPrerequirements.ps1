Import-Module (Join-Path $PSScriptRoot "Helpers.ps1") -Force

# Install Choco
AddToSTatus "Install Choco"
$env:chocolateyVersion = '1.4.0.0'
Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
choco feature enable -n allowGlobalConfirmation

# Installing .NET Framework 4.8
AddToStatus "Install .net Framework 4.8"
choco install dotnetfx

AddToStatus "Install Edge"
choco install microsoft-edge

AddToStatus "Install Azure CLI"
choco install azure-cli