#!/bin/bash

#  Copyright 2022 Google LLC
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#



export REGION="europe-west1"

gcloud alpha network-security gateway-security-policies rules delete allow-wp-pl \
    --gateway_security_policy=policy-pl \
    --location=$REGION \
    --quiet

gcloud alpha network-security gateway-security-policies rules delete allow-onet-pl \
    --gateway_security_policy=policy-pl \
    --location=$REGION \
    --quiet

gcloud alpha network-services gateways delete sg-swg-europe-west1 \
    --location=$REGION \
    --quiet

gcloud alpha network-security gateway-security-policies delete policy-pl \
    --location=$REGION \
    --quiet

sleep 30

gcloud certificate-manager certificates delete sg-swg-myorg-cert \
    --location=$REGION \
    --quiet

#Cleanup

rm ./cert.pem
rm ./key.pem

cp ./Templates/gateway.yaml ./gateway.yaml
cp ./Templates/policy-pl.yaml ./policy-pl.yaml
cp ./Templates/rule-onet.yaml ./rule-onet.yaml
cp ./Templates/rule-wp.yaml ./rule-wp.yaml