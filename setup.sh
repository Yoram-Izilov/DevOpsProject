#!/bin/bash
############### EKS ###############
# Define variables
REGION="us-east-1"
CLUSTER_NAME="carmel-yoram-eks-cluster"
ECR_REPO="602401143452.dkr.ecr.us-east-1.amazonaws.com/amazon/aws-load-balancer-controller"
AWS_LOAD_BALANCER_POLICY="arn:aws:iam::992382545251:policy/AWSLoadBalancerControllerIAMPolicy"
EXTERNAL_DNS_POLICY="arn:aws:iam::992382545251:policy/AllowExternalDNSUpdates"

# Get the VPC ID of the EKS cluster
VPC_ID=$(aws eks describe-cluster --name "$CLUSTER_NAME" --query "cluster.resourcesVpcConfig.vpcId" --output text)

# Check if VPC_ID is not empty
if [ -z "$VPC_ID" ]; then
  echo "Error: Unable to retrieve VPC ID for cluster $CLUSTER_NAME."
  exit 1
fi

# Update kubeconfig
aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER_NAME"

# Associate IAM OIDC provider
eksctl utils associate-iam-oidc-provider --region "$REGION" --cluster "$CLUSTER_NAME" --approve

# Create IAM service account for AWS Load Balancer Controller
eksctl create iamserviceaccount --cluster="$CLUSTER_NAME" --namespace=kube-system \
  --name=aws-load-balancer-controller --attach-policy-arn="$AWS_LOAD_BALANCER_POLICY" \
  --override-existing-serviceaccounts --approve

# Create IAM service account for External DNS
eksctl create iamserviceaccount --name external-dns --namespace default \
  --cluster "$CLUSTER_NAME" --attach-policy-arn="$EXTERNAL_DNS_POLICY" \
  --approve --override-existing-serviceaccounts

# service account for Elastic EBS
eksctl create iamserviceaccount --name ebs-csi-controller-sa --namespace kube-system --cluster "$CLUSTER_NAME" \
  --role-name AmazonEKS_EBS_CSI_DriverRole --role-only \
  --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy --approve
ARN=$(aws iam get-role --role-name AmazonEKS_EBS_CSI_DriverRole --query 'Role.Arn' --output text)
eksctl create addon --cluster "$CLUSTER_NAME" --name aws-ebs-csi-driver --version latest \
  --service-account-role-arn $ARN --force

# Add Helm repositories
echo "Adds and updates EKS helm repository..."
helm repo add eks https://aws.github.io/eks-charts
helm repo add argo-cd https://argoproj.github.io/argo-helm
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Install AWS Load Balancer Controller using Helm
helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system \
  --set clusterName="$CLUSTER_NAME" --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller --set region="$REGION" \
  --set vpcId="$VPC_ID" --set image.repository="$ECR_REPO"

echo "Waiting for AWS Load Balancer Controller pods to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/aws-load-balancer-controller -n kube-system

# Get the public subnets in the VPC
SUBNETS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=*public*" --query "Subnets[*].SubnetId" --output text)
# Create a comma-separated list of subnets
SUBNETS_CSV=$(echo $SUBNETS | tr ' ' ',')  # Convert tabs to commas
# Path to the Ingress YAML file
INGRESS_YAML_FILE="./Helm/nginx/nginx-ingress.yaml"
# Replace public_subnet_a,public_subnet_b with actual subnets in the Ingress YAML
sed -i "s|public_subnet_a,public_subnet_b|$SUBNETS_CSV|g" "$INGRESS_YAML_FILE"
# Confirm the replacement
echo "Updated Ingress YAML with subnets: $SUBNETS_CSV"

# Get the EXRERNAL DNS ROLE ARN
EXTERNAL_DNS_ROLE=$(eksctl get iamserviceaccount --cluster carmel-yoram-eks-cluster | grep external-dns | awk '{print $3}')
# Path to the Ingress YAML file
DNS_YAML_FILE="./Helm/external-DNS.yaml"
# Replace public_subnet_a,public_subnet_b with actual subnets in the Ingress YAML
sed -i "s|DNS-ROLE|$EXTERNAL_DNS_ROLE|g" "$DNS_YAML_FILE"
# Confirm the replacement
echo "Updated Ingress YAML with subnets: $EXTERNAL_DNS_ROLE"

echo "$SUBNETS_CSV"
echo "$EXTERNAL_DNS_ROLE"

############### Monitoring - Setup ###############

# Define variables for Monitoring
NAMESPACE="monitoring"
NODE_SELECTOR="monitoring-group"  # Replace with your actual node label

# Create monitoring namespace
echo "Creating namespace '$NAMESPACE'..."
kubectl create namespace "$NAMESPACE"

# Install Prometheus Kube Prometheus Stack with node selector
echo "Installing Prometheus Kube Prometheus Stack in namespace '$NAMESPACE'..."
helm install monitoring prometheus-community/kube-prometheus-stack \
  -f ./Helm/values/prometheus-values.yaml -n "$NAMESPACE"

# Wait for pods to be ready
echo "Waiting for pods to be ready in namespace '$NAMESPACE'..."
kubectl wait --for=condition=available --timeout=300s deployment/kube-prometheus-stack -n "$NAMESPACE"

echo "Installation completed."

############### Logging ###############

NAMESPACE="logging"

eksctl create iamserviceaccount --name ebs-csi-controller-sa --namespace kube-system --cluster "$CLUSTER_NAME" \
  --role-name AmazonEKS_EBS_CSI_DriverRole --role-only \
  --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy --approve

ARN=$(aws iam get-role --role-name AmazonEKS_EBS_CSI_DriverRole --query 'Role.Arn' --output text)

eksctl create addon --cluster "$CLUSTER_NAME" --name aws-ebs-csi-driver --version latest \
  --service-account-role-arn $ARN --force

kubectl create namespace logging

helm install elasticsearch --set replicas=2 --set volumeClaimTemplate.storageClassName=gp2 \
--set persistence.labels.enabled=true elastic/elasticsearch -n logging  -f ./Helm/values/elastic-values.yaml -n "$NAMESPACE"

# Wait for pods to be ready
echo "Waiting for pods to be ready in namespace '$NAMESPACE'..."
kubectl wait --for=condition=available --timeout=300s deployment/elasticsearch -n "$NAMESPACE"
echo "Installation completed."

helm install kibana elastic/kibana -n logging --set server.service.type=NodePort

# argoCD installation - ingress handle ssl and https
kubectl create namespace argocd
helm install argocd argo/argo-cd -n argocd --set server.insecure=true --set server.protocol=http --set server.service.type=NodePort
