import hashlib
import hmac
import logging
import urllib.request
import urllib.parse
import os
import json
import pika
import ssl

aws_session_token = os.environ.get('AWS_SESSION_TOKEN')
rabbit_base_path = os.environ.get('RABBIT_BASE')
hmac_path = os.environ.get('TFE_HMAC')

rabbit_channel = None
rabbit_exchange = ""

logging.basicConfig(format='[%(levelname)s] %(message)s', level=logging.DEBUG)

def get_secret(path):
    safe_parameter = urllib.parse.quote(path, safe="")
    extension_url = 'http://localhost:2773/systemsmanager/parameters/get'
    req = urllib.request.Request(extension_url + '?withDecryption=true&name=' + safe_parameter)
    req.add_header('X-Aws-Parameters-Secrets-Token', aws_session_token)
    config = urllib.request.urlopen(req).read()
    secret_value = json.loads(config)['Parameter']['Value']
    return secret_value


def rabbit(lambda_context):
    global rabbit_channel
    global rabbit_exchange

    if rabbit_channel is not None:
        logging.info("Channel already defined; reusing...")
        return

    logging.debug("Fetching RabbitMQ configuration")
    params = get_rabbit_config()

    logging.debug("Setting up RabbitMQ connection")
    ssl_context = ssl.SSLContext(ssl.PROTOCOL_TLSv1_2)
    ssl_context.verify_mode = ssl.CERT_REQUIRED
    ssl_context.check_hostname = True
    ssl_context.load_verify_locations("ISRG_Root_X1.crt")

    credentials = pika.PlainCredentials(params["username"], params["password"])
    connection_properties = {'connection_name': lambda_context.invoked_function_arn}
    connection_parameters = pika.ConnectionParameters(credentials=credentials, client_properties=connection_properties,
                                                      ssl_options=pika.SSLOptions(ssl_context), host=params["host"],
                                                      port=int(params["port"]), virtual_host=params["vhost"])
    connection = pika.BlockingConnection(connection_parameters)
    rabbit_channel = connection.channel()
    rabbit_exchange = params["exchange"]

    logging.info("Connected to RabbitMQ")


def get_rabbit_config():
    param_names = ["exchange", "host", "port", "username", "password", "vhost"]
    params = dict(zip(param_names, [get_secret(rabbit_base_path + "/" + x) for x in param_names]))
    return params


def handler(event, context):
    logging.debug("Lambda request ID:", context.aws_request_id)

    hmac_key = get_secret(hmac_path)

    for header in ["hdr", "sig", "prefix", "dest", "src"]:
        if header not in event["queryStringParameters"]:
            return json.dumps(
                dict(statusCode=400, isBase64Encoded=False,
                     body="hdr, sig, prefix, dest, and src parameters are required."))

    hashes = {"sha512": hashlib.sha512, "sha256": hashlib.sha256}

    if event["queryStringParameters"]["hdr"] not in event["headers"]:
        logging.error("No signature detected, dropping message.")
        print(json.dumps(event["headers"]))
        return json.dumps(dict(statusCode=403, isBase64Encoded=False, body="No signature detected."))

    received_signature = event["headers"][event["queryStringParameters"]["hdr"]]
    hash_type = hashes[event["queryStringParameters"]["sig"]]
    hash_prefix = event["queryStringParameters"]["prefix"]

    event_body = event["body"]

    calculated_signature = "{0}{1}".format(hash_prefix,
                                           hmac.new(hmac_key.encode(), event_body.encode(), hash_type).hexdigest())

    if received_signature != calculated_signature:
        logging.error("Mismatched HMAC", received_signature, calculated_signature)
        return json.dumps(dict(statusCode=403, isBase64Encoded=False, body="Mismatched HMAC"))

    rabbit(context)

    logging.debug("Publishing to RabbitMQ")
    msg_headers = {
        "aws_function_arn": context.invoked_function_arn,
        "aws_request_id": context.aws_request_id,
        "log_stream_name": context.log_stream_name,
        "destination": event["queryStringParameters"]["dest"],
        "source": event["queryStringParameters"]["src"],
        "hmac": calculated_signature,
    }
    msg_props = pika.BasicProperties(content_type="application/json", headers=msg_headers)
    rabbit_channel.basic_publish(exchange=rabbit_exchange, routing_key=event["queryStringParameters"]["dest"],
                                 body=event_body, properties=msg_props)
