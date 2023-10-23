from typing import Optional
from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import JSONResponse
import logging


app = FastAPI()

logger = logging.getLogger("api")
logging.basicConfig(level=logging.INFO)

@app.get("/flip-image/test")
#default values for bucket and key
async def flip_image(
    bucket: Optional[str] = None, 
    key: Optional[str] = None, 
    fail: Optional[bool] = False):
    if fail:
        raise HTTPException(status_code=504, detail="Failing as requested")
    try:
        return {"backend1": "success"}
    except Exception as e:
        logger.error(f"Error flipping image: {str(e)}")
        raise HTTPException(status_code=503, detail="Error processing image")

@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    return JSONResponse(
        status_code=500,
        content={"message": "An unexpected error occurred."},
    )

@app.get("/health")
async def health_check():
    return {"status": "healthy"}