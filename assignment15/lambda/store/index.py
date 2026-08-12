import json
import os
import boto3

dynamodb = boto3.resource("dynamodb")
cloudwatch = boto3.client("cloudwatch")


def handler(event, context):
    """
    Step 2 of the workflow.
    Takes the processed data from the previous state
    and stores it in DynamoDB.
    """
    print(f"Received event: {json.dumps(event)}")

    table_name = os.environ["TABLE_NAME"]
    table = dynamodb.Table(table_name)

    item = {
        "id": event["id"],
        "original_value": event.get("original_value"),
        "processed_value": event.get("processed_value"),
        "processed_at": event.get("processed_at"),
        "status": "STORED",
    }

    table.put_item(Item=item)
    print(f"Stored item in {table_name}: {json.dumps(item)}")

    # Emit a custom metric so CloudWatch can alarm on "items stored"
    cloudwatch.put_metric_data(
        Namespace="ServerlessWorkflow",
        MetricData=[
            {
                "MetricName": "ItemsStored",
                "Value": 1,
                "Unit": "Count",
            }
        ],
    )

    return {
        "message": "Item stored successfully",
        "item": item,
    }
