#!/bin/bash

# Define variables
REGION="us-east-1"
CLUSTER_NAME="carmel-yoram-eks-cluster"

aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER_NAME"

kubectl delete -f ./Helm/app-yamls/
kubectl delete -f ./Helm/external-DNS.yaml
kubectl delete -f ./Helm/ingressclass-resource.yaml

helm uninstall monitoring prometheus-community/kube-prometheus-stack -n monitoring
helm uninstall aws-load-balancer-controller -n kube-system

eksctl delete iamserviceaccount external-dns --cluster carmel-yoram-eks-cluster
eksctl delete iamserviceaccount aws-load-balancer-controller --cluster carmel-yoram-eks-cluster