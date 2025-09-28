# Fortress Linux - Deployment Guide

This guide provides detailed instructions for deploying Fortress Linux across different environments and configurations.

## 📋 Prerequisites

### System Requirements
- **Operating System**: Ubuntu 18.04+ or Debian 9+
- **Architecture**: x86_64 or ARM64
- **Memory**: Minimum 2GB RAM
- **Storage**: Minimum 10GB free disk space
- **Network**: Internet connection for package installation

### Software Requirements
- **Ansible**: Version 2.9+ (for automated deployment)
- **Python**: Version 3.6+
- **SSH**: Key-based authentication configured
- **Git**: For repository cloning

### Access Requirements
- **Root Access**: Administrative privileges on target systems
- **SSH Access**: Working SSH connection to target systems
- **Backup**: System backup recommended before deployment

## 🚀 Deployment Methods

### Method 1: Automated Ansible Deployment

#### 1. Setup Control Machine
```bash
# Install Ansible
sudo apt update
sudo apt install ansible python3-pip -y

# Install required collections
ansible-galaxy collection install -r requirements.yml

# Install Python dependencies
pip3 install -r requirements.txt
```

#### 2. Configure Inventory
```bash
# Edit inventory file
nano ansible/inventory/hosts

# Example configuration:
[webservers]
server1 ansible_user=admin ansible_host=192.168.1.10
server2 ansible_user=admin ansible_host=192.168.1.11
```

#### 3. Configure Variables
```bash
# Edit global variables
nano ansible/group_vars/all/main.yml

# Set Wazuh manager IP
wazuh_manager_ip: "192.168.1.100"

# Configure security level
security_level: "high"
```

#### 4. Run Deployment
```bash
# Test connectivity
ansible -i ansible/inventory/hosts all -m ping

# Run hardening playbook
ansible-playbook -i ansible/inventory/hosts ansible/playbooks/playbook_hardening.yml

# Run with specific tags
ansible-playbook -i ansible/inventory/hosts ansible/playbooks/playbook_hardening.yml --tags "firewall,ssh"
```

### Method 2: Manual Bash Script Deployment

#### 1. Clone Repository
```bash
git clone https://github.com/your-username/fortress-linux.git
cd fortress-linux
```

#### 2. Make Script Executable
```bash
chmod +x scripts/linux_hardening.sh
```

#### 3. Run Hardening Script
```bash
# Test script syntax first
bash -n scripts/linux_hardening.sh

# Execute hardening
sudo ./scripts/linux_hardening.sh
```

### Method 3: Containerized Deployment

#### 1. Build Container
```bash
# Create Dockerfile
cat > Dockerfile << EOF
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y ansible python3
COPY . /fortress-linux
WORKDIR /fortress-linux
CMD ["ansible-playbook", "-i", "ansible/inventory/hosts", "ansible/playbooks/playbook_hardening.yml"]
EOF

# Build image
docker build -t fortress-linux .
```

#### 2. Run Container
```bash
docker run -it fortress-linux
```

## 🌍 Environment-Specific Deployments

### Development Environment
```bash
# Development-specific inventory
[development]
dev-server ansible_user=dev ansible_host=192.168.1.100

# Development variables
[development:vars]
security_level: "medium"
auto_updates_enabled: false
backup_enabled: false
```

### Testing Environment
```bash
# Testing-specific inventory
[testing]
test-server ansible_user=test ansible_host=192.168.1.200

# Testing variables
[testing:vars]
security_level: "high"
auto_updates_enabled: true
backup_enabled: true
environment: "testing"
```

### Production Environment
```bash
# Production-specific inventory
[production]
prod-server ansible_user=admin ansible_host=192.168.1.10

# Production variables
[production:vars]
security_level: "critical"
auto_updates_enabled: true
backup_enabled: true
monitoring_enabled: true
```

## 🔧 Configuration Management

### Variable Hierarchy
Ansible variables are loaded in this order:
1. Command line values (-e)
2. Role defaults
3. Inventory file variables
4. Inventory group variables
5. Inventory host variables
6. Play group variables
7. Play host variables

### Custom Configuration Files
```bash
# Create custom group variables
ansible/group_vars/webservers/security.yml
ansible/group_vars/databases/security.yml

# Create custom host variables
ansible/host_vars/server1/custom_config.yml
```

