import json
import os
import boto3

dynamodb = boto3.resource("dynamodb")


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

    return {
        "message": "Item stored successfully",
        "item": item,
    }
