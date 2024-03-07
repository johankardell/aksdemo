sshKey=`cat ~/.ssh/id_rsa.pub`
IP="$(curl ipinfo.io/ip 2>/dev/null)"

# az stack sub create --deny-settings-mode none --delete-all --location swedencentral --template-file main.bicep -n aksSimple --parameters sshkey="$sshKey" --yes

az deployment sub create --location swedencentral --template-file main.bicep -n aksSimple --parameters sshkey="$sshKey" managementIP=$IP

