# Parameters
param (
    [switch]$ignorelocal = $false,
    [switch]$ignoreremote = $false,
    [switch]$skipcompare = $false,
    [switch]$spotless = $false,
    [switch]$cleanup = $false,
    [switch]$wget = $false,
    [switch]$curl = $false
)

# Cleanup everything and die
if ($cleanup -eq $true){
	write-output "Cleaning up directory."
	if (test-path *.xml){remove-item *.xml}
	if (test-path *.txt){remove-item *.txt}
	if (test-path *movies.ps1){remove-item *movies.ps1}
	if (test-path *tv.ps1){remove-item *tv.ps1}
	if (test-path *artist.ps1){remove-item *artist.ps1}
	if (test-path *photo.ps1){remove-item *photo.ps1}
	exit
}

# Variables are important
if (test-path .\variables.ps1){
	. .\variables.ps1
} else {
	write-host "Please update variables.ps1. Exiting."
	copy-item variables.ps1.example variables.ps1
}

# Set webrequest ssl and progress
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Local library processing
if (!(test-path "locallibraries.xml") -and $ignorelocal -eq $true){
	echo "Missing local libraries, will process them anyway."
	$ignorelocal = $false
}
if ($ignorelocal -eq $false){
	# Cleanup old folder
	remove-item locallib*.xml
	remove-item locallib*.txt
	
	# Get local plex server content info
	invoke-webrequest -uri $LocalPMS/library/sections?X-Plex-Token=$LocalAPI -outfile locallibraries.xml
	[xml]$LocalPMSxml = Get-Content -Path locallibraries.xml
	foreach ($f in $LocalPMSxml.MediaContainer.Directory){
		if ($f.type -eq "show" -or $f.type -eq "artist" -or $f.type -eq "movie"){
			invoke-webrequest -uri $LocalPMS/library/sections/$($f.key)/all?X-Plex-Token=$($LocalAPI) -outfile locallib.$($f.type).$($f.key).xml
		}
	}

	# Index local movies
	$localmoviexmls=Get-ChildItem $PWD -filter locallib.movie.*.xml
	foreach ($g in $localmoviexmls.Name){
		[xml]$v=get-content $g
		foreach ($f in $v.MediaContainer.Video){
			write-output "$($f.guid)" >> locallib.movie.txt
		}
	}
}

# Remote library processing
if (!(test-path "remotelibraries.xml") -and $ignoreremote -eq $true){
	echo "Missing remote libraries, will process them anyway."
	$ignoreremote = $false
}
if ($ignoreremote -eq $false){
	# Cleanup old folder
	remove-item remotelib*.xml
	remove-item remotelib*.txt
	
	# Get remote plex server content info
	invoke-webrequest -uri $remotePMS/library/sections?X-Plex-Token=$remoteAPI -outfile remotelibraries.xml
	[xml]$remotePMSxml = Get-Content -Path remotelibraries.xml
	foreach ($f in $remotePMSxml.MediaContainer.Directory){
		if ($f.type -eq "show" -or $f.type -eq "artist" -or $f.type -eq "movie"){
			invoke-webrequest -uri $remotePMS/library/sections/$($f.key)/all?X-Plex-Token=$($remoteAPI) -outfile remotelib.$($f.type).$($f.key).xml
		}
	}
}
if ($skipcompare -eq $false){
	if (($wget -eq $false) -and ($curl -eq $false) -and (test-path movies.ps1)){
		remove-item movies.ps1
	}elseif(test-path movies.sh){
		remove-item movies.sh
	}
	# Compare remote movies
	$remotemoviexmls=Get-ChildItem $PWD -filter remotelib.movie.*.xml
	foreach ($g in $remotemoviexmls.Name){
		if (!(test-path "$downloadlocation")){mkdir "$downloadlocation"}
		[xml]$v=get-content $g
		foreach ($f in $v.MediaContainer.Video){
			if (!($f -like "local*")){
				$x=$false
				foreach ($z in get-content locallib.movie.txt){
					if ($z -eq $f.guid){$x=$true}
				}
				if ($x -eq $true){
					write-output "$($f.title) exists in local library."
				} else {
					write-output "$($f.title) not present in local libraries."
					if ($wget -eq $true){
						write-output "wget -O `"$($downloadlocation)/$($v.MediaContainer.title1)/$($f.title).$($f.Media.container)`"  `"$($remotePMS)$($f.Media.Part.key)?download=1&X-Plex-Token=$($remoteAPI)`"" >> $($v.MediaContainer.title1).movies.sh
					}elseif ($curl -eq $true){
						write-output "curl `"$($remotePMS)$($f.Media.Part.key)?download=1&X-Plex-Token=$($remoteAPI)`" > `"$($downloadlocation)/$($v.MediaContainer.title1)/$($f.title).$($f.Media.container)`"" >> $($v.MediaContainer.title1).movies.sh
					}else{
						write-output "invoke-webrequest -uri `"$($remotePMS)$($f.Media.Part.key)?download=1&X-Plex-Token=$($remoteAPI)`" -outfile `"$($downloadlocation)\$($v.MediaContainer.title1)\$($f.title).$($f.Media.container)`"" >> $($v.MediaContainer.title1).movies.ps1
					}
				}
			}
		}
	}
}

### Cleanup
if ($spotless -eq $true){
	if (test-path *.xml){remove-item *.xml}
	if (test-path *.txt){remove-item *.txt}
#	if (test-path movies.ps1){remove-item movies.ps1}
#	if (test-path	tv.ps1){remove-item	tv.ps1}
#	if (test-path artist.ps1){remove-item artist.ps1}
#	if (test-path photo.ps1){remove-item photo.ps1}
}