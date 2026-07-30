import json


def handler(event, context):
    """
    Simple greeting Lambda.
    Accepts an optional 'name' query string parameter via API Gateway
    (HTTP API, payload format 2.0) and returns a JSON greeting.

    Example:
      GET /greet            -> {"message": "Hello, World! Welcome to the serverless API."}
      GET /greet?name=Alice -> {"message": "Hello, Alice! Welcome to the serverless API."}
    """
    query_params = event.get("queryStringParameters") or {}
    name = query_params.get("name", "World").strip() or "World"

    body = {
        "message": f"Hello, {name}! Welcome to the CE13-KH serverless API."
    }

    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps(body)
    }
