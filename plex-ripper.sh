#!/bin/bash
# V4. Local duplicate checking.
# 
# User token for remote Plex server.
remotetoken=aaaaaaaaaaaaaaaaa
# Remote Plex server URL
remotehost=http://another.plexserver.net
# Remote Plex server port, default is 32400
remoteport=32400
# User token for remote Plex server.
localtoken=bbbbbbbbbbbbbbb
# Remote Plex server URL
localhost=http://my.localplexserver.com
# Remote Plex server port, default is 32400
localport=32400
# The media directory you choose to drop scraped media into (use a trailing slash )
destination=/mnt/storage/somejiocynewmedia/
# Download rate limit in k, K, m, M, g or G
limit=30M

## Remove a bunch of temporary files
echo removing files
if [ -f .localtemp1.xml ]; then rm -f .localtemp1.xml; fi
if [ -f .localtemp2.xml ]; then rm -f .localtemp2.xml; fi
if [ -f .localtempshows.xml ]; then rm -f .localtempshows.xml; fi
if [ -f .localtempshows1.xml ]; then rm -f .localtempshows1.xml; fi
#if [ -f .existingmovies.xml ]; then rm -f .existingmovies.xml; fi
#if [ -f .existingepisodes.xml ]; then rm -f .existingepisodes.xml; fi
if [ ! -d $destination ]; then mkdir -p $destination; fi
if [ -f .remotetemp1.xml ]; then rm -f .remotetemp1.xml; fi
if [ -f .remotetemp2.xml ]; then rm -f .remotetemp2.xml; fi
if [ -f .remotetempshows.xml ]; then rm -f .remotetempshows.xml; fi
if [ -f .remotetempshows1.xml ]; then rm -f .remotetempshows1.xml; fi

## Get plex sections
echo grabbing sections
wget -qO- $localhost:$localport/library/sections?X-Plex-Token=$localtoken > .localtemp1.xml
localitemCount=`xmllint --xpath 'count(//MediaContainer/Directory)' .localtemp1.xml`
wget -qO- $remotehost:$remoteport/library/sections?X-Plex-Token=$remotetoken > .remotetemp1.xml
remoteitemCount=`xmllint --xpath 'count(//MediaContainer/Directory)' .remotetemp1.xml`

## Reset some variables
echo resetting vars
localmovie=()
localshow=()
remotemovie=()
remoteshow=()
y=''
b=''
i=''

## Map library section keys
echo section keys for local
for (( y=0; $y <= $localitemCount; y++ )); do
 localsectionkey[$y]="$(xmllint --xpath '//MediaContainer/Directory['$y']/@key' .localtemp1.xml)"
 localsectiontype[$y]="$(xmllint --xpath '//MediaContainer/Directory['$y']/@type' .localtemp1.xml)"
 localsectionkey[$y]=${localsectionkey[$y]:6:-1}
 localsectiontype[$y]=${localsectiontype[$y]:7:-1}
 if [[ ${localsectiontype[$y]} == "movie" ]] ; then localmovie+=(${localsectionkey[$y]}); fi
 if [[ ${localsectiontype[$y]} == "show" ]] ; then localshow+=(${localsectionkey[$y]}); fi
done

echo section keys for remote
for (( b=0; $b <= $remoteitemCount; b++ )); do
 remotesectionkey[$b]="$(xmllint --xpath '//MediaContainer/Directory['$b']/@key' .remotetemp1.xml)"
 remotesectiontype[$b]="$(xmllint --xpath '//MediaContainer/Directory['$b']/@type' .remotetemp1.xml)"
 remotesectionkey[$b]=${remotesectionkey[$b]:6:-1}
 remotesectiontype[$b]=${remotesectiontype[$b]:7:-1}
 if [[ ${remotesectiontype[$b]} == "movie" ]] ; then remotemovie+=(${remotesectionkey[$b]}); fi
 if [[ ${remotesectiontype[$b]} == "show" ]] ; then remoteshow+=(${remotesectionkey[$b]}); fi
done

