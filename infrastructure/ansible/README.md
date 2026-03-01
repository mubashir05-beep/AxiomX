# Ansible Playbook for AxiomX Infrastructure

This directory contains Ansible playbooks for setting up and managing the AxiomX trading engine infrastructure.

## Contents

- `site.yml` - Main playbook for infrastructure setup
- `hosts` - Inventory file (update with your EC2 instances)

## Prerequisites

```bash
# Install Ansible
pip install ansible

# Install AWS collection
ansible-galaxy collection install amazon.aws

# Generate SSH key for AWS instances
ssh-keygen -f ~/.ssh/axiomx-key -N ""
```

## Usage

### 1. Update Inventory

Edit `hosts` file with your EC2 instance IPs and hostnames:

```ini
[all]
trading-engine-1 ansible_host=10.0.1.100 ansible_user=ec2-user
trading-engine-2 ansible_host=10.0.2.100 ansible_user=ec2-user
trading-engine-3 ansible_host=10.0.3.100 ansible_user=ec2-user
```

### 2. Test Connectivity

```bash
ansible all -i hosts -m ping
```

### 3. Run Playbook

```bash
# Run entire playbook
ansible-playbook -i hosts site.yml

# Run specific tags
ansible-playbook -i hosts site.yml --tags docker
ansible-playbook -i hosts site.yml --tags kubernetes
ansible-playbook -i hosts site.yml --tags monitoring
```

## What Gets Installed

- **Docker** - Container runtime
- **Kubernetes** - kubectl command-line tool
- **Helm** - Kubernetes package manager
- **Terraform** - Infrastructure as code
- **Promtail** - Log collection agent for Grafana Loki
- **CloudWatch Agent** - AWS CloudWatch metrics/logs
- **Node Exporter** - Prometheus metrics exporter
- **AWS CLI** - Amazon Web Services command-line interface

## Security Considerations

- Use Ansible Vault for sensitive variables:
  ```bash
  ansible-vault create secrets.yml
  ```

- Use SSH keys (not passwords):
  ```bash
  -i ~/.ssh/axiomx-key
  ```

- Use IAM roles for AWS API calls (no credentials in code)

## Troubleshooting

### SSH Connection Failed

```bash
# Test SSH directly
ssh -i ~/.ssh/axiomx-key ec2-user@<instance-ip>

# Check security group allows SSH (port 22)
aws ec2 describe-security-groups --region us-east-1
```

### Playbook Hangs

```bash
# Run with verbose output
ansible-playbook -i hosts site.yml -vvv

# Run with timeout
ansible-playbook -i hosts site.yml --timeout=60
```

### Docker Daemon Not Running

```bash
# Manually start on instance
ssh -i key.pem ec2-user@<ip>
sudo systemctl restart docker
```

## Next Steps

1. Run the Terraform playbook to provision infrastructure
2. Deploy Kubernetes manifests using kubectl
3. Monitor with Prometheus and Grafana
4. Use CloudWatch for centralized logging

