import os
import json

import boto3
import requests
from loguru import logger


client = boto3.client("sqs")


def lambda_handler(event, context):
    for record in event["Records"]:
        try:
            logger.info(f"Processing record {record['messageId']}")

            message = json.loads(record["body"])

            logger.info(f"Sending data to {message['consumer_host']}/train_model")
            response = requests.post(f"{message['consumer_host']}/train_model", json=message["package"])
            response.raise_for_status()

            logger.info(f"Response: {response.status_code} {response.text}")

        except Exception as e:
            logger.exception(e)
            client.send_message(QueueUrl=os.environ["TRAINING_DLQ_URL"], MessageBody=record["body"])
