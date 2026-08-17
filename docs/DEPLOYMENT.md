# Deployment Guide: Order Service (OpenShift to AWS EKS)

## What changed in this migration
The application has been migrated from OpenShift to AWS EKS. The following changes were applied to the deployment manifests:

| OpenShift Resource | EKS Equivalent | File Path |
| :--- | :--- | :--- |
| Route | Ingress (ALB) | `k8s-openshift/ingress.yaml` |
| DeploymentConfig | Deployment | `k8s-openshift/deployment.yaml` |
| ImageStream | ECR Image URI | `k8s-openshift/deployment.yaml` |
| SCC | Pod Security Admission | (Namespace labels) |

## Prerequisites
- **AWS CLI** installed and configured.
- **kubectl** installed.
- **Docker** installed and running.
- **AWS Load Balancer Controller** must be installed on the EKS cluster to provision the ALB for the Ingress.
- IAM permissions to create ECR repositories and manage EKS clusters.

## Build and Push
The application uses the existing `Dockerfile.txt` for containerization.

1. Run the build script:
   - Linux/macOS: `./scripts/build-push.sh`
   - Windows: `scripts\build-push.bat`
2. Follow the prompts to select your registry (AWS ECR or Docker Hub).
3. The script will build the image and push it to the registry.
4. **Note the final Image URI** provided by the script; you will need it for deployment.

## Deployment Walkthrough
The deployment is performed using the migrated manifests located in the `k8s-openshift/` directory.

1. Run the deployment script:
   - Linux/macOS: `./scripts/deploy-image.sh`
   - Windows: `scripts\deploy-image.bat`
2. Provide the AWS region, EKS cluster name, and the **Full Image URI** from the build step.
3. The script applies manifests in the following order:
   - `serviceaccount.yaml`
   - `storage-pvc.yaml`
   - `deployment.yaml` (Image URI is substituted here)
   - `service.yaml`
   - `ingress.yaml`

## Image Reference
The manifests use the following placeholder for the image:
`<AWS_ACCOUNT_ID>.dkr.ecr.<AWS_REGION>.amazonaws.com/order-service:latest`

The deployment scripts use `sed` (or PowerShell) to replace this placeholder with the actual URI provided during execution.

## OpenShift to EKS Key Differences
- **No Routes**: OpenShift Routes are replaced by Kubernetes Ingress. We use the `alb` ingress class to trigger the AWS Load Balancer Controller.
- **No DeploymentConfigs**: Standard Kubernetes `Deployment` is used for rollout management.
- **No ImageStreams**: Images are pulled directly from Amazon ECR.
- **No In-Cluster Builds**: Images must be built externally (e.g., via the provided scripts) and pushed to ECR.
- **Security**: OpenShift SCCs are replaced by Kubernetes Pod Security Admission. Ensure the namespace `my-app-prod` has the appropriate labels if strict security policies are enforced.

## Troubleshooting
- **InvalidImageName**: Ensure the Image URI provided to `deploy-image.sh` is a valid ECR URI and that the EKS node IAM role has permissions to pull from ECR.
- **Ingress ADDRESS is empty**: This usually means the AWS Load Balancer Controller is not installed or is misconfigured. Check the controller logs.
- **Pods rejected by Pod Security Admission**: Check if the pod's security context (e.g., `runAsUser`) is compatible with the cluster's Pod Security Standards.
- **"no matches for kind"**: If you see this error, it means an old OpenShift-specific manifest (like `Route` or `DeploymentConfig`) is being applied. Ensure only the migrated manifests in `k8s-openshift/` are used.

## Rollback and Scaling
- **Scaling**: `kubectl scale deployment/order-service -n my-app-prod --replicas=N`
- **Rollback**: `kubectl rollout undo deployment/order-service -n my-app-prod`
