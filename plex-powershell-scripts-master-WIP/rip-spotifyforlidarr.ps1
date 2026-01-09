if (test-path .\variables.ps1){
	. .\variables.ps1
} else {
	write-host "Please update variables.ps1. Exiting."
	copy-item variables.ps1.example variables.ps1
}

# Confirm that spotdl exists
try { spotdl -v | out-null } catch{
	write-host "spotdl required, accessible using PATH envvar in Windows. Use PIP install. Go get it: https://github.com/spotDL/spotify-downloader"
	write-host " Likely `pip install spotdl ; $ENV:PATH="$ENV:PATH;c:\users\$ENV:USERNAME\appdata\roaming\python\python313\scripts"`"
	exit
}

# web request variables
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# request the entire list of missing files from Lidarr
write-output "Grabbing wanted albums from Lidarr."
if (test-path "lidarrwanted.json"){remove-item "lidarrwanted.json"}
invoke-webrequest -uri "$($lidarrhost)/api/v1/wanted/missing?includeArtist=false&apikey=$($lidarrapikey)&pageSize=$($lidarrpagesize)" -outfile lidarrwanted.json

# Search spotify for album links 
if (test-path "$($PWD)\rip.ps1"){remove-item "$($PWD)\rip.ps1"}
$LidarrJson = Get-Content .\lidarrwanted.json -Raw | ConvertFrom-Json 
foreach ($f in $LidarrJson.records){
	$artist = $f.artist.artistName -replace '[^i\p{IsBasicLatin}]'
	$title = $f.title -replace '[^i\p{IsBasicLatin}]'
	$headers = @{ 'Authorization' = "Bearer $($spotifyoauth)" ; 'Content-Type' = 'application/json' ; 'Accept' = 'application/json' }
	$link = "https://api.spotify.com/v1/search?q=$artist - $title&type=album&limit=1"
	$content = invoke-webrequest -headers $headers -uri $link
	$json = $content.content | convertfrom-json
##	write-output "Found $($json.albums.items.external_urls.spotify)"
	if (!($json.albums.items.external_urls.spotify)){
		write-output "Could not find download candidate for $title by $artist"
	}elseif ($json.albums.items.release_date){
		write-output "#$title by $artist found." >> rip.ps1
		write-output "spotdl $($json.albums.items.external_urls.spotify) --path-template `"$($riproom)\{artist}\{album} ($($json.albums.items.release_date.substring(0,4)))\{artist} - {title}.{ext}`"" >> rip.ps1
	} else {
		write-output "spotdl $($json.albums.items.external_urls.spotify) --path-template `"$($riproom)\{artist}\{album}\{artist} - {title}.{ext}`"" >> rip.ps1
	}
}
if (test-path lidarrwanted.json){remove-item lidarrwanted.json}
if (test-path .spotdl-cache){remove-item .spotdl-cache}

write-output "remove-item *.spotdlTrackingFile >> rip.ps1"
write-output "Completed creation of download script. Please run `"$($PWD)\rip.ps1`"."
