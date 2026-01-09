if (test-path .\variables.ps1){
	. .\variables.ps1
} else {
	write-host "Please update variables.ps1. Exiting."
	copy-item variables.ps1.example variables.ps1
}

if (!($args[0])){
	write-host "Provide a library type; artist, show, photo, or movie. Exiting."
	exit
}

$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
invoke-webrequest -uri $PMS/library/sections?X-Plex-Token=$APItoken -outfile libraries.xml
[xml]$xml = Get-Content -Path libraries.xml
if ($args[0] -eq "show" -or $args[0] -eq "artist" -or $args[0] -eq "photo" -or $args[0] -eq "movie" ){
	foreach ($f in $xml.MediaContainer.Directory){
		# write-host $f.key $f.type
		if ($f.type -eq $args[0]){
			$key = $f.key
		invoke-webrequest -uri $PMS/library/sections/$($key)/refresh?X-Plex-Token=$($APItoken)
		}
	}
}
if (test-path libraries.xml){remove-item libraries.xml}