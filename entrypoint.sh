#!/usr/bin/env bash
set -e

if [ -z "$1" ] || [ "$1" = 'backup' ] || [ "$1" = 'restore' ] || [ "$1" = 'duply' ]; then
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
    if [ -z "$1" ] || [ "$1" = 'backup' ]; then
        duply project backup_verify_purge --force > ${LOGFILE} 2>&1
        EXIT_CODE=$?
    elif [ "$1" = 'restore' ]; then
        exec duply project "$@" > ${LOGFILE} 2>&1
        EXIT_CODE=$?
    else
        exec "$@" > ${LOGFILE} 2>&1
        EXIT_CODE=$?
    fi

    if [ -n "$MAIL_FOR_ERRORS" ] && [ $EXIT_CODE -ne 0 ]; then
        cat $LOGFILE | mail -s "backup ${HOSTPATH} failed" "$MAIL_FOR_ERRORS"
    fi
else
    exec "$@"
fi
