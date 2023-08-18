sshKey=`cat ~/.ssh/id_rsa.pub`

az deployment sub create --location swedencentral --template-file main.bicep -n aksdemo --parameters sshkey="$sshKey"