## Create existing media logs
if [[ $1 != "skip" ]];then 
 echo Getting existing movies
 for f in "${localmovie[@]}"; do
  wget -qO- $localhost:$localport/library/sections/$f/all?X-Plex-Token=$localtoken >> .localtemp.xml
  itemsCount=`xmllint --xpath 'count(//MediaContainer/Video)' .localtemp.xml`
  declare -a tt=( )
  declare -a tg=( )
  percentage() { printf "  %s%%" $(( (($i)*100)/($itemsCount)*100/100 )); }
  clean_line() { printf "\r"; }
  for (( i=1; $i <= $itemsCount; i++ )); do 
   to[$i]="$(xmllint --xpath '//MediaContainer/Video['$i']/@guid' .localtemp.xml)"
   to[$i]=`echo $(cut -d'/' -f3 <<<${to[$i]})`
   to[$i]=`echo $(cut -d'?' -f1 <<<${to[$i]})`
   if [[ ${to[$i]} == "gui"* ]]; then 
    to[$i]=`echo $(cut -d'"' -f2 <<<${to[$i]})`
   fi
   percentage
   clean_line
   echo ${to[$i]} >> .existingmovies.txt
  done
  clean_line
  rm .localtemp.xml -f
 done
 echo Getting existing shows
 for f in "${localshow[@]}"; do
  wget -qO- $localhost:$localport/library/sections/$f/all?X-Plex-Token=$localtoken >> .localtempshows.xml
  hh=`xmllint --xpath 'count(//MediaContainer/Directory)' .localtempshows.xml`
  declare -a qq=( )
  percentage() { printf "  %s%%" $(( (($i)*100)/($hh)*100/100 )); }
  clean_line() { printf "\r"; }
  for (( i=1; $i <= $hh; i++ )); do 
   qq[$i]="$(xmllint --xpath '//MediaContainer/Directory['$i']/@key' .localtempshows.xml)"
   wget -qO- $localhost:$localport${qq[$i]:6:-9}allLeaves?X-Plex-Token=$localtoken >> .localtempshows1.xml
   declare -a tt=( )
   declare -a tg=( )
   jj=`xmllint --xpath 'count(//MediaContainer/Video)' .localtempshows1.xml`
   for (( uy=1; $uy <= $jj; uy++ )); do 
    tt[$uy]="$(xmllint --xpath '//MediaContainer/Video['$uy']/@guid' .localtempshows1.xml)"
    exshow=`echo $(cut -d'/' -f3 <<<${tt[$uy]})`
    exseas=`echo $(cut -d'/' -f4 <<<${tt[$uy]})`
    exepis=`echo $(cut -d'/' -f5 <<<${tt[$uy]})`
    exepis=`echo $(cut -d'?' -f1 <<<$exepis})`
    echo "$exshow-$exseas-$exepis"  >> .existingepisodes.txt
   done
   rm .localtempshows1.xml
  done
  percentage
  clean_line
  rm .localtempshows.xml
 done
 clean_line
else
 echo Skipping existing file generation.
fi

