FROM python:3.14.3-slim-trixie

# Install the required packages
RUN pip install --upgrade pip
COPY requirements.txt /app/requirements.txt
WORKDIR /app
RUN pip install -r requirements.txt

# Setup fastapi application
COPY . /app
WORKDIR /app

# Run uvicorn server
# --host 0.0.0.0 makes it accessible outside the container
# --port 5000 matches the previous flask port for convenience in docker-compose
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "5000"]
