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

# Reading Credentials
AWS_ACCESS_KEY_ID=$(jq '.accessKeyId' /root/.aws/aws.credentials.json | tr -d '"')
AWS_SECRET_ACCESS_KEY=$(jq '.secretAccessKey' /root/.aws/aws.credentials.json | tr -d '"')
REGION=$(jq '.region' /root/.aws/aws.credentials.json | tr -d '"')
ACCOUNT_ID=$(jq '.accountId' /root/.aws/aws.credentials.json | tr -d '"')
BACKUP_ROLE_ID=$(jq '.backupRoleId' /root/.aws/aws.credentials.json | tr -d '"')
S3_LOG_BUCKET=$(jq '.s3Bucket' /root/.aws/aws.credentials.json | tr -d '"')


sed -i -e "s#{{admin_aws_key_id}}#${AWS_ACCESS_KEY_ID}#g" \
    -e "s#{{admin_aws_secret_access_key}}#${AWS_SECRET_ACCESS_KEY}#g" \
    -e "s#{{region}}#${REGION}#g" \
    -e "s#{{es_host}}#${ES_HOST}\:${ES_PORT}#g" \
    -e "s#{{snapshot_name}}#${ES_SNAPSHOT_NAME}#g" \
    -e "s#{{s3_log_bucket}}#${S3_LOG_BUCKET}#g" \
    -e "s#{{aws_account_id}}#${ACCOUNT_ID}#g" \
    -e "s#{{aws_es_backup_role_name}}#${BACKUP_ROLE_ID}#g" \
    "/usr/bin/create-repository.py"

python "/usr/bin/create-repository.py"
# echo "" | tee "${LOG_FILE}"
