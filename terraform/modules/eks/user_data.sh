#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh ${cluster_name}
/opt/aws/bin/cfn-signal --exit-code $? --stack  --resource NodeGroup --region 

# Install additional monitoring tools
yum update -y
yum install -y amazon-cloudwatch-agent

# Configure CloudWatch agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << EOF
{
    "metrics": {
        "namespace": "CWAgent",
        "metrics_collected": {
            "cpu": {
                "measurement": [
                    "cpu_usage_idle",
                    "cpu_usage_iowait",
                    "cpu_usage_user",
                    "cpu_usage_system"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ],
                "totalcpu": false
            },
            "disk": {
                "measurement": [
                    "used_percent"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "diskio": {
                "measurement": [
                    "io_time"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "mem": {
                "measurement": [
                    "mem_used_percent"
                ],
                "metrics_collection_interval": 60
            },
            "netstat": {
                "measurement": [
                    "tcp_established",
                    "tcp_time_wait"
                ],
                "metrics_collection_interval": 60
            },
            "swap": {
                "measurement": [
                    "swap_used_percent"
                ],
                "metrics_collection_interval": 60
            }
        }
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/messages",
                        "log_group_name": "/aws/ec2/eks-node/${node_group_name}",
                        "log_stream_name": "{instance_id}-messages"
                    },
                    {
                        "file_path": "/var/log/kubelet/kubelet.log",
                        "log_group_name": "/aws/ec2/eks-node/${node_group_name}",
                        "log_stream_name": "{instance_id}-kubelet"
                    }
                ]
            }
        }
    }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

# Install and configure node exporter for Prometheus monitoring
useradd --no-create-home --shell /bin/false node_exporter
cd /tmp
curl -LO https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz
tar xvf node_exporter-1.6.1.linux-amd64.tar.gz
cp node_exporter-1.6.1.linux-amd64/node_exporter /usr/local/bin/
chown node_exporter:node_exporter /usr/local/bin/node_exporter

# Create systemd service for node exporter
cat > /etc/systemd/system/node_exporter.service << EOF
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable node_exporter
systemctl start node_exporter

# Configure log rotation
cat > /etc/logrotate.d/kubernetes << EOF
/var/log/containers/*.log {
    daily
    missingok
    rotate 7
    compress
    notifempty
    create 0644 root root
}
EOF

# Set up cost optimization script
cat > /usr/local/bin/cost-optimizer.sh << 'EOF'
#!/bin/bash
# Cost optimization script for EKS nodes

# Check if it's off-hours (weekends or after 6 PM)
current_hour=$(date +%H)
current_day=$(date +%u)

if [[ $current_day -gt 5 ]] || [[ $current_hour -gt 18 ]] || [[ $current_hour -lt 8 ]]; then
    # Scale down non-essential pods
    kubectl scale deployment --replicas=1 -l tier=backend -n default 2>/dev/null || true
    kubectl scale deployment --replicas=0 -l tier=batch -n default 2>/dev/null || true
else
    # Scale up for business hours
    kubectl scale deployment --replicas=3 -l tier=backend -n default 2>/dev/null || true
    kubectl scale deployment --replicas=2 -l tier=batch -n default 2>/dev/null || true
fi
EOF

chmod +x /usr/local/bin/cost-optimizer.sh

# Add cron job for cost optimization
echo "0 */2 * * * /usr/local/bin/cost-optimizer.sh" | crontab -

# Configure kernel parameters for better performance
echo 'net.core.rmem_max = 134217728' >> /etc/sysctl.conf
echo 'net.core.wmem_max = 134217728' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_rmem = 4096 65536 134217728' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_wmem = 4096 65536 134217728' >> /etc/sysctl.conf
echo 'net.core.netdev_max_backlog = 5000' >> /etc/sysctl.conf
sysctl -p

# Signal completion
/opt/aws/bin/cfn-signal --exit-code $? --stack  --resource ${node_group_name} --region
