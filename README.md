<h1 align="center">
  Hello! 👋
</h1>

This repository is the home for an LFTP sync script that makes up part of the [Media Workflow](https://github.com/chase-slept/media-workflow) documentation project.

## Table of Contents
- [Table of Contents](#table-of-contents)
- [About The Project](#about-the-project)
- [LFTP Script](#lftp-script)
- [Jump Host](#jump-host)

## About The Project

This goal of this project is to document the LFTP script that transfers media files from my local NAS to a remote server.  

## LFTP Script

The script itself is pretty straight forward. The main component is a single line:

```bash
lftp sftp://${HOST}/ -e 'set sftp:auto-confirm yes; mirror -v --parallel=1 --use-pget-n=2 --continue --only-missing --Remove-source-files   /mnt/data/sync/  /home/slept/media/; quit'
```

It runs the `lftp` command and connects via SFTP. The `${HOST}` portion is sourced from an external secrets file that points to our SSH Jump Host (which is itself accessible through our Bastion Server--that makes two jumps total). The command is set to auto-confirm any connection messages, mirror the local sync folder, split downloads into 2 segments, continue where left off if disconnected, grab only missing files, then remove any files it downloaded from the source location before closing the LFTP job. I've limited the download segments here to just 2, as this SSH connection has low bandwidth and is easily over-utilized.

We'll add the script to our system's crontab with `crontab -e`. I set it to run every minute: `*/1 * * * * /usr/bin/flock -n /tmp/sync.lock /home/slept/scripts/lftpsync.sh >> /home/slept/scripts/log.log 2>&1`. You can see we're using `flock` here to prevent it from running multiple times and stacking up on itself; the `-n` flag tells flock to throw an error if the lockfile at `/tmp/sync.lock` already exists, rather than waiting for the existing process to finish running. The last parameter is the command flock should run, which in this case is our script. We use `>>` to append the script's output to a file, with `2>&1` telling the shell to print stdout/stderr together in the same log.

## Jump Host

In order to secure the path to our local servers, we use a Jump Host to connect back home. This is configured in the SSH config file, which I've sanitized below:

```
Host vps
  HostName <IP to Bastion Server>
  User slept

Host pi.jump
  HostName <local IP to Raspberry Pi>
  User slept
  ProxyJump vps
```

This tells the server (and our LFTP script, which uses SSH) where to connect to Bastion server and the pi.jump SSH Host, which uses the ProxyJump command to first connect to our Bastion server. The ProxyJump command tunnels one host through another. We're essentially connecting via SSH to the Bastion server, which knows how to connect to the local server via SSH as well.
