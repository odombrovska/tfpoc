$url = "https://www.rarlab.com/rar/winrar-x64-602.exe"
$outpath = "$PSScriptRoot/winrar-x64-602.exe"

$wc = New-Object System.Net.WebClient
$wc.DownloadFile($url, $outpath)

Start-Process $outpath -ArgumentList "/S" -Wait -NoNewWindow
Remove-Item $outpath