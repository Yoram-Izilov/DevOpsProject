# NGINX and WSGI node group
resource "aws_eks_node_group" "app" {
  cluster_name = aws_eks_cluster.eks.name
  version      = "1.30"

  node_group_name = "app-group"
  node_role_arn   = aws_iam_role.node_group_role.arn

  subnet_ids = [
    aws_subnet.private_a1.id,
    aws_subnet.private_b.id
  ]

  instance_types = ["t2.medium"]

  scaling_config {
    desired_size = 2
    min_size     = 2
    max_size     = 2
  }

  update_config {
    max_unavailable = 1
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [scaling_config[0].desired_size]
  }

  depends_on = [
    aws_eks_cluster.eks,
    aws_iam_role_policy_attachment.eks_node_role_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_ecr_policy
  ]
}

# for Grafana, Prometheus, and maybe Jenkins(?)
resource "aws_eks_node_group" "monitoring" {
  cluster_name = aws_eks_cluster.eks.name
  version      = "1.30"

  node_group_name = "monitoring-group"
  node_role_arn   = aws_iam_role.node_group_role.arn

  subnet_ids = [
    aws_subnet.private_a2.id
  ]

  instance_types = ["t2.medium"]

  scaling_config {
    desired_size = 2
    min_size     = 2
    max_size     = 2
  }

  update_config {
    max_unavailable = 1
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [scaling_config[0].desired_size]
  }

  depends_on = [
    aws_eks_cluster.eks,
    aws_iam_role_policy_attachment.eks_node_role_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_ecr_policy
  ]
}