$url = "https://www.rarlab.com/rar/winrar-x64-602.exe"
$outpath = "$PSScriptRoot/winrar-x64-602.exe"

$wc = New-Object System.Net.WebClient
$wc.DownloadFile($url, $outpath)

Start-Process $outpath -ArgumentList "/S" -Wait -NoNewWindow
Remove-Item $outpath

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Install-PackageProvider -Name NuGet -RequiredVersion 2.8.5.201 -Force
Import-PackageProvider -Name NuGet -RequiredVersion 2.8.5.201

Set-PSRepository PSGallery -InstallationPolicy Trusted

Install-Module PSWindowsUpdate
Import-Module PSWindowsUpdate

Install-WindowsUpdate -AcceptAll -MicrosoftUpdate -AutoReboot