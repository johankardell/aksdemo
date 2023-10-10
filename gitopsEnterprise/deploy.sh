sshKey=`cat ~/.ssh/id_rsa.pub`

## Classic deployment
# az deployment sub create --location swedencentral --template-file main.bicep -n gitopsEnterprise --parameters sshkey="$sshKey"


## Deployment stack
az stack sub create --deny-settings-mode none --delete-all --location swedencentral --template-file main.bicep -n gitopsEnterprise --parameters sshkey="$sshKey" --yes
