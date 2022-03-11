if (!(Test-Path function:AddToStatus)) {
    function AddToStatus([string]$line, [string]$color = "Gray") {
        ("<font color=""$color"">" + [DateTime]::Now.ToString([System.Globalization.DateTimeFormatInfo]::CurrentInfo.ShortTimePattern.replace(":mm",":mm:ss")) + " $line</font>") | Add-Content -Path "c:\demo\status.txt" -Force -ErrorAction SilentlyContinue
        Write-Host -ForegroundColor $color $line 
    }
}

$Folder = "C:\DOWNLOAD\SSMS"
$Filename = "$Folder\SSMS-Setup-ENU.exe"
New-Item $Folder -itemtype directory -ErrorAction ignore | Out-Null

if (!(Test-Path $Filename)) {
    AddToStatus "Downloading SQL Server Management Studio (SSMS)"
    $WebClient = New-Object System.Net.WebClient
    $WebClient.DownloadFile("https://aka.ms/ssmsfullsetup", $Filename)
}

AddToStatus "Installing SQL Server Management Studio (SSMS)"
$Params = " /Install /Quiet /Norestart /Logs log.txt"
$Parameters = $Params.Split(" ")
& "$Filename" $Parameters | Out-Null