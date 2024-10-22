# IAM Role for EKS
resource "aws_iam_role" "eks_clsuter_role" {
  name = "carmel_yoram_eks_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks" {
  role       = aws_iam_role.eks_clsuter_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Create IAM Role for EKS Node Group
resource "aws_iam_role" "node_group_role" {
  name = "carmel_yoram_node_group_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# Attach policies for the Node Group
resource "aws_iam_role_policy_attachment" "eks_node_role_policy" {
  role       = aws_iam_role.node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_ecr_policy" {
  role       = aws_iam_role.node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

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