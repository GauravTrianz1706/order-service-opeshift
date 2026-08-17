@echo off
setlocal enabledelayedexpansion

echo -------------------------------------------------------
echo Deploy to AWS EKS
echo -------------------------------------------------------

set /p AWS_REGION=Enter AWS Region [us-east-1]: 
if "!AWS_REGION!"=="" set AWS_REGION=us-east-1

set /p CLUSTER_NAME=Enter EKS Cluster Name: 

set /p IMAGE_URI=Enter Full Image URI: 

echo Updating kubeconfig...
aws eks update-kubeconfig --region !AWS_REGION! --name !CLUSTER_NAME!

echo Verifying cluster connectivity...
kubectl cluster-info

echo Applying manifests...
set MANIFESTS=k8s-openshift/serviceaccount.yaml k8s-openshift/storage-pvc.yaml k8s-openshift/deployment.yaml k8s-openshift/service.yaml k8s-openshift/ingress.yaml

for %%f in (!MANIFESTS!) do (
    echo Processing %%f...
    powershell -Command "(Get-Content %%f) -replace '<AWS_ACCOUNT_ID>.dkr.ecr.<AWS_REGION>.amazonaws.com/order-service:latest', '!IMAGE_URI!' | Set-Content %%f"
    kubectl apply -f %%f
)

echo Waiting for rollout...
kubectl rollout status deployment/order-service -n my-app-prod

echo Deployment status:
kubectl get pods,svc,ingress -n my-app-prod

echo -------------------------------------------------------
echo DEPLOYMENT COMPLETE
echo Check the Ingress ADDRESS above for the application URL.
echo -------------------------------------------------------
