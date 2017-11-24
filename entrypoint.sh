#!/usr/bin/env bash
set -Eeo pipefail # unset variables are catched everywhere

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
            if [ -z "$MONGOHOST" ]; then
              echo "you need to set the MONGOHOST env variable"
              exit 1
            fi
            MONGO_ARGS="-o /to_backup --host $MONGOHOST --gzip"
            if [ -n "$MONGOPORT" ]; then
                MONGO_ARGS+=" --port $MONGOPORT"
            fi
            if [ -n "$MONGOUSER" ]; then
                MONGO_ARGS+=" --authenticationDatabase admin -u $MONGOUSER -p $MONGOPASSWORD"
            fi
            if [ -n "$MONGODB" ]; then
                MONGO_ARGS+=" -d $MONGODB"
            fi
            if [ -n "$MONGOREPLSET" ]; then
                MONGO_ARGS+=" --oplog"
            fi
            
            mongodump $MONGO_ARGS 2>&1 | tee ${LOGFILE}-mongo
            MONGO_EXIT_CODE=$?
            
            if [ $MONGO_EXIT_CODE -ne 0 ]; then
                if [ -n "$MAIL_FOR_ERRORS" ]; then
                    cat $LOGFILE-mongo | mail -s "mongo backup ${MONGOHOST} failed" "$MAIL_FOR_ERRORS"
                fi
                echo "mongodump $MONGO_ARGS exited with error $MONGO_EXIT_CODE"
                exit $MONGO_EXIT_CODE
            fi
        fi
        
        duply project backup_verify_purge --force 2>&1 | tee ${LOGFILE}
        EXIT_CODE=$?
    elif [ "$1" = 'restore' ]; then
        duply project $@ 2>&1 | tee ${LOGFILE}
        EXIT_CODE=$?
        
        if [ "$2" = 'mongo' ]; then
            if [ -z "$MONGOHOST" ]; then
              echo "you need to set the MONGOHOST env variable"
              exit 1
            fi
            MONGO_ARGS="--host $MONGOHOST --gzip"
            if [ -n "$MONGOPORT" ]; then
                MONGO_ARGS+=" --port $MONGOPORT"
            fi
            if [ -n "$MONGOUSER" ]; then
                MONGO_ARGS+=" --authenticationDatabase admin -u $MONGOUSER -p $MONGOPASSWORD"
            fi
            if [ -n "$MONGODB" ]; then
                MONGO_ARGS+=" -d $MONGODB"
            fi
            if [ -n "$MONGOREPLSET" ]; then
                MONGO_ARGS+=" --oplogReplay"
            fi
            
            mongorestore $MONGO_ARGS mongo 2>&1 | tee ${LOGFILE}-mongo
            MONGO_EXIT_CODE=$?
            
            if [ $MONGO_EXIT_CODE -ne 0 ]; then
                if [ -n "$MAIL_FOR_ERRORS" ]; then
                    cat $LOGFILE-mongo | mail -s "mongo restore ${MONGOHOST} failed" "$MAIL_FOR_ERRORS"
                fi
                echo "mongorestore $MONGO_ARGS mongo exited with error $MONGO_EXIT_CODE"
                exit $MONGO_EXIT_CODE
            fi
        fi
    else
        $@ 2>&1 | tee ${LOGFILE}
        EXIT_CODE=$?
    fi

    if [ $EXIT_CODE -ne 0 ]; then
        if [ -n "$MAIL_FOR_ERRORS" ]; then
            cat $LOGFILE | mail -s "backup ${HOSTPATH} failed" "$MAIL_FOR_ERRORS"
        fi
        exit $EXIT_CODE
    fi
else
    exec "$@"
fi
