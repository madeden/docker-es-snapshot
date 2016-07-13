#!/bin/bash

[ -f "aws.credentials.json" ] || {
	echo "Please create aws.credentials.json in the current folder and restart"
	exit 1
}

[ -f "es-snapshot-secret.yaml.template" ] || {
	echo "Please execute from the assets directory"
	exit 1
}

BASE64_ENC=$(cat "aws.credentials.json" | base64 --wrap=0)

sed -e "s#{{aws_config_data}}#${BASE64_ENC}#g" "es-snapshot-secret.yaml.template" \
		> es-snapshot-secret.yaml

echo "You can now execute :"
echo "   $ kubectl create -f es-snapshot-secret.yaml"
echo "   $ kubectl create -f es-snapshot-create-repository-job.yaml"
