output "VPC-name" {
  value = local.env_name
}

output "Region" {
  value = var.aws_region
}

output "Cidr" {
  value = var.vpc_cidr
}

output "example-vpc-private-1" {
  value = "${local.env_name}-private-1"
}

output "example-vpc-private-2" {
  value = "${local.env_name}-private-2"
}

output "example-vpc-public-1" {
  value = "${local.env_name}-public-1"
}

# Optional: Output the values so you can easily copy them into your backend config
output "s3-bucket-name" {
  value       = aws_s3_bucket.terraform_state.bucket
  description = "S3 Bucket name to use in backend configuration"
}

output "dynamodb-table-name" {
  value       = aws_dynamodb_table.terraform_lock.name
  description = "DynamoDB Table name to use for state locking"
}

output "test_gpu_ec2_public_ip" {
  value       = "ssh -i C:/Users/Tom/OneDrive/data/aws-lab/aws-keys/ff-ec2-key.pem ec2-user@${aws_instance.test_gpu_ec2.public_ip}"
  description = "Dynamic public IPv4 address of the GPU Spot instance"

}

output "check_cloudwatch_agent" {
  value       = "Check CloudWatch installation - systemctl status amazon-cloudwatch-agent"
  description = "Manual verification step for CloudWatch agent"
}
