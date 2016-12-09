#!/usr/bin/env bash
set -e

if [ -n "$1" ]; then
    exec "$@"
else
    if [ -z "$GPG_PW"   ] || \
       [ -z "$SCHEME"   ] || \
       [ -z "$HOST"     ] || \
       [ -z "$HOSTPATH" ] || \
       [ -z "$USER"     ] || \
       [ -z "$PASSWORD" ]
    then
      echo "you need to set more env variables"
      exit 1
    fi
    
    envsubst '${GPG_PW} ${SCHEME} ${HOST} ${HOSTPATH} ${USER} ${PASSWORD}' < conf.template > conf

    LOGFILE="$(date +%F)-backup-log"
    duply project backup_verify_purge --force > ${LOGFILE} 2>&1

    if [ -n "$MAIL_FOR_ERRORS" ] && [ $? -ne 0 ]; then
        cat $LOGFILE | mail -s "backup ${HOSTPATH} failed" "$MAIL_FOR_ERRORS"
    fi
fi
