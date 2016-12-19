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
            if [ -z "$MONGOHOST" ]; then
              echo "you need to set the MONGOHOST env variable"
              exit 1
            fi
            MONGO_ARGS=(-o /to_backup --host $MONGOHOST)
            if [ -n "$MONGOPORT" ]; then
                MONGO_ARGS+=(--port $MONGOPORT)
            fi
            if [ -n "$MONGOUSER" ]; then
                MONGO_ARGS+=(--authenticationDatabase admin -u $MONGOUSER -p $MONGOPASSWORD)
            fi
            if [ -n "$MONGODB" ]; then
                MONGO_ARGS+=(-d $MONGODB)
            fi
            if [ -n "$MONGOREPLSET" ]; then
                MONGO_ARGS+=(--oplog)
            fi
            
            mongodump ${MONGO_ARGS[@]} > ${LOGFILE}-mongo 2>&1
            MONGO_EXIT_CODE=$?
            
            if [ $MONGO_EXIT_CODE -ne 0 ]; then
                if [ -n "$MAIL_FOR_ERRORS" ]; then
                    cat $LOGFILE-mongo | mail -s "mongo backup ${MONGO_HOST} failed" "$MAIL_FOR_ERRORS"
                fi
                echo "mongodump ${MONGO_ARGS[@]}"
                cat $LOGFILE-mongo
                exit $MONGO_EXIT_CODE
            fi
        fi
        
        duply project backup_verify_purge --force > ${LOGFILE} 2>&1
        EXIT_CODE=$?
    elif [ "$1" = 'restore' ]; then
        duply project $@ > ${LOGFILE} 2>&1
        EXIT_CODE=$?
        
        if [ "$2" = 'mongo' ]; then
            if [ -z "$MONGO_HOST" ]; then
              echo "you need to set the MONGO_HOST env variable"
              exit 1
            fi
            MONGO_ARGS="--oplogReplay --host $MONGO_HOST"
            if [ -n "$MONGO_PORT" ]; then
                MONGO_ARGS="$MONGO_ARGS --port $MONGO_PORT"
            fi
            if [ -n "$MONGO_USER" ]; then
                MONGO_ARGS="$MONGO_ARGS --authenticationDatabase admin -u $MONGO_USER -p $MONGO_PASSWORD"
            fi
            if [ -n "$MONGO_DB" ]; then
                MONGO_ARGS="$MONGO_ARGS -d $MONGO_DB"
            fi
            
            mongorestore $MONGO_ARGS mongo > ${LOGFILE}-mongo 2>&1
            MONGO_EXIT_CODE=$?
            
            if [ -n "$MAIL_FOR_ERRORS" ] && [ $MONGO_EXIT_CODE -ne 0 ]; then
                cat $LOGFILE-mongo | mail -s "backup ${HOSTPATH} failed" "$MAIL_FOR_ERRORS"
            fi
            if [ $MONGO_EXIT_CODE -ne 0 ]; then
                if [ -n "$MAIL_FOR_ERRORS" ]; then
                    cat $LOGFILE-mongo | mail -s "mongo backup ${MONGO_HOST} failed" "$MAIL_FOR_ERRORS"
                fi
                cat mongorestore $MONGO_ARGS mongo
                cat $LOGFILE-mongo
                exit $MONGO_EXIT_CODE
            fi
        fi
    else
        $@ > ${LOGFILE} 2>&1
        EXIT_CODE=$?
    fi

    if [ $EXIT_CODE -ne 0 ]; then
        if [ -n "$MAIL_FOR_ERRORS" ]; then
            cat $LOGFILE | mail -s "backup ${HOSTPATH} failed" "$MAIL_FOR_ERRORS"
        fi
        cat $LOGFILE
        exit $EXIT_CODE
    fi
else
    exec "$@"
fi
