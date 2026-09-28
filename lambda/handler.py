def handler(event, context):
    name = event.get("name", "world")
    return {
        "statusCode": 200,
        "body": f"Hello, {name}! This is Lambda running on LocalStack."
    }
