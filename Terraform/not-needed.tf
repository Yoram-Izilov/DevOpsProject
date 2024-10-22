# Here to make sure eks creation happened
# provider "kubernetes" {
#   config_path = "~/.kube/config"
# }

# Create the service account and attach the load balancer controller role
# resource "kubernetes_service_account" "aws_load_balancer_controller" {
#   metadata {
#     name      = "aws-load-balancer-controller"
#     namespace = "kube-system"
#     annotations = {
#       "eks.amazonaws.com/role-arn" = aws_iam_role.eks_service_account_role.arn
#     }
#   }

#   depends_on = [aws_eks_cluster.eks]
# }

# resource "kubernetes_service_account" "external_dns_sa" {
#   metadata {
#     name      = "external-dns"
#     namespace = "default"

#     annotations = {
#       "eks.amazonaws.com/role-arn" = aws_iam_role.external_dns_role.arn
#     }
#   }

#   depends_on = [
#     aws_iam_role_policy_attachment.external_dns_policy_attachment,
#     aws_eks_cluster.eks
#   ]
# }

# Grafana and Kibana node group
# resource "aws_eks_node_group" "monitoring" {
#   cluster_name = aws_eks_cluster.eks.name
#   version      = "1.30"

#   node_group_name = "monitoring-group"
#   node_role_arn   = aws_iam_role.node_group_role.arn

#   subnet_ids = [
#     aws_subnet.private_a2.id
#   ]

#   instance_types = ["t2.medium"]

#   scaling_config {
#     desired_size = 1
#     min_size     = 1
#     max_size     = 1
#   }

#   update_config {
#     max_unavailable = 1
#   }

#   lifecycle {
#     create_before_destroy = true
#     ignore_changes        = [scaling_config[0].desired_size]
#   }

#   depends_on = [
#     aws_eks_cluster.eks,
#     aws_iam_role_policy_attachment.eks_node_role_policy,
#     aws_iam_role_policy_attachment.eks_cni_policy,
#     aws_iam_role_policy_attachment.eks_ecr_policy
#   ]
# }

# # Create a Kubernetes namespace in the EKS cluster
# resource "kubernetes_namespace" "monitoring" {
#   metadata {
#     name = "monitoring"
#   }

#   depends_on = [aws_eks_cluster.eks]
# }