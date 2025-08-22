import boto3
import json
import os
from datetime import datetime, timezone
secrets_client = boto3.client("secretsmanager")
sns_client = boto3.client("sns")
SECRET_NAME = "acr/test/dummy"
SNS_TOPIC_ARN = "arn:aws:sns:us-east-1:833376745199:acr-jira-token-expiry-test" # set in Lambda env variables
def lambda_handler(event, context):
    # Get secret value
    secret_value = secrets_client.get_secret_value(SecretId=SECRET_NAME)
    secret = json.loads(secret_value["SecretString"])
    # Extract token and expiry date
    token = secret["token"]
    expiry_date = datetime.fromisoformat(secret["expiryDate"].replace("Z", "+00:00"))
    # Calculate days left
    days_left = (expiry_date - datetime.now(timezone.utc)).days
    # If nearing expiry, send alert
    if days_left <= 15:
        message = (
            f"Hello Team, \n"
            f"Jira API token in `{SECRET_NAME}` is expiring in {days_left} days "
            f"Kindly Rotate token before its exipry in AWS Secret Manager \n"
            f"(expiry: {expiry_date.date()}).\n"
            f"Token (masked): {token[:4]}**** \n"
            f"AWS Secret location - https://us-east-1.console.aws.amazon.com/secretsmanager/secret?name=jira%2Fapi%2Ftoken&region=us-east-1 \n"
            f"Thank you\n"
            f"ACR SRE TEAM\n"
        )
        sns_client.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject="Jira API Token Expiry Alert",
            Message=message
        )
