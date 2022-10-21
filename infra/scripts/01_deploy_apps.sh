#!/bin/bash

# Get commandline arguments
while (( "$#" )); do
  case "$1" in
    --license-key)
      NEWRELIC_LICENSE_KEY="$2"
      shift
      ;;
    *)
      shift
      ;;
  esac
done

##################
### Apps Setup ###
##################

### Set variables

# Docker
dockerNetwork="php-tracing"

# MySQL
declare -A mysql
mysql["name"]="mysql"
mysql["imageName"]="mysql:8"
mysql["port"]=3306
mysql["username"]="root"
mysql["password"]="pass"
mysql["database"]="mydb"
mysql["table"]="myvalues"

# PHP daemon
declare -A phpdaemon
phpdaemon["name"]="newrelic-php-daemon"
phpdaemon["imageName"]="newrelic/php-daemon"
phpdaemon["port"]=31339

# Proxy
declare -A proxy
proxy["name"]="proxy-php"
proxy["imageName"]="proxy-php"
proxy["port"]=8080

# Persistence
declare -A persistence
persistence["name"]="persistence-php"
persistence["imageName"]="persistence-php"
persistence["port"]=8081
######

### Docker setup ###
docker network create \
  --driver bridge \
  $dockerNetwork
######

### Build ###

# Proxy
docker build \
  --build-arg newRelicAppName=${proxy[name]} \
  --build-arg newRelicLicenseKey=$NEWRELIC_LICENSE_KEY \
  --build-arg newRelicDaemonAddress="${phpdaemon[name]}:${phpdaemon[port]}" \
  --tag ${proxy[imageName]} \
  "../../apps/proxy/."

# Persistence
docker build \
  --build-arg newRelicAppName=${persistence[name]} \
  --build-arg newRelicLicenseKey=$NEWRELIC_LICENSE_KEY \
  --build-arg newRelicDaemonAddress="${phpdaemon[name]}:${phpdaemon[port]}" \
  --tag ${persistence[imageName]} \
  "../../apps/persistence/."
######

### Run ###

# MySQL
docker run \
  -d \
  --rm \
  --network $dockerNetwork \
  --name "${mysql[name]}" \
  -p "${mysql[port]}":"${mysql[port]}" \
  -e MYSQL_ROOT_PASSWORD="${mysql[password]}" \
  ${mysql[imageName]}

# Create database & table
sleep 2
sudo docker exec \
  -it ${mysql[name]} \
  mysql \
  --user=${mysql[username]} \
  --password=${mysql[password]} \
  --execute \
  "create database if not exists ${mysql[database]};\
  use ${mysql[database]};\
  create table if not exists ${mysql[table]} (id int unsigned auto_increment primary key, data varchar(255));"

# PHP daemon
docker stop "${phpdaemon[name]}"
docker run \
  -d \
  --rm \
  --network $dockerNetwork \
  --name "${phpdaemon[name]}" \
  ${phpdaemon[imageName]}

# Proxy
docker stop "${proxy[name]}"
docker run \
  -d \
  --rm \
  --network $dockerNetwork \
  --name "${proxy[name]}" \
  -p ${proxy[port]}:80 \
  ${proxy[imageName]}

# Persistence
docker stop "${persistence[name]}"
docker run \
  -d \
  --rm \
  --network $dockerNetwork \
  --name "${persistence[name]}" \
  -p ${persistence[port]}:80 \
  -e MYSQL_SERVER="${mysql[name]}" \
  -e MYSQL_USERNAME="${mysql[username]}" \
  -e MYSQL_PASSWORD="${mysql[password]}" \
  -e MYSQL_DATABASE="${mysql[database]}" \
  -e MYSQL_TABLE="${mysql[table]}" \
  ${persistence[imageName]}
######
