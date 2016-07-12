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
#      a. ES_SNAPSHOT_NAME is the name of the ES snapshot repository  (created via script above)
#      b. ES HOST and ES_PORT define URL of the AWS ES Cluster
#      c. PATTERN defines the indices pattern to track. Defaults to logstash
#      d. LOG_FILE defines the log file use. Note that this will be reset at each run. No need to change
#      e. RETENTION defines the number of days of indices to keep
#   2. In k8s, 
#      a. If the version is <=1.2.4 then there are no cronjobs, and you need to operate with this. 
#      b. If version is >1.3, then the cron should be removed from the Docker image, and this run as a cron
# 
# Note the behavior of the container to tail the log is to keep it alive as cron does not run in foreground
#
# This version is primarily for AWS ElasticSearch hence Curator doesn't work (security endpoint doesn't allow
# access to metadata). If you run a cluster yourself, you can definitely adapt by commenting and uncommenting 
# in this Dockerfile. I provide the example curator configuration and actions to perform the same operation. Both
# would need rendering with the same variables as above. 
#
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
	${APT_CMD} install -yqq ${APT_FORCE} \
		cron \
		curl && \
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

# Add crontab file
RUN echo '00 9 * * * root /usr/bin/run.sh' >> /etc/crontab
# COPY curator.yaml /root/.curator/curator.yml
# COPY actions.yaml /root/.curator/actions.yml

RUN touch ${LOG_FILE}

COPY run.sh /usr/bin/run.sh
RUN chmod +x /usr/bin/run.sh

CMD [ "cron", "-f" ]


