import hashlib
import hmac
import urllib.request
import urllib.parse
import os
import json

aws_session_token = os.environ.get('AWS_SESSION_TOKEN')
hmac_path = os.environ.get('TFE_HMAC')


def handler(event, context):
    print("Lambda function ARN:", context.invoked_function_arn)
    print("CloudWatch log stream name:", context.log_stream_name)
    print("CloudWatch log group name:",  context.log_group_name)
    print("Lambda Request ID:", context.aws_request_id)

    safe_parameter = urllib.parse.quote(hmac_path, safe="")
    req = urllib.request.Request('http://localhost:2773/systemsmanager/parameters/get?name=' + safe_parameter)
    req.add_header('X-Aws-Parameters-Secrets-Token', aws_session_token)
    config = urllib.request.urlopen(req).read()
    print(json.loads(config)['Parameter']['Value'])

    received_signature = event["headers"]["x-tfe-notification-signature"]
    event_body = event["body"]

    calculated_signature = hmac.new("".encode(), event_body.encode(), hashlib.sha512).hexdigest()

    print("received signature =", received_signature)
    print("calcul.  signature =", calculated_signature)
    print(event_body)


