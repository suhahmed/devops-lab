#!/usr/bin/env bash
set -eo pipefail

# --- AWS & CLUSTER VARIABLES (TAILORED TO YOUR FOOTPRINT) ---
AWS_ACCOUNT_ID="767261812371"      
AWS_REGION="us-east-1"              
IMAGE_NAME="devops-lab-secure-app"
IMAGE_TAG=$(date +%Y%m%d%H%M%S)     
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
KUBECONFIG_PATH="$HOME/.kube/config"

# (Optional) If you have a SonarQube instance inside your VPC
SONAR_URL="http://10.0.2.101:9000"   

echo "=========================================================="
echo " Starting Secure Containerless DevSecOps Pipeline"
echo "=========================================================="

# 1. SECRET SCAN GATE
echo "===> Stage 1: Running Gitleaks Plaintext Secret Inspection..."
gitleaks dir --verbose --redact .

# 2. SOFTWARE COMPOSITION ANALYSIS (SCA)
echo "===> Stage 2: Scanning Project Dependencies with Trivy..."
trivy fs --severity CRITICAL --exit-code 1 .

# 3. DAEMONLESS CONTAINER IMAGE COMPILING (BUILDAH)
echo "===> Stage 3: Compiling Image Artifact using Buildah..."
buildah bud -t ${ECR_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} .

# 4. CONTAINER IMAGE VULNERABILITY GATE SCAN
echo "===> Stage 4: Exporting and Auditing Container Layer Vulnerabilities..."
buildah push ${ECR_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} oci-archive:app-image.tar
trivy image --severity HIGH,CRITICAL --exit-code 1 --input app-image.tar
rm -f app-image.tar

# 5. SECURE AMAZON ECR REGISTRY PUSH
echo "===> Stage 5: Uploading Secure OCI Image to AWS ECR..."
AWS_TOKEN=$(aws ecr get-login-password --region ${AWS_REGION})
buildah push --creds AWS:${AWS_TOKEN} ${ECR_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}

# 6. INTERNAL PRIVATE NETWORK KUBERNETES DEPLOYMENT
echo "===> Stage 6: Initiating Secure Application Rollout (10.0.2.0/24)..."
kubectl set image deployment/app-deployment web-container=${ECR_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} \
  --kubeconfig=${KUBECONFIG_PATH} \
  -n default

kubectl rollout status deployment/app-deployment --kubeconfig=${KUBECONFIG_PATH} -n default

echo "=========================================================="
echo " Success: DevSecOps Flow Validation Complete!"
echo "=========================================================="

