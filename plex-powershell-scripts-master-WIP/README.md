# plex powershell scripts

A few tools to rip content from subscribed Plex servers. This was authored a while ago, and I'm sure I'd do a better job now. By no means complete, but functional for shows + movies, IIRC. I literally haven't touched this project in over 3 years. I'm not going to commit to maintaing this, feel free to fork and improve yourself.

## variables.ps1
All script variables are defined in this file. If it doesn't exist, you can either copy variables.ps1.example to variables.ps1, or run any of the scripts to create it. It will need to be manually modified for your environment and target environment.

## compare-libraries.ps1
Will compare the target library with your library. IIRC, if a local library isn't defined, it will just grab everything. If that's not the case, you can create an empty library to compare. I digress... After comparison, the script will dump a download script. That script will contain one-liners for downloading each piece of content. You can wade through it and cherry pick, or run the whole thing and grow your library. Output options are curl, wget, or the default, invoke-webrequest.

## get-plexservers.ps1
list all plex servers available to your plex account. Useful for figuring out what to grab.

## refresh-plexlibraries.ps1
Forces a refresh of a given library, IIRC.

## rip-spotifyforlidarr.ps1
Requires spotdl + PATH envvar update. Creates "rip.ps1" which will download all missing albums. Currently broken, probably wouldn't take a lot of effort to resolve.