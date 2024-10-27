#  ami-0ccc5636aea2eb2bc - private openVPN ami
# Create Security Group for OpenVPN Instance
resource "aws_security_group" "vpn_ec2_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  ingress {
    from_port   = 943
    to_port     = 943
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  ingress {
    from_port   = 945
    to_port     = 945
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }
  
  ingress {
    from_port   = 1194
    to_port     = 1194
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" 
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "OpenVPN Security Group"
  }
}

# Create OpenVPN EC2 Instance
resource "aws_instance" "openvpn_server" {
  ami                     = "ami-0ccc5636aea2eb2bc"
  instance_type           = "t2.micro"
  subnet_id               = aws_subnet.public_a.id
  vpc_security_group_ids  = [aws_security_group.vpn_ec2_sg.id] 

  tags = {
    Name = "carmel-yoram-vpn"
  }
}

# Create a Network Load Balancer
resource "aws_lb" "openvpn_nlb" {
  name               = "carmel-yoram-openvpn-nlb"
  internal           = false
  load_balancer_type = "network"
  security_groups    = [aws_security_group.vpn_ec2_sg.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  enable_deletion_protection = false

  tags = {
    Name = "OpenVPN NLB"
  }
}

# Create a target group for the NLB
resource "aws_lb_target_group" "openvpn_tg" {
  name     = "carmel-yoram-openvpn-tg"
  port     = 943
  protocol = "TCP"
  vpc_id   = aws_vpc.main.id

  health_check {
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    protocol            = "TCP"
  }
}

# Create a listener for the NLB
resource "aws_lb_listener" "tcp_listener" {
  load_balancer_arn = aws_lb.openvpn_nlb.arn
  port              = 443  
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.openvpn_tg.arn
  }
}

# Register the EC2 instance in the target group
resource "aws_lb_target_group_attachment" "ec2_attachment" {
  target_group_arn = aws_lb_target_group.openvpn_tg.arn
  target_id        = aws_instance.openvpn_server.id
  port             = 943

  lifecycle {
    ignore_changes = [target_id]
  }
}

# Create a DNS record in Route 53
resource "aws_route53_record" "openvpn_dns" {
  zone_id   = "Z0781481D0PZJV31FKX5"
  name      = "vpn.yoram-izilov.com"
  type      = "A"

  alias {
    name                   = aws_lb.openvpn_nlb.dns_name
    zone_id                = aws_lb.openvpn_nlb.zone_id
    evaluate_target_health = true
  }
}