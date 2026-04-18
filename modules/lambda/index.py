import json

def handler(event, context):
    print("=== SECURITY FINDING RECEIVED ===")
    print(json.dumps(event, indent=2))
    return {"status": "processed"}