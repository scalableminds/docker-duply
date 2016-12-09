#!/usr/bin/env bash
set -e

if [ -n "$1" ]; then
    exec "$@"
else
    LOGFILE="$(date +%F)-backup-log"
    duply project backup_verify_purge --force > ${LOGFILE} 2>&1

    if [ -n "$MAIL_FOR_ERRORS" ] && [ $? -ne 0 ]; then
        cat $LOGFILE | mail -s "backup ${PATH} failed" "$MAIL_FOR_ERRORS"
    fi
fi
