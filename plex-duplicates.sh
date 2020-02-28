#!/usr/bin/sh
# Requires ffprobe
# User token. Take from the URL you have when navigating to the plex server in a browser.
token=qqqqqqqqqqq
# Plex URL
host=plex.server.local
# Plex server port, default is 32400
port=32400
# Directory key. Can be found at http://$host:$port/library/sections?X-Plex-Token=$token
section=1
# Action. (dry,rm,mv) dry run, remove duplicates, move duplicates
action=dry
# destination - used only when action=mv
destination=/mnt/storage/dedupe/

if [[ ! -f .wtf.txt ]]; then 
 wget -O .wtf.txt http://$host:$port/library/sections/$section/all?X-Plex-Token=$token
fi

if [[ ! -f .wtf.txt ]]; then echo Cannot find .wtf.txt. Check your connection string.; exit; fi
if [[ $action != "dry" && $action != "mv" && $action != "rm" ]]; then echo Chose an appropraiate action.; exit; fi
if [[ $action == "mv" && ! -d "$destination" ]]; then mkdir -p "$destination"; echo "Creating destination folder $destination"; fi
if [[ $action == "mv" && ! -d "$destination" ]]; then echo Destination folder folder could not be created.; exit; fi

itemsCount=`xmllint --xpath 'count(//MediaContainer/Video)' .wtf.txt`
declare -a tt=( )
declare -a tg=( )
for (( i=177; $i <= $itemsCount; i++ )); do
#for (( i=1; $i <= $itemsCount; i++ )); do
 bob=`xmllint --xpath 'count(//MediaContainer/Video['$i']/Media)' .wtf.txt`
 h=0
 if [[ $bob -gt "1" ]]; then
 bb="0"
 ss=""
  for (( g=1; $g <= $bob; g++ )); do
   s="$(xmllint --xpath '//MediaContainer/Video['$i']/Media['$g']/Part/@file' .wtf.txt)"
   s=${s:6}
   s=${s//\"/}
   b=`ffprobe "$s" -v quiet -print_format json -show_format | grep bit_rate`
   b=`echo $(cut -d'"' -f4 <<< $b)`
   if [[ $b == "" || $b == "0" ]]; then
    if [[ $action == "rm" ]]; then
     echo Removing $s as it has a bitrate of 0
     rm -f "$s"
    elif [[ $action == "mv" ]]; then
     echo Moving $s as it has a bitrate of 0
     mv -f "$s" $destination
    elif [[ $action == "dry" ]]; then
     echo $s has a bitrate of 0
    fi
   elif [[ $b -gt $bb ]]; then
    bb=$b
    if [[ -f "$ss" ]]; then
     if [[ $action == "rm" ]]; then
      echo "Removing $ss because it has a lower bitrate than $s ($bb vs $b)"
      rm -f "$ss"
     elif [[ $action == "mv" ]]; then
      echo "Moving $ss  because it has a lower bitrate than $s ($bb vs $b)"
      mv -f "$ss" $destination
     elif [[ $action == "dry" ]]; then
      echo "$ss has a lower bitrate than $s ($bb vs $b)"
     fi
    fi
   elif [[ $b -lt $bb ]]; then
    if [[ $action == "rm" ]]; then
     echo "Removing $s because it has a lower bitrate than $ss ($b vs $bb)"
     rm -f "$s"
    elif [[ $action == "mv" ]]; then
     echo "Moving $s because it has a lower bitrate than $ss ($b vs $bb)"
     mv -f "$s" $destination
    elif [[ $action == "dry" ]]; then
     echo "$s has a lower bitrate than $ss ($b vs $bb)"
    fi
   elif [[ "$b" -eq "$bb" ]]; then
    if [[ $action == "rm" ]]; then
     echo "Removing $s as it is a duplicate of $ss"
     rm -f "$s"
    elif [[ $action == "mv" ]]; then
     echo "Moving $s as it is a duplicate of $ss"
     mv "$s" $destination
    elif [[ $action == "dry" ]]; then
     echo "$s is a duplicate of $ss"
    fi
   fi
   ss=$s
  done
 fi
done
curl http://$host:$port/library/sections/$section/refresh?X-Plex-Token=$token

exit
