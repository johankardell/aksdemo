#!/usr/bin/env bash

set -euo pipefail

sshKey="$(cat ~/.ssh/id_rsa.pub)"
IP="$(curl --fail --silent --show-error https://ipinfo.io/ip)"
clusterAdminPrincipalId="$(az ad signed-in-user show --query id --output tsv)"
deployACR=true

az deployment sub create \
  --location swedencentral \
  --template-file main.bicep \
  --name aksSimple \
  --parameters \
    sshkey="$sshKey" \
    managementIP="${IP}/32" \
    deployACR=$deployACR \
    clusterAdminPrincipalId="$clusterAdminPrincipalId"
