# 🚀 vLLM on AWS EC2 - Terraform Infrastructure

> Terraform configuration to provision a complete VPC, networking, GPU EC2 infrastructure, bootstrap scripts, and CloudWatch monitoring for running **vLLM** inference servers.

This module deploys a production-ready (yet lab-oriented) AWS environment optimized for GPU workloads like vLLM, while keeping the setup approachable for iterative testing and experimentation.

---

## ✨ Overview

The Terraform code in this directory provisions:

- A custom VPC with public and private subnets across multiple Availability Zones
- Internet Gateway + NAT Gateway for outbound connectivity
- Route tables and associations
- A GPU EC2 instance with bootstrap via `userdata.sh`
- Security groups for instance access
- CloudWatch monitoring resources and agent configuration
- Outputs for easy SSH access and resource references
- Supporting JSON and shell assets used during provisioning

Designed to complement the manual vLLM setup documented in the root [README.md](../README.md).

## 📋 Prerequisites

- Terraform >= 1.14.8 (pinned in `terraform.tf`)
- AWS CLI configured with credentials
- An existing SSH key pair named `ff-ec2-key` (or update the `key_name` in Terraform)
- Sufficient AWS quota for the selected GPU instance type and capacity in your target region
- Basic understanding of Terraform workflows

## 🛠️ Files

| File | Description |
|------|-------------|
| `terraform.tf` | Terraform settings, provider requirements, and backend configuration |
| `variables.tf` | Input variables such as region, networking values, and deployment options |
| `main.tf` | Core infrastructure resources including VPC, subnets, routing, and EC2 instance |
| `security-groups.tf` | Security group definitions controlling inbound and outbound access |
| `monitoring.tf` | CloudWatch-related resources, alarms, or monitoring configuration |
| `outputs.tf` | Useful outputs including instance details and connection helpers |
| `userdata.sh` | EC2 bootstrap script executed at instance launch |
| `cwconfig.sh` | CloudWatch agent setup helper script |
| `test_gpu_ec2.json` | Supporting JSON configuration used by the Terraform/monitoring flow |
| `readme.md` | This documentation for the Terraform deployment |

## 🚀 Deployment

1. **Clone the repository**

   ```bash
   git clone https://github.com/tomteresz/vllm-on-ec2.git
   cd vllm-on-ec2/terraform
   ```

2. **Initialize Terraform**

   ```bash
   terraform init
   ```

3. **Review the plan**

   ```bash
   terraform plan
   ```

4. **Apply**

   ```bash
   terraform apply
   ```

   Confirm with `yes` when prompted.

5. **Access the instance**

   Use the outputs after deployment:

   ```bash
   terraform output
   ```

   Retrieve the public IP or copy the full SSH command shown in the outputs.

## 🔧 Customization

### Change Instance Type

Update the EC2 configuration in `main.tf` to match the GPU family and size you want to test.

```hcl
instance_type = "g5.xlarge"   # example: g5, g4dn, g6, etc.
```

### Adjust Bootstrap Logic

Modify `userdata.sh` when you want to install different drivers, Python packages, vLLM versions, or model startup commands.

### Tighten Security Group

Replace broad inbound rules with specific ports (for example SSH or vLLM API access) and trusted CIDR ranges.

### Monitoring

Use `monitoring.tf`, `cwconfig.sh`, and `test_gpu_ec2.json` to expand CloudWatch metrics, logs, dashboards, or alarm behavior.

### Region and Networking

Adjust variables and subnet layout to match your preferred AWS region, CIDR ranges, and availability requirements.

## 🧰 Post-Deployment

After the instance launches:

1. Follow the **Installation** and **Run vLLM as a Service** sections in the root [README.md](../README.md).
2. Verify the bootstrap completed successfully via cloud-init logs and system logs.
3. Confirm CloudWatch agent configuration if monitoring is enabled.
4. Validate GPU availability, Python environment, and vLLM startup before exposing the service.

## ⚠️ Important Notes & Warnings

- **Security**: Review the security group rules carefully before exposing any public endpoint. Lab defaults are often too permissive for production.
- **Costs**: GPU instances, NAT Gateway, and CloudWatch usage can add noticeable cost. Clean up resources when not in use.
- **Spot Capacity**: If the instance uses Spot, interruptions are possible. Plan for restart or reprovisioning.
- **Region Compatibility**: AMIs, GPU availability, and quotas differ by region. Validate these before `terraform apply`.
- **Bootstrap Scripts**: Changes in AWS AMIs or package repositories can affect `userdata.sh` behavior over time.

## 📁 Project Structure (Terraform)

```text
terraform/
├── cwconfig.sh
├── main.tf
├── monitoring.tf
├── outputs.tf
├── readme.md
├── security-groups.tf
├── terraform.tf
├── test_gpu_ec2.json
├── userdata.sh
└── variables.tf
```

## 🔗 Related

- [Root README](../README.md) — vLLM installation, service setup, monitoring, and troubleshooting
- [AWS Documentation](https://docs.aws.amazon.com/) — EC2, VPC, CloudWatch, and Spot Instances
- [Terraform Documentation](https://developer.hashicorp.com/terraform/docs) — workflow, providers, modules, and state management

---

**Built with ❤️ for fast LLM inference on AWS GPUs.**

*GPU says: "Provision me once, benchmark me twice."* 🧠
