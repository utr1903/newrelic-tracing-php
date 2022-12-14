#!/bin/bash

###############
### Methods ###
###############
postDeploymentMarker() {

  local appName=$1

  appId=$(curl -X GET 'https://api.eu.newrelic.com/v2/applications.json' \
  -H "Api-Key:${NEWRELIC_API_KEY}" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  | jq -r '.applications[] | select(.name==''"'${appName}'"'') | .id')

timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
curl -X POST "https://api.eu.newrelic.com/v2/applications/$appId/deployments.json" \
  -i \
  -H "Api-Key:${NEWRELIC_API_KEY}" \
  -H "Content-Type: application/json" \
  -d \
  '{
    "deployment": {
      "revision": "1.0.0",
      "changelog": "Initial deployment",
      "description": "Deploy the app.",
      "user": "datanerd@example.com",
      "timestamp": "'"${timestamp}"'"
    }
  }'
}
#########

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

# Simulator
declare -A simulator
simulator["name"]="simulator-php"
simulator["imageName"]="simulator-php"
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

# Simulator
docker build \
  --build-arg newRelicAppName=${simulator[name]} \
  --tag ${simulator[imageName]} \
  "../../apps/simulator/."
######

### Run ###

# MySQL
docker run \
  -d \
  --rm \
  --cpus "0.05" \
  --memory "2000m" \
  --network $dockerNetwork \
  --name "${mysql[name]}" \
  -p "${mysql[port]}":"${mysql[port]}" \
  -e MYSQL_ROOT_PASSWORD="${mysql[password]}" \
  ${mysql[imageName]}

# Wait until mysql is up
sleep 10

# Create database & table
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
  --cpus "0.01" \
  --memory "50m" \
  --network $dockerNetwork \
  --name "${phpdaemon[name]}" \
  ${phpdaemon[imageName]}

# Wait until daemon is up
sleep 5

# Proxy
docker stop "${proxy[name]}"
docker run \
  -d \
  --rm \
  --cpus "0.01" \
  --memory "50m" \
  --network $dockerNetwork \
  --name "${proxy[name]}" \
  -p ${proxy[port]}:80 \
  ${proxy[imageName]}

# postDeploymentMarker ${proxy[name]}

# Persistence
docker stop "${persistence[name]}"
docker run \
  -d \
  --rm \
  --cpus "0.01" \
  --memory "50m" \
  --network $dockerNetwork \
  --name "${persistence[name]}" \
  -p ${persistence[port]}:80 \
  -e MYSQL_SERVER="${mysql[name]}" \
  -e MYSQL_USERNAME="${mysql[username]}" \
  -e MYSQL_PASSWORD="${mysql[password]}" \
  -e MYSQL_DATABASE="${mysql[database]}" \
  -e MYSQL_TABLE="${mysql[table]}" \
  ${persistence[imageName]}

# postDeploymentMarker ${persistence[name]}

# Simulator
docker stop "${simulator[name]}"
docker run \
  -d \
  --rm \
  --cpus "0.01" \
  --memory "50m" \
  --network $dockerNetwork \
  --name "${simulator[name]}" \
  ${simulator[imageName]}
######
