# 🚀 vLLM on AWS EC2 - Terraform Infrastructure

> Terraform configuration to provision a complete VPC, networking, and GPU EC2 Spot instance for running **vLLM** inference servers.

This module deploys a production-ready (yet lab-oriented) AWS environment optimized for GPU workloads like vLLM.

---

## ✨ Overview

The Terraform code in this directory provisions:

- A custom VPC with public and private subnets across multiple Availability Zones
- Internet Gateway + NAT Gateway for outbound connectivity
- Route tables and associations
- A **g4ad.xlarge** GPU Spot instance (AMD GPU) with public IP
- A permissive security group (lab-only)
- S3 backend + DynamoDB locking for Terraform state
- Outputs for easy SSH access and resource references

Designed to complement the manual vLLM setup documented in the root [README.md](../README.md).

## 📋 Prerequisites

- Terraform >= 1.14.8 (pinned in `terraform.tf`)
- AWS CLI configured with credentials
- An existing SSH key pair named `ff-ec2-key` (or update the `key_name` in `main.tf`)
- Sufficient AWS quota for g4ad instances and Spot capacity in `eu-central-1`
- Basic understanding of Terraform workflows

## 🛠️ Files

| File                    | Description |
|-------------------------|-----------|
| `terraform.tf`          | Terraform settings, providers, and remote backend resources (S3 + DynamoDB) |
| `variables.tf`          | Input variables (region, VPC CIDR, etc.) |
| `main.tf`               | Core resources: VPC, subnets, IGW, NAT, route tables, EC2 instance |
| `security-groups.tf`    | Security group (lab: allow-all inbound) |
| `outputs.tf`            | Useful outputs including SSH command |

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

   Use the SSH command from the outputs:

   ```bash
   terraform output test_gpu_ec2_public_ip
   ```

   Or copy the full command shown.

## 🔧 Customization

### Change Instance Type

Edit `main.tf`:

```hcl
instance_type = "g5.xlarge"   # or g4dn.xlarge, g6, etc.
```

### Use Private Subnet (Recommended for Production)

Move the EC2 into a private subnet and add a bastion or use Systems Manager Session Manager.

### Tighten Security Group

Replace the allow-all SG with specific ports (22, 8000, etc.) and trusted CIDRs.

### Spot vs On-Demand

Adjust `instance_market_options` as needed.

### AMI

Current AMI is hardcoded (`ami-066684246476b7b50`). Update to the latest Amazon Linux or Deep Learning Base AMI for your region.

## 🧰 Post-Deployment

After the instance launches:

1. Follow the **Installation** and **Run vLLM as a Service** sections in the root [README.md](../README.md).
2. Install NVIDIA drivers / CUDA if not using a Deep Learning AMI.
3. Set up vLLM, systemd service, and CloudWatch agent.

## ⚠️ Important Notes & Warnings

- **Security**: The security group allows **all inbound traffic** — suitable only for labs / short-lived testing. Do **not** use in production.
- **Spot Instance**: Can be interrupted. Use `instance_interruption_behavior = "terminate"`.
- **Costs**: GPU instances are expensive. Monitor with CloudWatch.
- **Region**: Hardcoded to `eu-central-1`. Update variables as needed.
- **Key Pair**: Ensure `ff-ec2-key` exists in the region.

## 📁 Project Structure (Terraform)

```
terraform/
├── main.tf
├── variables.tf
├── outputs.tf
├── security-groups.tf
├── terraform.tf
└── mystate/                  # Local state directory (gitignored)
```

## 🔗 Related

- [Root README](../README.md) — vLLM installation, systemd, CloudWatch, troubleshooting
- [AWS Documentation](https://docs.aws.amazon.com/) — EC2, VPC, Spot Instances

---

**Built with ❤️ for fast LLM inference on AWS GPUs.**

*GPU says: "Spot me once, shame on you. Spot me twice..."* 🧠
