<h1 align="center">
  Hello! 👋
</h1>

This repository is the home for an LFTP sync script that makes up part of the [Media Workflow](https://github.com/chase-slept/media-workflow) documentation project.

## Table of Contents
- [Table of Contents](#table-of-contents)
- [About The Project](#about-the-project)
- [LFTP Script](#lftp-script)

## About The Project

This goal of this project is to document the LFTP script that transfers media files from my local NAS to a remote server.  

## LFTP Script

The script itself is pretty straight forward. The main component is a single line:

```bash
lftp sftp://${HOST}/ -e 'set sftp:auto-confirm yes; mirror -v --parallel=1 --use-pget-n=2 --continue --only-missing --Remove-source-files   /mnt/data/sync/  /home/slept/media/; quit'
```

It runs the lftp command and connects via SFTP with the  `${HOST}` portion sourced from an external secrets file. The command is set to auto-confirm any messages, mirrors the local sync folder grabbing only missing files, splits downloads into 2 segments, then removes any files it downloaded from the source location.

The script is meant to run as a cronjob and as such, needs a way to prevent being run repeatedly and getting stuck on itself. Initially, I used `flock` to prevent it from running if it was already running, but the cronjob would still initiate a PID and wait in a queue to continue. After some research, I came across another solution, which was to use a PID trap. I'll need to do more research into this process but here's the solution I found that prevented new cronjobs from spawning when one was already running:

```bash
#PID trap
PIDFILE=/tmp/`basename $0`.pid
if [ -f $PIDFILE ]; then
    if ps -p `cat $PIDFILE` > /dev/null 2>&1; then
        echo "$0 already running!"
        exit
    fi
fi
echo $$ > $PIDFILE

trap 'rm -f "$PIDFILE" >/dev/null 2>&1' EXIT HUP KILL INT QUIT TERM
```

The script also includes some pretty standard logging traps.
