# https://learn.microsoft.com/en-us/azure/application-gateway/for-containers/quickstart-create-application-gateway-for-containers-managed-by-alb-controller?tabs=new-subnet-non-aks-vnet
RG='rg-aks-agc-demo'
VNET='aks-agc-demo'
SUBNET='agc'
RESOURCE_NAME='agc-aks-demo'
# RESOURCE_ID=$(az network alb show --resource-group $RESOURCE_GROUP --name $RESOURCE_NAME --query id -o tsv)
# FRONTEND_NAME='frontend'

# kubectl apply -f - <<EOF
# apiVersion: gateway.networking.k8s.io/v1
# kind: Gateway
# metadata:
#   name: gateway-01
#   namespace: test-infra
#   annotations:
#     alb.networking.azure.io/alb-id: $RESOURCE_ID
# spec:
#   gatewayClassName: azure-alb-external
#   listeners:
#   - name: http-listener
#     port: 80
#     protocol: HTTP
#     allowedRoutes:
#       namespaces:
#         from: Same
#   addresses:
#   - type: alb.networking.azure.io/alb-frontend
#     value: $FRONTEND_NAME
# EOF






ALB_SUBNET_ID=$(az network vnet subnet show -g $RG --vnet-name $VNET -n $SUBNET --query id -o tsv)

kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: alb-test-infra
EOF

kubectl apply -f - <<EOF
apiVersion: alb.networking.azure.io/v1
kind: ApplicationLoadBalancer
metadata:
  name: alb-test
  namespace: alb-test-infra
spec:
  associations:
  - $ALB_SUBNET_ID
EOF

kubectl apply -f https://raw.githubusercontent.com/MicrosoftDocs/azure-docs/refs/heads/main/articles/application-gateway/for-containers/examples/traffic-split-scenario/deployment.yaml

kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: gateway-01
  namespace: test-infra
  annotations:
    alb.networking.azure.io/alb-namespace: alb-test-infra
    alb.networking.azure.io/alb-name: alb-test
spec:
  gatewayClassName: azure-alb-external
  listeners:
  - name: http-listener
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: Same
EOF