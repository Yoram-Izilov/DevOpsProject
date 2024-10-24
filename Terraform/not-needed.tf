
# IAM Role for AWS Load Balancer Controller
# data "http" "aws_lb_controller_iam_policy" {
#   url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json"
# }

# resource "aws_iam_policy" "aws_load_balancer_controller_policy" {
#   name        = "AWSLoadBalancerControllerIAMPolicy"
#   description = "IAM Policy for AWS Load Balancer Controller"
#   policy      = data.http.aws_lb_controller_iam_policy.response_body
# }


# data "tls_certificate" "eks" {
#   url = aws_eks_cluster.eks.identity[0].oidc[0].issuer
# }

# resource "aws_iam_openid_connect_provider" "cluster" {
#   client_id_list  = ["sts.amazonaws.com"]
#   thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
#   url             = aws_eks_cluster.eks.identity[0].oidc[0].issuer
# }

# resource "aws_iam_role" "eks_service_account_role" {
#   name = "eks-service-account-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect = "Allow",
#         Principal = {
#           Federated = aws_iam_openid_connect_provider.cluster.arn
#         },
#         Action = "sts:AssumeRoleWithWebIdentity",
#         Condition = {
#           StringEquals = {
#             "${aws_iam_openid_connect_provider.cluster.url}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
#             "${aws_iam_openid_connect_provider.cluster.url}:aud" = "sts.amazonaws.com"
#           }
#         }
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller_attachment" {
#   policy_arn = aws_iam_policy.aws_load_balancer_controller_policy.arn
#   role       = aws_iam_role.eks_service_account_role.name
# }

# IAM Role for External DNS
# resource "aws_iam_role" "external_dns_role" {
#   name = "carmel_yoram_external_dns_role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Action = "sts:AssumeRoleWithWebIdentity"
#       Effect = "Allow"
#       Principal = {
#         Service = "eks.amazonaws.com"
#       }
#       Condition = {
#         StringEquals = {
#           "eks.amazonaws.com:sub" = "system:serviceaccount:default:external-dns"
#         }
#       }
#     }]
#   })
# }

# resource "aws_iam_role_policy_attachment" "external_dns_policy_attachment" {
#   policy_arn = "arn:aws:iam::992382545251:policy/AllowExternalDNSUpdates" # Use the existing ARN
#   role       = aws_iam_role.external_dns_role.name
# }

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