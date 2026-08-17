#!/bin/bash
set -e
set -o pipefail

echo "-------------------------------------------------------"
echo "Deploy to AWS EKS"
echo "-------------------------------------------------------"

# 1. Inputs
read -p "Enter AWS Region [us-east-1]: " AWS_REGION
AWS_REGION=${AWS_REGION:-us-east-1}

read -p "Enter EKS Cluster Name: " CLUSTER_NAME

read -p "Enter Full Image URI (e.g. <account>.dkr.ecr.<region>.amazonaws.com/order-service:latest): " IMAGE_URI

# 2. Configure kubectl
echo "Updating kubeconfig..."
aws eks update-kubeconfig --region "$AWS_REGION" --name "$CLUSTER_NAME"

echo "Verifying cluster connectivity..."
kubectl cluster-info

# 3. Define Manifests
# Using the migrated manifests found in k8s-openshift/
MANIFESTS=(
    "k8s-openshift/serviceaccount.yaml"
    "k8s-openshift/storage-pvc.yaml"
    "k8s-openshift/deployment.yaml"
    "k8s-openshift/service.yaml"
    "k8s-openshift/ingress.yaml"
)

# 4. Apply Manifests
echo "Applying manifests..."
for manifest in "${MANIFESTS[@]}"; do
    if [ -f "$manifest" ]; then
        echo "Processing $manifest..."
        # Substitute image placeholder
        sed -i 's|<AWS_ACCOUNT_ID>.dkr.ecr.<AWS_REGION>.amazonaws.com/order-service:latest|'$IMAGE_URI'|g' "$manifest"
        kubectl apply -f "$manifest"
    else
        echo "Warning: Manifest $manifest not found, skipping."
    fi
done

# 5. Verification
echo "Waiting for rollout..."
kubectl rollout status deployment/order-service -n my-app-prod

echo "Deployment status:"
kubectl get pods,svc,ingress -n my-app-prod

echo "-------------------------------------------------------"
echo "DEPLOYMENT COMPLETE"
echo "Check the Ingress ADDRESS above for the application URL."
echo "-------------------------------------------------------"
