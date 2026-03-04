FROM python:3.14.3-slim-trixie
    

# Install the required packages
RUN pip install --upgrade pip
COPY requirements.txt /app/requirements.txt
WORKDIR /app
RUN pip install -r requirements.txt


# Setup flask application
COPY . /app
WORKDIR /app

# Best Practice Changes:
# 1. "--bind 0.0.0.0:5000": Ensures the container listens on all interfaces (safer than binding to a hostname "flask").
# 2. "--error-logfile -": The dash "-" tells Gunicorn to print errors to the screen (stdout).
# 3. "--preload": Loads the app before forking workers. If your code has a syntax error, it crashes immediately with a clear message.
CMD ["gunicorn", "--workers=4", "--bind", "0.0.0.0:5000", "--error-logfile", "-", "--access-logfile", "-", "--preload", "main:app"]