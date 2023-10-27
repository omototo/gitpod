from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import JSONResponse
import logging
import os 

import boto3
import random
from wand.image import Image

app = FastAPI()

logger = logging.getLogger("api")
logging.basicConfig(level=logging.INFO)
s3_endpoint_url = f"https://s3.eu-central-1.amazonaws.com" 
s3 = boto3.client('s3', endpoint_url=s3_endpoint_url)
env_var = os.getenv('ENGINE', 'ECS')

@app.get("/flip-image/test")
async def flip_image(bucket: str, key: str, fail: bool = False):
    if fail:
        raise HTTPException(status_code=504, detail="Failing as requested")
    try:
        download_path = "/tmp/original_image.jpg"
        s3.download_file(bucket, key, download_path)
        
        # Flip image using Wand
        with Image(filename=download_path) as img:
            img.flip()
            img.save(filename="/tmp/flipped_image.jpg")
        
        # Upload flipped image back to S3 in the 'processed' folder
        upload_path = "processed/" + str(random.randrange(10)) + "/" + key.split("/")[-1]
        s3.upload_file("/tmp/flipped_image.jpg", bucket, upload_path)

        # Generate S3 URL for the uploaded image
        s3_url = f"s3://{bucket}/{upload_path}"
        return {"from-"+ env_var: s3_url}
    except Exception as e:
        logger.error(f"Error flipping image: {str(e)}")
        raise HTTPException(status_code=500, detail="Error processing image")

@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    return JSONResponse(
        status_code=500,
        content={"message": "An unexpected error occurred."},
    )

@app.get("/health")
async def health_check():
    return {"status": "healthy"}
