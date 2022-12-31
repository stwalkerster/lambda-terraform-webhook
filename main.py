import hashlib
import hmac
import urllib.request
import urllib.parse
import os
import json
import boto3

aws_session_token = os.environ.get('AWS_SESSION_TOKEN')
hmac_path = os.environ.get('TFE_HMAC')


def handler(event, context):
    print("Lambda Request ID:", context.aws_request_id)
    external_ip = urllib.request.urlopen('https://ident.me').read().decode('utf8')
    print(external_ip)

    safe_parameter = urllib.parse.quote(hmac_path, safe="")
    extension_url = 'http://localhost:2773/systemsmanager/parameters/get'
    req = urllib.request.Request(extension_url + '?withDecryption=true&name=' + safe_parameter)
    req.add_header('X-Aws-Parameters-Secrets-Token', aws_session_token)
    config = urllib.request.urlopen(req).read()
    hmac_key = json.loads(config)['Parameter']['Value']

    received_signature = event["headers"]["x-tfe-notification-signature"]
    event_body = event["body"]

    calculated_signature = hmac.new(hmac_key.encode(), event_body.encode(), hashlib.sha512).hexdigest()

    if received_signature != calculated_signature:
        print("Mismatched HMAC", received_signature, calculated_signature)
        return json.dumps(dict(statusCode=403, isBase64Encoded=False, body="Mismatched HMAC"))

    print(event_body)

    dynamodb = boto3.client('dynamodb')
    item = {
        'request': {'S': context.aws_request_id},
        'body': {'S': event_body},
        'hmac': {'S': received_signature}
    }
    dynamodb.put_item(TableName='TerraformNotifications', Item=item)
