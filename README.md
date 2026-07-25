# 🚀 vLLM on AWS EC2 GPU Instances

> A practical, production-oriented setup for serving LLMs with vLLM on NVIDIA GPU EC2 instances such as `g4dn`, `g5`, and similar accelerated instances.

[![Python](https://img.shields.io/badge/Python-3.13+-blue.svg)](https://www.python.org/)
[![AWS](https://img.shields.io/badge/AWS-EC2-orange.svg)](https://aws.amazon.com/ec2/)
[![vLLM](https://img.shields.io/badge/LLM-vLLM-green.svg)](https://docs.vllm.ai/)
[![GPU](https://img.shields.io/badge/GPU-NVIDIA-76B900.svg)](https://www.nvidia.com/)

---

## 🚀 Overview

This guide installs and runs **vLLM** on an AWS EC2 instance with an NVIDIA GPU. vLLM exposes an OpenAI-compatible API, allowing applications to call completion and chat-completion endpoints using familiar API patterns.

It includes:

- NVIDIA GPU validation
- Python virtual environment setup
- vLLM installation
- Small-model and 7B-model tests
- CloudWatch NVIDIA GPU metrics
- A persistent `systemd` service
- Basic troubleshooting and operational checks

## ✨ Key Features

- **GPU-accelerated inference** — Run LLMs on EC2 NVIDIA GPUs
- **OpenAI-compatible API** — Use `/v1/completions` and `/v1/chat/completions` endpoints
- **Small-model validation** — Start with `facebook/opt-125m`
- **Larger-model example** — Run `Qwen/Qwen2.5-7B-Instruct`
- **CloudWatch GPU monitoring** — Collect GPU utilization, VRAM usage, temperature, and power draw 
- **systemd integration** — Start automatically after reboot and restart on failure
- **Simple operational workflow** — Verify with `nvidia-smi`, service status, and logs

## 📋 Prerequisites

- AWS EC2 GPU instance, for example:
  - `g4dn.xlarge` with an NVIDIA T4 GPU
  - `g5.xlarge` with an NVIDIA A10G GPU 
- Amazon Linux 2023 or another `dnf`-based Linux distribution
- NVIDIA driver installed and working
- CUDA-compatible driver environment
- An EC2 IAM role with CloudWatch metric publishing permissions if CloudWatch monitoring is enabled
- Internet access for downloading Python packages and Hugging Face models

> **Recommended:** Use an AWS Deep Learning AMI or another image that already includes compatible NVIDIA drivers and CUDA components.

## 🛠️ Installation

### 1. Verify NVIDIA GPU

Connect to the EC2 instance and verify that the NVIDIA driver can access the GPU.

```bash
nvidia-smi
```

Expected output should show the GPU model, driver version, CUDA version, and active GPU processes.

Example checks:

```bash
nvidia-smi
lspci | grep -i nvidia
```

### 2. Install Python and build dependencies

```bash
sudo dnf install -y \
  python3.13 \
  python3.13-pip \
  python3.13-devel \
  git \
  gcc \
  gcc-c++
```

### 3. Create project directory and virtual environment

```bash
mkdir -p /home/ec2-user/vllm
cd /home/ec2-user/vllm

python3.13 -m venv .venv
source .venv/bin/activate

python -m pip install --upgrade pip
```

### 4. Install vLLM

```bash
source /home/ec2-user/vllm/.venv/bin/activate

pip install vllm
```

Optional workaround if `torchcodec` causes dependency or runtime issues:

```bash
pip uninstall -y torchcodec
```

Confirm the installation:

```bash
vllm --help
python -c "import vllm; print(vllm.__version__)"
```

## ▶️ Run a Test Model

Start with a small model to validate CUDA, PyTorch, vLLM, networking, and API access before loading a larger model.

### Start OPT-125M

```bash
source /home/ec2-user/vllm/.venv/bin/activate

vllm serve facebook/opt-125m \
  --host 127.0.0.1 \
  --port 8000 \
  --dtype float16 \
  --gpu-memory-utilization 0.20 \
  --max-model-len 512
```

vLLM provides an OpenAI-compatible server interface for model inference. 

### Test completions endpoint

Open a second SSH session and run:

```bash
curl -s http://127.0.0.1:8000/v1/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "facebook/opt-125m",
    "prompt": "AWS EC2 is",
    "max_tokens": 30
  }' | python3 -m json.tool
```

Expected result:

```json
{
  "id": "cmpl-...",
  "object": "text_completion",
  "choices": [
    {
      "text": "...",
      "index": 0
    }
  ]
}
```

## 🧠 Run a Larger Model

`Qwen/Qwen2.5-7B-Instruct` is a useful next step for testing instruction-following chat workloads. Ensure your GPU has sufficient VRAM before starting it.

### Start Qwen2.5-7B-Instruct

```bash
source /home/ec2-user/vllm/.venv/bin/activate

vllm serve Qwen/Qwen2.5-7B-Instruct \
  --host 127.0.0.1 \
  --port 8000 \
  --gpu-memory-utilization 0.90
```

### Test chat completions endpoint

```bash
curl -s http://127.0.0.1:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Qwen/Qwen2.5-7B-Instruct",
    "messages": [
      {
        "role": "user",
        "content": "Explain Kubernetes in one sentence."
      }
    ],
    "max_tokens": 100,
    "temperature": 0.2
  }' | python3 -m json.tool
```

## 📊 CloudWatch GPU Monitoring

The Amazon CloudWatch Agent can collect NVIDIA GPU metrics from Linux servers through a `nvidia_gpu` section in its agent configuration. 

### Required IAM permissions

Attach an IAM instance profile that permits CloudWatch metric publishing. At minimum, the instance needs:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "cloudwatch:PutMetricData",
        "ec2:DescribeTags"
      ],
      "Resource": "*"
    }
  ]
}
```

### Install CloudWatch Agent

```bash
sudo dnf install -y amazon-cloudwatch-agent
```

### Create CloudWatch Agent config

```bash
sudo tee /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json >/dev/null <<'EOF'
{
  "agent": {
    "metrics_collection_interval": 60
  },
  "metrics": {
    "namespace": "GPU/vLLM",
    "append_dimensions": {
      "InstanceId": "${aws:InstanceId}",
      "InstanceType": "${aws:InstanceType}"
    },
    "metrics_collected": {
      "nvidia_gpu": {
        "measurement": [
          "utilization_gpu",
          "utilization_memory",
          "memory_total",
          "memory_used",
          "memory_free",
          "temperature_gpu",
          "power_draw"
        ],
        "metrics_collection_interval": 60
      },
      "mem": {
        "measurement": [
          "mem_used_percent",
          "mem_available",
          "mem_used",
          "mem_total"
        ],
        "metrics_collection_interval": 60
      }
    }
  }
}
EOF
```

The CloudWatch agent supports GPU utilization, memory utilization, total/used/free memory, GPU temperature, and power-draw metrics. 

### Start CloudWatch Agent

```bash
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -s
```

### Verify CloudWatch Agent

```bash
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -m ec2 \
  -a status

sudo systemctl status amazon-cloudwatch-agent

sudo tail -f \
  /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log
```

Metrics will be available in the CloudWatch namespace:

```text
GPU/vLLM
```

## ⚙️ Run vLLM as a Service

Running vLLM through `systemd` allows the server to start after reboot and restart automatically if it fails.

### Create systemd unit file

```bash
sudo tee /etc/systemd/system/vllm.service > /dev/null <<'EOF'
[Unit]
Description=vLLM Inference Server
After=network.target
Wants=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/home/ec2-user/vllm

ExecStart=/bin/bash -c 'source /home/ec2-user/vllm/.venv/bin/activate && exec vllm serve facebook/opt-125m \
  --host 0.0.0.0 \
  --port 8000 \
  --dtype float16 \
  --gpu-memory-utilization 0.20 \
  --max-model-len 512'

Restart=always
RestartSec=5
LimitNOFILE=65535

StandardOutput=append:/var/log/vllm.log
StandardError=append:/var/log/vllm.log

[Install]
WantedBy=multi-user.target
EOF
```

### Enable and start

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now vllm.service

sudo systemctl status vllm.service
```

### View logs

```bash
tail -f /var/log/vllm.log
```

### Restart after configuration changes

```bash
sudo systemctl daemon-reload
sudo systemctl restart vllm.service
sudo systemctl status vllm.service
```

## 🔐 Security Notes

- Keep vLLM bound to `127.0.0.1` unless it must be reached remotely.
- Do not expose TCP port `8000` publicly without authentication, TLS, rate limits, and network controls.
- Prefer private subnets, an internal ALB, API Gateway, or a reverse proxy for production access.
- Use a restrictive EC2 security group and allow port `8000` only from trusted sources.
- Consider an IAM role, private Hugging Face access token handling, encrypted EBS volumes, and CloudWatch log retention.

## 🧰 Operational Commands

| Command | Description |
|---|---|
| `nvidia-smi` | Show GPU health, utilization, VRAM usage, and processes |
| `sudo systemctl status vllm.service` | Check vLLM service state |
| `sudo journalctl -u vllm.service -f` | Stream vLLM systemd logs |
| `tail -f /var/log/vllm.log` | Stream vLLM application logs |
| `sudo systemctl restart vllm.service` | Restart the vLLM server |
| `sudo systemctl status amazon-cloudwatch-agent` | Check CloudWatch Agent state |
| `curl http://127.0.0.1:8000/v1/models` | Check vLLM API availability |

## ⚠️ Troubleshooting

### `nvidia-smi` fails

```bash
nvidia-smi
sudo dmesg | grep -i nvidia
lsmod | grep nvidia
```

- Confirm that the instance type has an NVIDIA GPU.
- Confirm that compatible NVIDIA drivers are installed.
- Reboot after installing or upgrading NVIDIA drivers.

### vLLM cannot access GPU

```bash
source /home/ec2-user/vllm/.venv/bin/activate

python -c "import torch; print(torch.cuda.is_available())"
python -c "import torch; print(torch.cuda.get_device_name(0))"
```

Expected output:

```text
True
NVIDIA ...
```

### Out of memory errors

- Lower `--gpu-memory-utilization`, for example from `0.90` to `0.75`.
- Reduce `--max-model-len`.
- Use a smaller model.
- Check current VRAM consumers with:

```bash
nvidia-smi
```

### vLLM service will not start

```bash
sudo systemctl status vllm.service
sudo journalctl -u vllm.service -n 100 --no-pager
tail -n 100 /var/log/vllm.log
```

Common causes include:

- Wrong virtual-environment path
- Insufficient GPU memory
- Incorrect model name
- Missing NVIDIA drivers
- No outbound access to Hugging Face model downloads
- Permission issues writing to `/var/log/vllm.log`

## 📁 Project Structure

```text
.
├── README.md                         # Installation and operational documentation
├── vllm.service                      # Optional systemd unit file
└── amazon-cloudwatch-agent.json      # Optional CloudWatch Agent configuration
```

## 🔧 Customization Ideas

- Replace `facebook/opt-125m` with your preferred Hugging Face model.
- Configure `Qwen/Qwen2.5-7B-Instruct` as the default systemd service model.
- Add a reverse proxy such as NGINX with TLS and authentication.
- Add CloudWatch alarms for GPU temperature, GPU utilization, and VRAM pressure.
- Store Hugging Face model cache on a dedicated gp3 EBS volume.
- Add Prometheus metrics and Grafana dashboards for model-level observability.
- Use Terraform or CloudFormation to provision the instance profile, security group, CloudWatch alarms, and EC2 instance.

## 📝 License

This project is provided as-is for educational, experimental, and internal platform-engineering use.

---

**Built with ❤️, NVIDIA GPUs, and a healthy respect for VRAM limits.**

*GPU says: "Me have memory. Please do not load a 70B model on a T4."* 🧠
