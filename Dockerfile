# This container takes a snapshot of an AWS ES cluster and backup to S3, then deletes old indices. 
# It was inspired by the [official documentation](http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-managedomains.html)
# and [this post](http://freshlex.com/2016/06/21/part-6-backup-elasticsearch-to-amazon-simple-storage-service-s3/), as well as 
# [this intro](https://medium.com/@rcdexta/periodic-snapshotting-of-elasticsearch-indices-f6b6ca221a0c#.ca8lifyif) to Curator
# 
# Usage: 
# Before anything, read the blog and doc, and create the IAM Role and Policy, then render and run the attached python script from a location 
# that can access the ES endpoint (depends on your security measures). Note that you will
# need python-boto on the system to run this (apt install python-boto)
#
# The following parameters must be rendered: 
#
# * {{region}}: your profile region
# * {{es_host}}: end point of your ES cluster
# * {{es_snapshot_name}}: name of the snapshot. Do not use "." in the name
# * {{admin_aws_key_id}}: AWS Key that can use the ES role (see documentation)
# * {{admin_aws_secret_access_key}}: AWS secret of the above key
# * {{s3_log_bucket}}: S3 Bucket to use for backups
# * {{aws_account_id}}: AWS Account ID
# * {{aws_es_backup_role_name}}: Name of the role your created before
#
# 
#   1. Setup env variables
#      a. S3_BUCKET is where the backup will be done
#      b. ES HOST and ES_PORT define URL of the AWS ES Cluster
#      c. PATTERN defines the indices pattern to track. Defaults to logstash
#      d. LOG_FILE defines the log file use. Note that this will be reset at each run. No need to change
#      e. RETENTION defines the number of days of indices to keep
#   2.a. In k8s, create a secret based on an AWS credential files
#   2.b. In Docker "solo", create an AWS credentials file with the account you want to use
#   3.a. (k8s): Launch with :
#      kubectl create -f s3 k8s-incron_s3-rc.yaml
#   3.b. (Docker) Launch with : 
#      docker run --rm=true \
#          -v /path/to/aws/credentials:/root/.aws/credentials \
#          -v /path/to/folder/to/monitor:root/incron \
#          -v /path/to/incron/file:/var/spool/incron/root \
#          -e S3_BUCKET=<S3-bucket-name>
#          samnco/docker-incron-s3
# 
# Now everytime the file mentioned in the incron file is modified (or other rules applying to it)
# a version of the file with the date and time appended at the end will be uploaded in the S3
# bucket. 
# If the bucket doesn't exist on first execution, it will be created
#
# Testing: you can build the image and remove the commented "ADD" line and have something nearly automated
#
FROM ubuntu:16.04

MAINTAINER Samuel Cozannet <samuel.cozannet@madeden.com>

ENV APT_CMD="apt" 
ENV APT_FORCE="--allow-downgrades --allow-remove-essential --allow-change-held-packages" 

ENV ES_SNAPSHOT_NAME="es-s3-backup"
ENV ES_HOST=localhost
ENV ES_PORT=9200
ENV PATTERN=logstash
ENV LOG_FILE=/var/log/es-backup.log
ENV RETENTION=7

RUN	${APT_CMD} update && \
	${APT_CMD} install -yqq ${APT_FORCE} curl && \
	${APT_CMD} clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Waiting for an update of AWS ES to activate this
# RUN	${APT_CMD} update && \
# 	${APT_CMD} install -yqq ${APT_FORCE} curl \
# 		python \
# 		python-pip \
# 		elasticsearch-curator && \
# 	${APT_CMD} clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# RUN pip install requests-aws4auth

# RUN mkdir -p /root/.curator

# Add crontab file in the cron directory
COPY crontab /etc/cron.d/es-backup-daily
# COPY curator.yaml /root/.curator/curator.yml
# COPY actions.yaml /root/.curator/actions.yml

RUN chmod 0644 /etc/cron.d/es-backup-daily

COPY run.sh /usr/bin/run.sh
RUN chmod +x /usr/bin/run.sh

CMD cron && tail -f /var/log/es-backup.log


