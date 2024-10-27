# Create Security Group for Jenkins Instance
resource "aws_security_group" "jenkins_ec2_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" 
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "EC2 Security Group"
  }
}

# Create jenkins EC2 Instance - ami-014aa519f4166e6ef
resource "aws_instance" "jenkins_server" {
  ami                     = "ami-014aa519f4166e6ef"
  instance_type           = "t3.medium"
  subnet_id               = aws_subnet.private_a1.id
  vpc_security_group_ids  = [aws_security_group.jenkins_ec2_sg.id] 
  key_name = "yoram-key-home" 
  
  tags = {
    Name = "carmel-yoram-jenkins"
  }
}

# Create an Application Load Balancer
resource "aws_lb" "jenkins_alb" {
  name               = "carmel-yoram-jenkins-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.jenkins_ec2_sg.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  enable_deletion_protection = false

  tags = {
    Name = "Jenkins ALB"
  }
}

# Create a target group for the ALB
resource "aws_lb_target_group" "jenkins_tg" {
  name     = "carmel-yoram-jenkins-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/login"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Create a listener for the ALB
resource "aws_lb_listener" "jenkins_https_listener" {
  load_balancer_arn = aws_lb.jenkins_alb.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = "arn:aws:acm:us-east-1:992382545251:certificate/fd6746c6-2e08-4c09-9c9a-702f3ed352ae"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.jenkins_tg.arn
  }
}

# Register the jenkins instance in the target group
resource "aws_lb_target_group_attachment" "jenkins_ec2_attachment" {
  target_group_arn = aws_lb_target_group.jenkins_tg.arn
  target_id        = aws_instance.jenkins_server.id
  port             = 80

  lifecycle {
    ignore_changes = [target_id]
  }
}

# Create a DNS record in Route 53
resource "aws_route53_record" "jenkins_dns" {
  zone_id   = "Z0781481D0PZJV31FKX5"
  name      = "jenkins.yoram-izilov.com"
  type      = "A"

  alias {
    name                   = aws_lb.jenkins_alb.dns_name
    zone_id                = aws_lb.jenkins_alb.zone_id
    evaluate_target_health = true
  }
}