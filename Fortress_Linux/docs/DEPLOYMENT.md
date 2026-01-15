# Deployment Guide

This guide covers deployment options for Fortress Linux across different environments.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Development Environment](#development-environment)
- [Production Deployment](#production-deployment)
- [Multi-environment Deployment](#multi-environment-deployment)
- [Troubleshooting](#troubleshooting)

## Prerequisites

### System Requirements
- **Operating System**: Ubuntu 18.04+ or Debian 10+
- **Architecture**: x86_64 or ARM64
- **Memory**: Minimum 512MB RAM (1GB+ recommended)
- **Storage**: Minimum 2GB free disk space
- **Network**: Internet connection for package installation

### Software Dependencies
```bash
# Install required packages
sudo apt update
sudo apt install -y \
    python3 \
    python3-pip \
    git \
    curl \
    ansible \
    ufw \
    auditd
```

## Quick Start

### Clone Repository
```bash
git clone https://github.com/elliotsecops/Secure-Fortress-Linux.git
cd Secure-Fortress-Linux/Fortress_Linux
```

### Option 1: Bash Script Deployment
```bash
# Make script executable
chmod +x scripts/linux_hardening.sh

# Run with default settings
sudo bash scripts/linux_hardening.sh

# Run with custom options
sudo bash scripts/linux_hardening.sh --minimal --log-level debug
```

### Option 2: Ansible Deployment
```bash
# Install Ansible dependencies
pip3 install -r requirements.txt

# Configure inventory
cp ansible/inventory/development.ini ansible/inventory/custom.ini
nano ansible/inventory/custom.ini  # Edit as needed

# Run playbook
ansible-playbook -i ansible/inventory/custom.ini ansible/playbooks/playbook_hardening.yml
```

## Development Environment

### Setup Development Environment
```bash
# Run the setup script
./scripts/setup-dev-environment.sh

# Install pre-commit hooks
./scripts/setup-precommit.sh

# Verify installation
pre-commit run --all-files
```

### Run Tests
```bash
# Run unit tests
pytest tests/

# Run Molecule tests
cd molecule/default
molecule test

# Run specific platform test
molecule test --platform-name ubuntu-22.04
```

### Development Workflow
```bash
# 1. Create feature branch
git checkout -b feature/new-feature

# 2. Make changes and test
nano ansible/roles/system_hardening/tasks/main.yml
pytest tests/test_system_hardening.py

# 3. Run pre-commit hooks
git add .
git commit -m "Add new feature"

# 4. Push and create PR
git push origin feature/new-feature
```

## Production Deployment

### Production Inventory Setup
```bash
# Copy production template
cp ansible/inventory/production.ini ansible/inventory/production.ini

# Edit inventory with your servers
nano ansible/inventory/production.ini
```

### Production Inventory Example
```ini
[webservers]
web-prod-01 ansible_host=10.0.1.10 ansible_user=admin
web-prod-02 ansible_host=10.0.1.11 ansible_user=admin

[databases]
db-prod-01 ansible_host=10.0.2.10 ansible_user=admin
db-prod-02 ansible_host=10.0.2.11 ansible_user=admin

[production:children]
webservers
databases

[production:vars]
security_level=critical
auto_updates_enabled=true
backup_enabled=true
monitoring_enabled=true
wazuh_manager_ip=10.0.0.100

# Security settings
firewall_enabled=true
auditd_enabled=true
ssh_hardening_enabled=true
fail2ban_enabled=true

# Allowed ports
firewall_allowed_ports:
  - { port: 80, proto: tcp, comment: "HTTP" }
  - { port: 443, proto: tcp, comment: "HTTPS" }
  - { port: 22, proto: tcp, comment: "SSH" }
```

### Pre-flight Checks
```bash
# Run pre-flight validation
ansible-playbook -i ansible/inventory/production.ini \
    ansible/playbooks/preflight_checks.yml
```

### Create Backup
```bash
# Create backup before hardening
ansible-playbook -i ansible/inventory/production.ini \
    ansible/playbooks/backup.yml
```

### Deploy Hardening
```bash
# Execute hardening playbook with UX options
ansible-playbook -i ansible/inventory/production.ini \
    ansible/playbooks/playbook_hardening.yml \
    -e "system_hardening_enabled=true"

# Run with extra variables and verbose output
ansible-playbook -i ansible/inventory/production.ini \
    ansible/playbooks/playbook_hardening.yml \
    -e "system_hardening_enabled=true"
    -e "firewall_enabled=true" \
    -v
```

### Enhanced Bash Script Deployment with UX Options
```bash
# Standard hardening with full UX features
sudo bash scripts/linux_hardening.sh

# With progress tracking and confirmations
sudo bash scripts/linux_hardening.sh --verbose

# Quiet mode for automation (errors only)
sudo bash scripts/linux_hardening.sh --quiet

# Auto-confirm for CI/CD (skip all confirmations)
sudo bash scripts/linux_hardening.sh --yes --quiet

# Dry-run to preview changes
sudo bash scripts/linux_hardening.sh --dry-run

# Debug mode for troubleshooting
sudo bash scripts/linux_hardening.sh --debug

# Minimal mode for resource-constrained systems
sudo bash scripts/linux_hardening.sh --minimal

# Combined options for advanced usage
sudo bash scripts/linux_hardening.sh --yes --verbose --backup-skip
```

### Post-deployment Verification
```bash
# Check firewall status
ansible -i ansible/inventory/production.ini all -m shell -a "sudo ufw status"

# Check SSH configuration
ansible -i ansible/inventory/production.ini all -m shell -a "sudo sshd -T | grep -E 'PermitRootLogin|PasswordAuthentication'"

# Check auditd status
ansible -i ansible/inventory/production.ini all -m shell -a "sudo systemctl status auditd"
```

## Multi-environment Deployment

### Environment Inventory Structure
```bash
ansible/inventory/
├── development.ini    # Development environment
├── testing.ini       # QA/testing environment
├── production.ini    # Production environment
└── minimal.ini       # Resource-constrained systems
```

### Deploy to Multiple Environments
```bash
# Deploy to development
ansible-playbook -i ansible/inventory/development.ini \
    ansible/playbooks/playbook_hardening.yml

# Deploy to testing
ansible-playbook -i ansible/inventory/testing.ini \
    ansible/playbooks/playbook_hardening.yml

# Deploy to production
ansible-playbook -i ansible/inventory/production.ini \
    ansible/playbooks/playbook_hardening.yml
```

### Configuration Management
```bash
# Use ansible.cfg for environment-specific settings
export ANSIBLE_CONFIG=./ansible/ansible.cfg

# Or use different config files
ansible-playbook -i development.ini -e @group_vars/development.yml playbook.yml
ansible-playbook -i production.ini -e @group_vars/production.yml playbook.yml
```

## Troubleshooting

### Common Deployment Issues

#### 1. Permission Denied Errors
```bash
# Ensure running as root or with sudo
ansible-playbook -i inventory.ini playbook.yml --ask-become-pass

# Or use become in inventory
[all:vars]
ansible_become=true
ansible_become_method=sudo
```

#### 2. SSH Connection Issues
```bash
# Test SSH connection
ssh -i ~/.ssh/id_rsa admin@your-server

# Check SSH config
cat ~/.ssh/config

# Use verbose mode
ansible-playbook -i inventory.ini playbook.yml -vvv
```

#### 3. Package Installation Failures
```bash
# Update package cache first
ansible -i inventory.ini all -m apt -a "update_cache=yes"

# Install dependencies manually
ansible -i inventory.ini all -m apt -a "name=python3-pip state=present"
```

#### 4. Molecule Test Failures
```bash
# Check Molecule configuration
cat molecule/default/molecule.yml

# Verify Docker is running
docker ps

# Clean up and retry
molecule destroy
molecule test
```

### Recovery Procedures

#### Rollback from Backup
```bash
# Restore from latest backup
ansible-playbook -i ansible/inventory/custom.ini \
    ansible/playbooks/rollback.yml

# Or restore specific backup
ansible-playbook -i ansible/inventory/custom.ini \
    ansible/playbooks/rollback.yml \
    -e "backup_date=20260110_120000"
```

#### Manual Recovery
```bash
# Restore SSH configuration manually
sudo cp /etc/fortress-backups/latest/sshd_config /etc/ssh/sshd_config
sudo systemctl restart sshd

# Restore firewall manually
sudo cp /etc/fortress-backups/latest/ufw.conf /etc/ufw/ufw.conf
sudo ufw reload

# Restore auditd manually
sudo cp /etc/fortress-backups/latest/auditd.conf /etc/audit/auditd.conf
sudo systemctl restart auditd
```

### Logging and Debugging

#### Check Logs
```bash
# Check hardening log
tail -f /var/log/fortress-hardening.log

# Check Ansible log
tail -f logs/ansible.log

# Check backup log
tail -f /var/log/fortress-backup-restore.log
```

#### Enable Debug Mode
```bash
# Ansible debug mode
ansible-playbook -i inventory.ini playbook.yml -vvv

# Bash script debug mode
sudo bash scripts/linux_hardening.sh --log-level debug

# Molecule debug mode
molecule test --debug
```

## Verification Checklist

### Post-deployment Verification
- [ ] Firewall is active and configured
- [ ] SSH hardening is applied
- [ ] Auditd is running and logging
- [ ] Password policies are enforced
- [ ] Unnecessary services are disabled
- [ ] File permissions are secured
- [ ] Backup was created successfully
- [ ] All services are running

### Security Verification
```bash
# Run comprehensive security check
ansible-playbook -i ansible/inventory/production.ini \
    ansible/playbooks/security_verification.yml

# Or use system check script
./scripts/system_check.sh
```

## Advanced Topics

### Terminal UX Options

Fortress Linux v2.1+ includes enhanced terminal UX for optimal user experience.

#### Verbosity Control
```bash
# Quiet mode (errors only)
sudo bash scripts/linux_hardening.sh --quiet
sudo bash scripts/linux_hardening.sh -q

# Verbose mode (detailed output)
sudo bash scripts/linux_hardening.sh --verbose
sudo bash scripts/linux_hardening.sh -v

# Debug mode (very detailed)
sudo bash scripts/linux_hardening.sh --debug
sudo bash scripts/linux_hardening.sh -vv
```

#### Safety Features
```bash
# Dry-run mode (preview changes without making them)
sudo bash scripts/linux_hardening.sh --dry-run

# Auto-confirm mode (skip all confirmations, use with caution!)
sudo bash scripts/linux_hardening.sh --yes
sudo bash scripts/linux_hardening.sh -y

# Combined for automation
sudo bash scripts/linux_hardening.sh --yes --quiet
```

#### Progress Indicators
The hardening script now provides:
- **Step counters**: Shows current step (e.g., [3/11])
- **Time estimates**: Predicted duration for each operation
- **Progress bars**: Visual progress for multi-item operations
- **Animated spinners**: Real-time feedback for long operations
- **Verification tables**: Compact status summary at completion

#### Testing UX
```bash
# Test all UX functions
./scripts/test_ux.sh

# This validates:
#   ✓ Progress bars rendering
#   ✓ Spinners animating
#   ✓ Step counters displaying
#   ✓ Verification tables formatting
#   ✓ Error messages with fix suggestions
#   ✓ Headers, sections, and dividers
#   ✓ Confirmation system
#   ✓ Dry-run mode
#   ✓ Auto-confirm detection
```

#### Error Recovery
When errors occur, the script provides:
- **Contextual error messages**: Clear description of what failed
- **Fix suggestions**: Commands to resolve common issues
- **Recovery menu**: Options to retry, skip, show details, or abort

Example:
```bash
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
❌ UFW configuration failed

💡 Possible fix:
   sudo ufw --force reset && sudo ufw enable

📄 Log: /var/log/fortress-hardening.log:45
!!!!!!!!!!!!!!!!!!!!!!!!!!!!

Recovery options:
  1) Retry operation
  2) Skip and continue
  3) Show error details
  4) Abort and exit
```

### Rolling Updates
```bash
# Update servers one at a time
ansible-playbook -i ansible/inventory/production.ini \
    ansible/playbooks/playbook_hardening.yml \
    --limit "web-prod-01"

ansible-playbook -i ansible/inventory/production.ini \
    ansible/playbooks/playbook_hardening.yml \
    --limit "web-prod-02"
```

### Custom Variables
```bash
# Create custom variables file
cat > custom_vars.yml << 'EOF'
system_hardening_enabled: true
firewall_enabled: true
ssh_hardening_enabled: true
auditd_enabled: false
custom_firewall_rules:
  - { port: 8443, proto: tcp, comment: "Custom HTTPS" }
EOF

# Use custom variables
ansible-playbook -i inventory.ini playbook.yml -e @custom_vars.yml
```

### Schedule Hardening
```bash
# Add cron job for weekly updates
echo "0 2 * * 0 root ansible-playbook -i /path/to/inventory.ini /path/to/playbook.yml" | sudo tee -a /etc/cron.d/fortress-hardening

# Or use systemd timer
sudo tee /etc/systemd/system/fortress-hardening.timer << 'EOF'
[Unit]
Description=Weekly Fortress Linux hardening

[Timer]
OnCalendar=Sun 02:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

sudo systemctl enable --now fortress-hardening.timer
```

## Support

For additional help:
- Check the [README.md](README.md)
- Review [SECURITY.md](docs/SECURITY.md)
- Open an issue on GitHub
- Check logs in `/var/log/fortress-hardening.log`
