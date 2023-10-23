# Use AWS Lambda base image
FROM public.ecr.aws/lambda/python:3.9

# Install ImageMagick
RUN yum install -y ImageMagick

# Set the working directory
WORKDIR /var/task

# Install the required Python packages
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Add the Lambda handler to the container
COPY lambda_function.py ./

# Set the CMD to your handler (could also be done as a parameter override outside of the image)
CMD [ "lambda_function.handler" ]
