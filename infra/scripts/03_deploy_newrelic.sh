#!/bin/bash

# Set variables
proxyAppName="proxy-php"
persistenceAppName="persistence-php"

# Initialise Terraform
terraform -chdir=../terraform/newrelic init

# Plan Terraform
terraform -chdir=../terraform/newrelic plan \
  -var NEW_RELIC_ACCOUNT_ID=$NEWRELIC_ACCOUNT_ID \
  -var NEW_RELIC_API_KEY=$NEWRELIC_API_KEY \
  -var NEW_RELIC_REGION="eu" \
  -var php_proxy_app_name=$proxyAppName \
  -var php_persistence_app_name=$persistenceAppName \
  -var notification_email="uturkarslan@newrelic.com" \
  -out "./tfplan"

# Apply Terraform
terraform -chdir=../terraform/newrelic apply tfplan

# # Destroy Terraform
# terraform -chdir=../terraform/newrelic destroy \
#   -var NEW_RELIC_ACCOUNT_ID=$NEWRELIC_ACCOUNT_ID \
#   -var NEW_RELIC_API_KEY=$NEWRELIC_API_KEY \
#   -var NEW_RELIC_REGION="eu" \
#   -var php_proxy_app_name=$proxyAppName \
#   -var php_persistence_app_name=$persistenceAppName \
#   -var notification_email="uturkarslan@newrelic.com"
