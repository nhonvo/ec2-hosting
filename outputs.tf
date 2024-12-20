output "ec2_public_ip" {
  value = aws_eip.webapi_eip.public_ip
  description = "Public IP of the EC2 instance"
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.webapi_cf.domain_name
  description = "CloudFront distribution domain name"
}
