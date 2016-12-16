#!/usr/bin/env bash

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
        if [ "$1" = 'mongo' ] || [ "$2" = 'mongo' ]; then
            if [ -z "$MONGO_HOST" ]; then
              echo "you need to set the MONGO_HOST env variable"
              exit 1
            fi
            MONGO_ARGS="-o /to_backup --oplog --host $MONGO_HOST"
            if [ -n "$MONGO_PORT" ]; then
                MONGO_ARGS="$MONGO_ARGS --port $MONGO_PORT"
            fi
            if [ -n "$MONGO_USER" ]; then
                MONGO_ARGS="$MONGO_ARGS --authenticationDatabase admin -u $MONGO_USER -p $MONGO_PASSWORD"
            fi
            if [ -z "$MONGO_DB" ]; then
                MONGO_ARGS="$MONGO_ARGS -d $MONGO_DB"
            fi
            
            mongodump $MONGO_ARGS > ${LOGFILE}-mongo 2>&1
            MONGO_EXIT_CODE=$?
            
            if [ -n "$MAIL_FOR_ERRORS" ] && [ $MONGO_EXIT_CODE -ne 0 ]; then
                cat $LOGFILE-mongo | mail -s "backup ${HOSTPATH} failed" "$MAIL_FOR_ERRORS"
            fi
        fi
        
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