## 📊 Monitoring and Logging

### Deployment Monitoring
```bash
# Check deployment status
ansible-playbook --list-hosts -i ansible/inventory/hosts ansible/playbooks/playbook_hardening.yml

# Monitor deployment logs
tail -f logs/deployment.log

# Check system status after deployment
ansible -i ansible/inventory/hosts all -m command -a "systemctl status"
```

### Post-Deployment Verification
```bash
# Verify firewall rules
ansible -i ansible/inventory/hosts all -m command -a "ufw status"

# Check SSH configuration
ansible -i ansible/inventory/hosts all -m command -a "sshd -T | grep -E 'permitrootlogin|passwordauthentication'"

# Verify Wazuh agent
ansible -i ansible/inventory/hosts all -m command -a "systemctl status wazuh-agent"
```

## 🔄 Rollback Procedures

### Method 1: Ansible Rollback
```bash
# Create backup before deployment
ansible-playbook -i ansible/inventory/hosts ansible/playbooks/backup.yml

# Restore from backup
ansible-playbook -i ansible/inventory/hosts ansible/playbooks/restore.yml
```

### Method 2: System Restore
```bash
# Using Timeshift (if available)
sudo timeshift --restore

# Manual configuration restore
sudo cp /etc/backup/sshd_config /etc/ssh/sshd_config
sudo systemctl restart sshd
```

## 🚨 Troubleshooting

### Common Issues

#### SSH Connection Problems
```bash
# Test SSH connectivity
ssh -i ~/.ssh/id_rsa admin@server-ip

# Check Ansible SSH settings
ansible -i ansible/inventory/hosts all -m ping -vvv
```

#### Permission Issues
```bash
# Verify sudo access
ansible -i ansible/inventory/hosts all -m command -a "whoami" --become

# Check privilege escalation
ansible-playbook --check -i ansible/inventory/hosts ansible/playbooks/playbook_hardening.yml
```

#### Package Installation Failures
```bash
# Update package cache
ansible -i ansible/inventory/hosts all -m apt -a "update_cache=yes"

# Fix broken packages
ansible -i ansible/inventory/hosts all -m command -a "apt --fix-broken install"
```

### Debug Commands
```bash
# Dry run (check mode)
ansible-playbook --check -i ansible/inventory/hosts ansible/playbooks/playbook_hardening.yml

# Verbose output
ansible-playbook -vvv -i ansible/inventory/hosts ansible/playbooks/playbook_hardening.yml

# Step-by-step execution
ansible-playbook --step -i ansible/inventory/hosts ansible/playbooks/playbook_hardening.yml
```

## 📈 Scaling Deployment

### Large-Scale Deployments
```bash
# Increase parallel execution
ansible-playbook -f 50 -i ansible/inventory/hosts ansible/playbooks/playbook_hardening.yml

# Use asynchronous tasks
ansible-playbook -i ansible/inventory/hosts ansible/playbooks/playbook_hardening.yml --async
```

### Multi-Environment Management
```bash
# Environment-specific playbooks
ansible-playbook -i environments/dev/inventory ansible/playbooks/playbook_hardening.yml
ansible-playbook -i environments/prod/inventory ansible/playbooks/playbook_hardening.yml
```

## 🎯 Best Practices

### Pre-Deployment Checklist
- [ ] Test in development environment first
- [ ] Create system backup
- [ ] Verify SSH key-based authentication
- [ ] Check disk space availability
- [ ] Verify network connectivity
- [ ] Review security requirements
- [ ] Plan rollback procedures

### Post-Deployment Checklist
- [ ] Verify all services are running
- [ ] Test SSH access
- [ ] Check firewall rules
- [ ] Verify monitoring systems
- [ ] Test backup procedures
- [ ] Update documentation
- [ ] Notify stakeholders

## 📚 Additional Resources

### Documentation
- [Ansible Documentation](https://docs.ansible.com/)
- [Ubuntu Security Guide](https://ubuntu.com/security)
- [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks/)

### Support
- **Issues**: GitHub issues for bugs and feature requests
- **Discussions**: Community discussions for general questions
- **Security**: security@example.com for security vulnerabilities

---

This deployment guide provides comprehensive instructions for deploying Fortress Linux across various environments and scales.