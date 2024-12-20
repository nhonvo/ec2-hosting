provider "aws" {
  region = "us-east-1" # Update to your preferred region
}

# Key Pair for EC2
resource "aws_key_pair" "webapi_key" {
  key_name   = "webapi-key"
  public_key = file("~/.ssh/id_rsa.pub") # Replace with your actual public key file
}

# Security Group
resource "aws_security_group" "webapi_sg" {
  name        = "webapi-sg"
  description = "Allow HTTP, HTTPS, and SSH access"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Restrict this to your IP for SSH
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
}

# EC2 Instance
resource "aws_instance" "webapi_instance" {
  ami           = "ami-0c02fb55956c7d316" # Amazon Linux 2 AMI
  instance_type = "t2.micro"

  key_name      = aws_key_pair.webapi_key.key_name
  security_groups = [aws_security_group.webapi_sg.name]

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    amazon-linux-extras enable dotnet7
    yum install -y dotnet-sdk-7.0 nginx
    systemctl start nginx
    systemctl enable nginx
  EOF

  tags = {
    Name = "WebAPI-Demo"
  }
}

# Elastic IP for EC2
resource "aws_eip" "webapi_eip" {
  instance = aws_instance.webapi_instance.id
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "webapi_cf" {
  origin {
    domain_name = aws_eip.webapi_eip.public_ip
    origin_id   = "webapi-origin"

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_protocol_policy   = "http-only"
      origin_ssl_protocols     = ["TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "webapi-origin"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name = "WebAPI-Demo-CloudFront"
  }
}
