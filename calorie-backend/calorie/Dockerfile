FROM python:3.14.3-slim-trixie

# Install the required packages
RUN pip install --upgrade pip
COPY requirements.txt /calorie/requirements.txt
WORKDIR /calorie
RUN pip install -r requirements.txt

COPY . /calorie
WORKDIR /calorie

ENTRYPOINT celery -A calorie worker -Q calorie -l INFO