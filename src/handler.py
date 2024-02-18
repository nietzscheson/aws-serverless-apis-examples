def handler(event, context):
    result = "Hello from the handler!"

    return {
        'statusCode': 200,
        'body': result,
    }
