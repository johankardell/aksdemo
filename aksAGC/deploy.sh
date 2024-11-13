sshKey=`cat ~/.ssh/id_rsa.pub`
IP="$(curl ipinfo.io/ip 2>/dev/null)"
deployACR=true

az deployment sub create --location francecentral --template-file main.bicep -n aksAGC --parameters sshkey="$sshKey" managementIP=$IP deployACR=$deployACR
