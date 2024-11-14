# az stack sub delete --delete-all -n aksSimple --yes
az group delete -n rg-aks-simple-demo --yes
az deployment sub delete -n aksSimple
