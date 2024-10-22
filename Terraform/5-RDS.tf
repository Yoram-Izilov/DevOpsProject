resource "aws_db_subnet_group" "rds_subnet" {
  name       = "carmel-yoram-rds-subnet-group"
  subnet_ids = [aws_subnet.private_a1.id, aws_subnet.private_a2.id, aws_subnet.private_b.id]
}

# yoram-carmel-postgres-db  
resource "aws_db_instance" "rds" {
  identifier = "yoram-carmel-postgres-db"

  engine            = "postgres"
  engine_version    = "16.3"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp3"

  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet.name
  publicly_accessible    = false

  snapshot_identifier = "carmel-yoram-final-snapshot"
  skip_final_snapshot = true

  tags = {
    Project = "TeamD"
  }

  lifecycle {
    ignore_changes = [identifier]
  }

}
