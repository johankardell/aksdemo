sshKey=`cat ~/.ssh/id_rsa.pub`
location="swedencentral"

IP="$(curl ipinfo.io/ip 2>/dev/null)"

## Deployment stack
az stack sub create --deny-settings-mode none --action-on-unmanage deleteAll --location "$location" --template-file main.bicep -n gitopsEnterprise --yes --parameters sshkey="$sshKey" location="$location" 

