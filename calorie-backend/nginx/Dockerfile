FROM nginx:1.29.5-alpine

COPY . /app

RUN rm /etc/nginx/conf.d/default.conf
COPY default.conf /etc/nginx/conf.d/