# Use an slim Python runtime as a parent image for building
FROM tiangolo/uvicorn-gunicorn:python3.11-slim as builder
WORKDIR /app
COPY ./app /app
RUN pip install boto3 Wand fastapi

# Use the Slim image for the runtime
FROM tiangolo/uvicorn-gunicorn:python3.11-slim
WORKDIR /app

# Install ImageMagick 
ENV MAGICK_HOME=/usr
RUN apt-get update && apt-get install imagemagick -y

COPY --from=builder /app /app
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
