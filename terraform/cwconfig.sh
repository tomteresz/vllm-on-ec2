#!/usr/bin/env bash
set -euo pipefail

CONFIG_PATH="/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json"
AGENT_CTL="/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl"

echo "Installing Amazon CloudWatch Agent..."
sudo dnf install -y amazon-cloudwatch-agent

echo "Writing CloudWatch Agent config..."
sudo tee "$CONFIG_PATH" >/dev/null <<'EOF'
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

echo "Starting CloudWatch Agent with config..."
sudo "$AGENT_CTL" \
  -a fetch-config \
  -m ec2 \
  -c "file:$CONFIG_PATH" \
  -s

echo "Agent status:"
sudo "$AGENT_CTL" -m ec2 -a status || true

echo "Systemd status:"
sudo systemctl status amazon-cloudwatch-agent --no-pager || true

echo "Prod restart."
sudo systemctl restart amazon-cloudwatch-agent

echo "Done."

# sudo journalctl -u amazon-cloudwatch-agent