cd sampleApp
az acr build --registry jkacrsimpledemo --image sampleapp:0.1 . -f Dockerfile
cd ..
