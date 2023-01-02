import hashlib
import hmac
import urllib.request
import urllib.parse
import os
import json
import boto3
import pika

aws_session_token = os.environ.get('AWS_SESSION_TOKEN')
rabbit_base_path = os.environ.get('RABBIT_BASE')

rabbit_channel = None
rabbit_exchange = ""

def get_secret(path):
    safe_parameter = urllib.parse.quote(path, safe="")
    extension_url = 'http://localhost:2773/systemsmanager/parameters/get'
    req = urllib.request.Request(extension_url + '?withDecryption=true&name=' + safe_parameter)
    req.add_header('X-Aws-Parameters-Secrets-Token', aws_session_token)
    config = urllib.request.urlopen(req).read()
    secret_value = json.loads(config)['Parameter']['Value']
    return secret_value

def rabbit():
    global rabbit_channel
    global rabbit_exchange

    if rabbit_channel is not None:
        print("Channel defined")
        return

    param_names = ["exchange", "host", "port", "username", "password", "vhost"]
    params = dict(zip(param_names, [get_secret(rabbit_base_path + "/" + x) for x in param_names]))

    print(json.dumps(params))

    connection = pika.BlockingConnection(
        pika.ConnectionParameters(credentials=pika.PlainCredentials(params["username"], params["password"]), ssl=True,
                                  host=params["host"], virtual_host=params["vhost"]))
    rabbit_channel = connection.channel()
    rabbit_exchange = params["exchange"]

def handler(event, context):
    print("Lambda Request ID:", context.aws_request_id)

    hmac_key = get_secret(os.environ.get('TFE_HMAC'))
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

    rabbit()

    print("publishing message")

    rabbit_channel.basic_publish(exchange=rabbit_exchange, routing_key='Lambda', body='Howdy RabbitMQ, Lambda Here!!')