## get the movies that do not exist in current direcotory or local plex server
for f in "${remotemovie[@]}"; do
 wget -qO- $remotehost:$remoteport/library/sections/$f/all?X-Plex-Token=$remotetoken >> .remotetemp.xml
 itemsCount=`xmllint --xpath 'count(//MediaContainer/Video)' .remotetemp.xml`
 declare -a tt=( )
 declare -a tg=( )
 percentage() { printf "  %s%%" $(( (($i)*100)/($itemsCount)*100/100 )); }
 clean_line() { printf "\r"; }
 for (( i=1; $i <= $itemsCount; i++ )); do 
  to[$i]="$(xmllint --xpath '//MediaContainer/Video['$i']/@guid' .remotetemp.xml)"
  to[$i]=`echo $(cut -d'/' -f3 <<<${to[$i]})`
  to[$i]=`echo $(cut -d'?' -f1 <<<${to[$i]})`
  if [[ ! `cat .existingmovies.txt | grep ${to[$i]} -c` -gt "0" ]]; then
   tt[$i]="$(xmllint --xpath '//MediaContainer/Video['$i']/Media/Part/@key' .remotetemp.xml)"
   tg[$i]="$(xmllint --xpath '//MediaContainer/Video['$i']/@title' .remotetemp.xml)"
   name=${tg[$i]:8:-1}
   name=${name// /_}
   name=${name//:/_}
   name=${name//!/}
   name=${name//\"/}
   name=${name//&amp;/&}
   ext=`echo $(cut -d'.' -f2 <<< ${tt[$i]})`
   ext=${ext::3}
   if [ -f "$destination$name.*" ]; then 
    if [ ! -f "$destination$name.$ext" ]; then
     echo "$destination$name.*" >> aaaa_to_be_removed.txt
    fi
   fi
   if [ ! -f "$destination$name.$ext" ]; then
    curl -s --limit-rate $limit "$remotehost:$remoteport${tt[$i]:6:-1}?download=1&X-Plex-Token=$remotetoken" > "$destination$name.$ext"
   fi
  else
   echo ${to[$i]} exists. Skipping.
  fi
 done
 percentage
 clean_line
 rm .remotetemp.xml
done
clean_line

## get the episodes that do not exist in current direcotory or local plex server
for f in "${remoteshow[@]}"; do
 wget -qO- $remotehost:$remoteport/library/sections/$f/all?X-Plex-Token=$remotetoken >> .remotetempshows.xml
 hh=`xmllint --xpath 'count(//MediaContainer/Directory)' .remotetempshows.xml`
 declare -a qq=( )
 percentage() { printf "  %s%%" $(( (($i)*100)/($hh)*100/100 )); }
 clean_line() { printf "\r"; }
 for (( i=1; $i <= $hh; i++ )); do 
  qq[$i]="$(xmllint --xpath '//MediaContainer/Directory['$i']/@key' .remotetempshows.xml)"
  wget -qO- $remotehost:$remoteport${qq[$i]:6:-9}allLeaves?X-Plex-Token=$remotetoken >> .remotetempshows1.xml
  declare -a tt=( )
  declare -a tg=( )
  jj=`xmllint --xpath 'count(//MediaContainer/Video)' .remotetempshows1.xml`
  for (( uy=1; $uy <= $jj; uy++ )); do 
   tt[$uy]="$(xmllint --xpath '//MediaContainer/Video['$uy']/@guid' .remotetempshows1.xml)"
   exshow=`echo $(cut -d'/' -f3 <<<${tt[$uy]})`
   exseas=`echo $(cut -d'/' -f4 <<<${tt[$uy]})`
   exepis=`echo $(cut -d'/' -f5 <<<${tt[$uy]})`
   exepis=`echo $(cut -d'?' -f1 <<<$exepis})`
   if [[ ! `cat .existingepisodes.txt | grep "$exshow-$exseas-$exepis" -c` -gt "0" ]]; then
    tt[$uy]="$(xmllint --xpath '//MediaContainer/Video['$uy']/Media/Part/@key' .remotetempshows1.xml)"
    tg[$uy]="$(xmllint --xpath '//MediaContainer/Video['$uy']/@title' .remotetempshows1.xml)"
    season[$uy]="$(xmllint --xpath '//MediaContainer/Video['$uy']/@parentIndex' .remotetempshows1.xml)"
    episode[$uy]="$(xmllint --xpath '//MediaContainer/Video['$uy']/@index' .remotetempshows1.xml)"
    remoteshowname="$(xmllint --xpath '//MediaContainer/@title2' .remotetempshows1.xml)"
    episode[$uy]=`echo "${episode[$uy]}" | cut -d'"' -f2`
    season[$uy]=`echo "${season[$uy]}" | cut -d'"' -f2`
    remoteshowname=${remoteshowname:9:-1}
    remoteshowname=${remoteshowname// /_}
    remoteshowname=${remoteshowname//:/_}
    remoteshowname=${remoteshowname//!/}
    remoteshowname=${remoteshowname//\//}
    remoteshowname=${remoteshowname//&amp;/&}
    name=${remoteshowname}_${season[$uy]}x${episode[$uy]}
    ext=`echo "${tt[$uy]}" | cut -d'.' -f2`
    ext=`echo "$ext" | cut -d'"' -f1`
    if [ ! -d $destination$remoteshowname ]; then mkdir -p $destination$remoteshowname; fi
    if [ ! -f "$destination$remoteshowname/$name.$ext" ]; then
     curl -s --limit-rate $limit "$remotehost:$remoteport${tt[$uy]:6:-1}?download=1&X-Plex-Token=$remotetoken" > "$destination$remoteshowname/$name.$ext"
    else
     echo $name already exists in library.
    fi
   fi
  done
  rm .remotetempshows1.xml
  percentage
  clean_line
 done
 clean_line
 rm .remotetempshows.xml
done
