@echo off
setlocal enabledelayedexpansion

echo -------------------------------------------------------
echo Build and Push to Amazon ECR / Docker Hub
echo -------------------------------------------------------

set PROJECT_NAME=order-service
set DOCKERFILE_PATH=Dockerfile.txt

set /p IMAGE_TAG=Enter image tag [latest]: 
if "!IMAGE_TAG!"=="" set IMAGE_TAG=latest

echo Select Registry:
echo 1) AWS ECR
echo 2) Docker Hub
set /p REGISTRY_CHOICE=Choice [1-2]: 
if "!REGISTRY_CHOICE!"=="" set REGISTRY_CHOICE=1

if "!REGISTRY_CHOICE!"=="1" (
    set /p AWS_REGION=Enter AWS Region [us-east-1]: 
    if "!AWS_REGION!"=="" set AWS_REGION=us-east-1
    set /p AWS_ACCOUNT_ID=Enter AWS Account ID: 
    
    set REGISTRY_URL=!AWS_ACCOUNT_ID!.dkr.ecr.!AWS_REGION!.amazonaws.com
    set ECR_REPO=!PROJECT_NAME!
    set ECR_REPO=!ECR_REPO: =-!
    set FULL_IMAGE_NAME=!REGISTRY_URL!/!ECR_REPO!:!IMAGE_TAG!

    echo Logging into Amazon ECR...
    aws ecr get-login-password --region !AWS_REGION! | docker login --username AWS --password-stdin !REGISTRY_URL!

    echo Ensuring ECR repository exists...
    aws ecr describe-repositories --repository-names !ECR_REPO! --region !AWS_REGION! >nul 2>&1
    if !ERRORLEVEL! neq 0 (
        aws ecr create-repository --repository-name !ECR_REPO! --region !AWS_REGION!
    )
) else (
    set /p DOCKER_USER=Enter Docker Hub Username: 
    set REGISTRY_URL=docker.io/!DOCKER_USER!
    set FULL_IMAGE_NAME=!REGISTRY_URL!/!PROJECT_NAME!:!IMAGE_TAG!
    
    echo Logging into Docker Hub...
    docker login
)

echo Building image: !FULL_IMAGE_NAME!
docker build -f !DOCKERFILE_PATH! -t !FULL_IMAGE_NAME! .

echo Pushing image...
docker push !FULL_IMAGE_NAME!

echo -------------------------------------------------------
echo SUCCESS!
echo Image URI: !FULL_IMAGE_NAME!
echo Use this URI when running deploy-image.sh
echo -------------------------------------------------------
