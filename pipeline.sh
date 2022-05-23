#!/bin/sh
# shellcheck disable=SC2181
# Copyright 2021 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# NOT TESTED END TO END

set -e

echo Pipeline for demo-pingstatus-mint-v1 in project: "$ORG" for environment: "$ENV" with host: $ENVGROUP_HOSTNAME
read -p "OK to proceed (Y/n)? " i
if [ "$i" != "Y" ]
then
  echo aborted
  exit 1
fi

mvn -P test clean
mvn -P test jshint:lint
mvn -P test frontend:install-node-and-npm@install-node-and-npm
mvn -P test frontend:npm@npm-install
mvn -P test frontend:npm@apigeelint
mvn -P test frontend:npm@unit
mvn -P test resources:copy-resources@copy-resources
mvn -P test replacer:replace@replace
mvn -P test apigee-config:targetservers
mvn -P test apigee-config:resourcefiles

# System.uuid for analytics not needed for Monetization, used for debugging.
# ./create_datacollector.sh

mvn -P test apigee-enterprise:configure
mvn -P test apigee-enterprise:deploy
mvn -P test apigee-config:apiproducts

# Rate Plans
./create_rateplan_basic.sh
./create_rateplan_revshare.sh

mvn -P test apigee-config:developers

# Prepaid and Postpaid developers
./update_developer_monetization_config.sh

# Prepaid developer balance
./create_developer_balance.sh

# Subscriptions Prepaid and Postpaid
./create_developer_subscription_basic.sh
./create_developer_subscription_revshare.sh

mvn -P test apigee-config:apps
mvn -P test apigee-config:exportAppKeys
mvn -P test frontend:npm@integration
