resource "aws_eks_cluster" "eks" {
  name     = "carmel-yoram-eks-cluster"
  version  = "1.30"
  role_arn = aws_iam_role.eks_clsuter_role.arn

  vpc_config {
    endpoint_private_access = false
    endpoint_public_access  = true

    subnet_ids = [
      aws_subnet.private_a1.id,
      aws_subnet.private_a2.id,
      aws_subnet.private_b.id
    ]

    security_group_ids = [
      aws_security_group.eks_sg.id
    ]
  }

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }

  depends_on = [aws_iam_role_policy_attachment.eks]
}


resource "null_resource" "update_kubeconfig" {
  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --region us-east-1 --name ${aws_eks_cluster.eks.name}"
  }

  depends_on = [aws_eks_cluster.eks]
}

# Here to make sure eks creation happened
provider "kubernetes" {
  config_path = "~/.kube/config"
}

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
