# Redis Elasticache
resource "aws_elasticache_subnet_group" "redis_subnet" {
  name       = "yoram-carmel-redis-subnet-group"
  subnet_ids = [aws_subnet.private_a1.id, aws_subnet.private_a2.id, aws_subnet.private_b.id]
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "yoram-carmel-redis-cluster"
  engine               = "redis"
  node_type            = "cache.t2.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  subnet_group_name    = aws_elasticache_subnet_group.redis_subnet.name
  security_group_ids   = [aws_security_group.redis_sg.id]

  tags = {
    Project = "TeamD"
  }
}