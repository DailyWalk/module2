import json
from datetime import datetime, timezone


def handler(event, context):
    """
    Step 1 of the workflow.
    Takes raw input data, does some processing on it,
    and passes the enriched result to the next state.
    """
    print(f"Received event: {json.dumps(event)}")

    raw_value = event.get("value")
    if raw_value is None:
        raise ValueError("Input must contain a 'value' field")

    # Example "processing": normalize + enrich the payload
    processed = {
        "id": event.get("id", "unknown"),
        "original_value": raw_value,
        "processed_value": str(raw_value).strip().upper(),
        "processed_at": datetime.now(timezone.utc).isoformat(),
        "status": "PROCESSED",
    }

    print(f"Processed result: {json.dumps(processed)}")
    return processed
