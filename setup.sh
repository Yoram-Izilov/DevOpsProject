#!/bin/bash

# Define variables
REGION="us-east-1"
CLUSTER_NAME="carmel-yoram-eks-cluster"

# Get the VPC ID of the EKS cluster
VPC_ID=$(aws eks describe-cluster --name "$CLUSTER_NAME" --query "cluster.resourcesVpcConfig.vpcId" --output text)

# Check if VPC_ID is not empty
if [ -z "$VPC_ID" ]; then
    echo "Error: Unable to retrieve VPC ID for cluster $CLUSTER_NAME."
    exit 1
fi

ECR_REPO="602401143452.dkr.ecr.us-east-1.amazonaws.com/amazon/aws-load-balancer-controller"
AWS_LOAD_BALANCER_POLICY="arn:aws:iam::992382545251:policy/AWSLoadBalancerControllerIAMPolicy"
EXTERNAL_DNS_POLICY="arn:aws:iam::992382545251:policy/AllowExternalDNSUpdates"

# Update kubeconfig
aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER_NAME"

# Associate IAM OIDC provider
eksctl utils associate-iam-oidc-provider --region "$REGION" --cluster "$CLUSTER_NAME" --approve

# Create IAM service account for AWS Load Balancer Controller
eksctl create iamserviceaccount --cluster="$CLUSTER_NAME" --namespace=kube-system \
  --name=aws-load-balancer-controller --attach-policy-arn="$AWS_LOAD_BALANCER_POLICY" \
  --override-existing-serviceaccounts --approve

# Add EKS Helm repository and update
helm repo add eks https://aws.github.io/eks-charts
helm repo update

# Install AWS Load Balancer Controller using Helm
helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system \
  --set clusterName="$CLUSTER_NAME" --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller --set region="$REGION" \
  --set vpcId="$VPC_ID" --set image.repository="$ECR_REPO"

# Create IAM service account for External DNS
eksctl create iamserviceaccount --name external-dns --namespace default \
  --cluster "$CLUSTER_NAME" --attach-policy-arn="$EXTERNAL_DNS_POLICY" \
  --approve --override-existing-serviceaccounts

# Get IAM service account details
eksctl get iamserviceaccount --cluster "$CLUSTER_NAME"

# Define variables for Monitoring 
NAMESPACE="monitoring"
NODE_SELECTOR="monitoring-group"  # Replace with your actual node label

# Add Helm repositories
echo "Adding Helm repositories..."
helm repo add stable https://charts.helm.sh/stable
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

# Update Helm repositories
echo "Updating Helm repositories..."
helm repo update

# Create monitoring namespace
echo "Creating namespace '$NAMESPACE'..."
kubectl create namespace "$NAMESPACE"

# Install Prometheus Kube Prometheus Stack with node selector
echo "Installing Prometheus Kube Prometheus Stack in namespace '$NAMESPACE'..."
helm install monitoring prometheus-community/kube-prometheus-stack -n "$NAMESPACE" \
  --set defaultRules.prometheus.enabled=false \
  --set prometheus.prometheusSpec.nodeSelector."$NODE_SELECTOR"="true" \
  --set alertmanager.alertmanagerSpec.nodeSelector."$NODE_SELECTOR"="true" \
  --set grafana.nodeSelector."$NODE_SELECTOR"="true"

# Wait for pods to be ready
echo "Waiting for pods to be ready in namespace '$NAMESPACE'..."
kubectl wait --for=condition=available --timeout=600s deployment/kube-prometheus-stack -n "$NAMESPACE"

echo "Installation completed."


############### DEPLOYMENT ###############

# Get the public subnets in the VPC
SUBNETS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=*public*" --query "Subnets[*].SubnetId" --output text)

# Create a comma-separated list of subnets
SUBNETS_CSV=$(echo $SUBNETS | tr '\t' ',')  # Convert tabs to commas

# Path to the Ingress YAML file
INGRESS_YAML_FILE="./Helm/app-yamls/nginx-ingress.yaml"

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

echo "Applying yamls..."
kubectl apply -f ./Helm/ingressclass-resource.yaml
kubectl apply -f $DNS_YAML_FILE
kubectl apply -f ./Helm/app-yamls/

