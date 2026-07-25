resource "aws_observabilityadmin_telemetry_enrichment" "resource_tags_telemetry" {
  region = "eu-central-1"
}

resource "aws_cloudwatch_dashboard" "test_gpu_ec2" {
  dashboard_name = "CloudWatch-Dashboard-4-test-gpu-ec2-resource"

  dashboard_body = file("${path.module}/test_gpu_ec2.json")
}