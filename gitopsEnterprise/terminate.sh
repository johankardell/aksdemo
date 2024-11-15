az stack group delete -g rg-aks-gitopsEnterprise-demo --action-on-unmanage deleteAll -n gitopsEnterpriseAKS --yes
az stack sub delete --action-on-unmanage deleteAll -n gitopsEnterprise --yes
