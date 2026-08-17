#!/bin/bash
set -e

echo "-------------------------------------------------------"
echo "Build and Push to Amazon ECR / Docker Hub"
echo "-------------------------------------------------------"

# Project configuration
PROJECT_NAME="order-service"
DOCKERFILE_PATH="Dockerfile.txt"

# 1. Get Image Tag
read -p "Enter image tag [latest]: " IMAGE_TAG
IMAGE_TAG=${IMAGE_TAG:-latest}

# 2. Select Registry
echo "Select Registry:"
echo "1) AWS ECR"
echo "2) Docker Hub"
read -p "Choice [1-2]: " REGISTRY_CHOICE
REGISTRY_CHOICE=${REGISTRY_CHOICE:-1}

if [ "$REGISTRY_CHOICE" == "1" ]; then
    read -p "Enter AWS Region [us-east-1]: " AWS_REGION
    AWS_REGION=${AWS_REGION:-us-east-1}
    read -p "Enter AWS Account ID: " AWS_ACCOUNT_ID
    
    REGISTRY_URL="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
    ECR_REPO=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-*//;s/-*$//')
    FULL_IMAGE_NAME="${REGISTRY_URL}/${ECR_REPO}:${IMAGE_TAG}"

    echo "Logging into Amazon ECR..."
    aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$REGISTRY_URL"

    echo "Ensuring ECR repository exists..."
    aws ecr describe-repositories --repository-names "$ECR_REPO" --region "$AWS_REGION" >/dev/null 2>&1 || \
    aws ecr create-repository --repository-name "$ECR_REPO" --region "$AWS_REGION"
else
    read -p "Enter Docker Hub Username: " DOCKER_USER
    REGISTRY_URL="docker.io/${DOCKER_USER}"
    FULL_IMAGE_NAME="${REGISTRY_URL}/${PROJECT_NAME}:${IMAGE_TAG}"
    
    echo "Logging into Docker Hub..."
    docker login
fi

# 3. Build and Push
echo "Building image: $FULL_IMAGE_NAME"
docker build -f "$DOCKERFILE_PATH" -t "$FULL_IMAGE_NAME" .

echo "Pushing image..."
docker push "$FULL_IMAGE_NAME"

echo "-------------------------------------------------------"
echo "SUCCESS!"
echo "Image URI: $FULL_IMAGE_NAME"
echo "Use this URI when running deploy-image.sh"
echo "-------------------------------------------------------"
