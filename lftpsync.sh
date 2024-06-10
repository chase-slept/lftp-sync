#!/bin/bash
#logging
LOGFILE="~/scripts/log.log"
exec 3>&1 1>"$LOGFILE" 2>&1
trap "echo 'ERROR: An error occurred during execution, check log $LOGFILE for details.' >&3" ERR
trap '{ set +x; } 2>/dev/null; echo -n "[$(date -Is)]  "; set -x' DEBUG

#define sensitives
source ~/scripts/syncDefines.sh

echo "Starting LFTP ..."
lftp sftp://${HOST}/ -e 'set sftp:auto-confirm yes; mirror -v --parallel=1 --use-pget-n=2 --continue --only-missing --Remove-source-files   /mnt/data/sync/  /home/slept/media/; quit'