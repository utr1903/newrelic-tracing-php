FROM debian:stable

RUN apt-get update -y && \
  apt-get install curl -y && \
  apt-get install vim -y && \
  apt-get install jq -y

RUN mkdir /app
COPY simulate.sh /app

ENTRYPOINT ["bash", "/app/simulate.sh"]
