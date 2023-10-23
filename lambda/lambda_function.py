import boto3
from wand.image import Image
import os
import json

s3_endpoint_url = f"https://s3.eu-central-1.amazonaws.com" 
s3 = boto3.client('s3', endpoint_url=s3_endpoint_url)


def handler(event, context):
    # Extract bucket and key from the event
    print("Got event\n" + json.dumps(event, indent=2))
    if event["queryStringParameters"] is None:
        return {
            'statusCode': 200,
            'body': "Empty query string parameters"
        }
    bucket = event["queryStringParameters"]['bucket']
    key = event["queryStringParameters"]['key']
    print(f"Bucket: {bucket}")
    print(f"Key: {key}")
    download_path = '/tmp/{}'.format(os.path.basename(key))
    
    try:
        # Download image from S3
        s3.download_file(bucket, key, download_path)
        
        # Process the image with Wand
        with Image(filename=download_path) as img:
            img.flip()
            img.save(filename=download_path)
        
        # Upload the processed image back to S3 in the 'processed' directory
        processed_key = 'processed/' + os.path.basename(key)
        s3.upload_file(download_path, bucket, processed_key)
        
        return {
            'statusCode': 200,
            'body': f"s3://{bucket}/{processed_key}"
        }
    
    except Exception as e:
        return {
            'statusCode': 500,
            'body': f"Error processing image: {str(e)}"
        }
