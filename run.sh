#!/bin/bash

LOGTAG="es-backup"
FACILITY=local0

touch "${LOG_FILE}"

function log() {
    local LOGLEVEL=$1
	shift
    local LOGLINE="$*"

    echo "["`date`"] ["${LOGTAG}"] ["${FACILITY}.${LOGLEVEL}"] : "${LOGLINE} | tee -a ${LOG_FILE}
}


INDICES=$(curl -s http://${ES_HOST}:${ES_PORT}/_cat/indices?v | grep ${PATTERN} | awk '{ print $3 }' | sort -r)

[ -z "${INDICES}" ] && {
	log info "No indices returned containing $PATTERN found on ${ES_HOST}" && \
	exit 0	
} || {
	log info "Preparing to backup indices ${INDICES}"
}

# First let us backup the whole thing
curl -XPUT "http://${ES_HOST}:${ES_PORT}/_snapshot/${ES_SNAPSHOT_NAME}/$(date +%Y-%m-%d)?wait_for_completion=true" && {
	log info Successfully backed up all indices to ${S3_BUCKET}. Now Deleting indexes
	declare -a INDEX=(${INDICES})
	if [ ${#INDEX[@]} -gt ${RETENTION} ]; then
	  for index in ${INDEX[@]:${RETENTION}};do
	    # We don't want to accidentally delete everything
	    if [ -n "${index}" ]; then
	        log info Deleting index: ${index}
	        curl -s -XDELETE "${ES_HOST}:${ES_PORT}/${index}/" 
	    fi
	  done
	fi
} || {
	log err Oups. Something wrong happened
}

# echo "" | tee "${LOG_FILE}"
