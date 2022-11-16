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
export PROJECT_ID="sg-sg-demo-2e6160da"
export NETWORK="vpc-internal-custom"
export SUBNET="subnet-a"

# Check if REGIONAL_MANAGED_PROXY exist
if [[ $(gcloud compute networks subnets list --filter="purpose=REGIONAL_MANAGED_PROXY" --format=flattened | wc -c)  -eq 0 ]]; then
    echo "Please configure REGIONAL_MANAGED_PROXY per: https://cloud.google.com/secure-web-gateway/docs/initial-setup-steps#create_a_proxy_subnet"
    return 0
fi


# Generate self signed SSL cert
openssl req -x509 -newkey rsa:2048 \
 -keyout key.pem \
 -out cert.pem \
 -days 365 \
 -nodes \
 -subj "/C=PL/ST=mazowieckie/L=Warszawa/O=My Company/OU=Myorg/CN=swg.myorg.com"

gcloud certificate-manager certificates create sg-swg-myorg-cert \
   --certificate-file=./cert.pem \
   --private-key-file=./key.pem \
   --location=$REGION



export CERTIFICATE=$(gcloud certificate-manager certificates describe sg-swg-myorg-cert --location=$REGION --format="value(name)")

cp ./Templates/gateway.yaml ./gateway.yaml
cp ./Templates/policy-pl.yaml ./policy-pl.yaml
cp ./Templates/rule-onet.yaml ./rule-onet.yaml
cp ./Templates/rule-wp.yaml ./rule-wp.yaml

sed -i "s|{{PROJECT_ID}}|$PROJECT_ID|g" ./*.yaml
sed -i "s|{{REGION}}|$REGION|g" ./*.yaml
sed -i "s|{{NETWORK}}|$NETWORK|g" ./*.yaml
sed -i "s|{{SUBNET}}|$SUBNET|g" ./*.yaml
sed -i "s|{{CERTIFICATE}}|$CERTIFICATE|g" ./*.yaml

gcloud alpha network-security gateway-security-policies import policy-pl \
  --source=policy-pl.yaml --location=$REGION

gcloud alpha network-security gateway-security-policies rules import allow-wp-pl \
   --source=rule-wp.yaml \
   --location=$REGION \
   --gateway_security_policy=policy-pl

gcloud alpha network-security gateway-security-policies rules import allow-onet-pl \
   --source=rule-onet.yaml \
   --location=$REGION \
   --gateway_security_policy=policy-pl

gcloud alpha network-services gateways import sg-swg-europe-west1 \
  --source=gateway.yaml \
  --location=$REGION
