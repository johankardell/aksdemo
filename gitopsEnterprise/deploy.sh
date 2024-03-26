sshKey=`cat ~/.ssh/id_rsa.pub`
IP="$(curl ipinfo.io/ip 2>/dev/null)"

az account set -s aks

## Deployment stack
az stack sub create --deny-settings-mode none --delete-all --location swedencentral --template-file main.bicep -n gitopsEnterprise --parameters sshkey="$sshKey" adminIp="$IP" --yes

