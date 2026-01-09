if (test-path .\variables.ps1){
	. .\variables.ps1
} else {
	write-host "Please update variables.ps1. Exiting."
	copy-item variables.ps1.example variables.ps1
}
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
invoke-webrequest -uri https://plex.tv/api/servers?X-Plex-Token=$YourAPItoken -outfile servers.xml
[xml]$xml = Get-Content -Path servers.xml
foreach ($f in $xml.MediaContainer.Server){
	write-host $f.name
	write-host "$($f.scheme)://$($f.host):$($f.port)"
	write-host $f.accessToken
	write-host "" 
}
if (test-path servers.xml){remove-item servers.xml}