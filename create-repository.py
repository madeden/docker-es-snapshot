from boto.connection import AWSAuthConnection

class ESConnection(AWSAuthConnection):

    def __init__(self, region, **kwargs):
        super(ESConnection, self).__init__(**kwargs)
        self._set_auth_region_name(region)
        self._set_auth_service_name("es")

    def _required_auth_capability(self):
        return ['hmac-v4']

if __name__ == "__main__":

    client = ESConnection(
            region='{{region}}',
            host='{{es_host}}',
            aws_access_key_id='{{admin_aws_key_id}}',
            aws_secret_access_key='{{admin_aws_secret_access_key}}', is_secure=False)

    print 'Registering Snapshot Repository'
    resp = client.make_request(method='POST',
            path='/_snapshot/{{snapshot_name}}',
            data='{"type": "s3","settings": { "bucket": "{{s3_log_bucket}}","region": "{{region}}","role_arn": "arn:aws:iam::{{aws_account_id}}:role/{{aws_es_backup_role_name}}"}}')
    body = resp.read()
    print body
