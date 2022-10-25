#!/bin/bash

curl -Ls https://download.newrelic.com/install/newrelic-cli/scripts/install.sh | bash && sudo \
  NEW_RELIC_API_KEY=$NEWRELIC_API_KEY \
  NEW_RELIC_ACCOUNT_ID=$NEWRELIC_ACCOUNT_ID \
  NEW_RELIC_REGION=EU \
  /usr/local/bin/newrelic install
