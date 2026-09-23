#!/bin/bash
set -euo pipefail          # removed -x for cleaner logs (optional)

# Simple, reliable logging that works under cloud-init
exec >> /var/log/user-data.log 2>&1
echo "=== user-data started at $(date -Is) ==="
# cloudwatch log - /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log

CONFIG_PATH="/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json"
AGENT_CTL="/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl"
PROMETHEUS_CONFIG_PATH="/opt/aws/amazon-cloudwatch-agent/etc/prometheus.yaml"

dnf install -y amazon-cloudwatch-agent

cat > "$CONFIG_PATH" <<'EOF'
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
  },
    "logs": {
    "metrics_collected": {
      "prometheus": {
        "log_group_name": "/aws/ec2/vllm-metrics",
        "prometheus_config_path": "/opt/aws/amazon-cloudwatch-agent/etc/prometheus.yaml",
        "emf_processor": {
          "metric_namespace": "vLLM/Inference"
        }
      }
    }
  }
}
EOF

cat > "$PROMETHEUS_CONFIG_PATH" <<'EOF'
global:
  scrape_interval: 60s
  scrape_timeout: 50s

scrape_configs:
  - job_name: 'vllm'
    metrics_path: '/metrics'
    static_configs:
      - targets: ['127.0.0.1:8000']
    
    # Filter metrics after scraping, keeping only specified metrics
    metric_relabel_configs:
      - source_labels: [__name__]
        regex: '^(vllm:num_requests_running|vllm:kv_cache_usage_perc|vllm:prefix_cache_queries|vllm:prefix_cache_hits|vllm:prompt_tokens_total|vllm:generation_tokens_total)$'
        action: keep
EOF



"$AGENT_CTL" \
  -a fetch-config \
  -m ec2 \
  -c "file:$CONFIG_PATH" \
  -s

systemctl enable amazon-cloudwatch-agent
systemctl restart amazon-cloudwatch-agent

#sudo cloud-init status --long
#sudo cat /var/log/cloud-init-output.log
#sudo cat /var/log/user-data.log
#sudo journalctl -u cloud-final -b --no-pager

echo "=== vLLM installation ==="

dnf install -y \
  python3.13 python3.13-pip python3.13-devel \
  git gcc gcc-c++
mkdir -p /home/ec2-user/vllm /home/ec2-user/tmp /home/ec2-user/.cache/pip
chown -R ec2-user:ec2-user /home/ec2-user/vllm /home/ec2-user/tmp /home/ec2-user/.cache
# Install vLLM as ec2-user (not root)
sudo -u ec2-user bash -lc '
  set -euo pipefail
  cd /home/ec2-user/vllm
  python3.13 -m venv .venv
  source .venv/bin/activate
  python -m pip install --upgrade pip
  export TMPDIR=/home/ec2-user/tmp
  export PIP_CACHE_DIR=/home/ec2-user/.cache/pip
  pip install vllm
  pip uninstall -y torchcodec || true
  vllm --help >/dev/null
  python -c "import torch; print(\"cuda:\", torch.cuda.is_available())"
  python -c "import vllm; print(\"vllm:\", vllm.__version__)"
'