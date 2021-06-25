Install-PackageProvider -Name NuGet -RequiredVersion 2.8.5.201 -Force
Import-PackageProvider -Name NuGet -RequiredVersion 2.8.5.20

Install-Module PSWindowsUpdate
Import-Module PSWindowsUpdate

Install-WindowsUpdate -AcceptAll -MicrosoftUpdate -AutoReboot