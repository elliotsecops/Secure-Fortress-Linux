# Fortress Linux - System Security Hardening Framework

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Ansible](https://img.shields.io/badge/Ansible-9.0%2B-blue.svg)](https://www.ansible.com/)
[![Linux](https://img.shields.io/badge/Linux-Ubuntu%2022.04%2B%7CDebian%2012%2B-orange.svg)](https://www.linux.org/)
[![Python](https://img.shields.io/badge/Python-3.8%2B-blue.svg)](https://www.python.org/)

Fortress Linux is a comprehensive security hardening framework designed to enhance the security posture of Linux systems through automated hardening scripts and Ansible playbooks. This project provides both manual and automated approaches to system hardening, with integrated monitoring capabilities and robust error handling.

## 🆕 What's New (2024 Update)

### 🚀 Critical Improvements
- **Enhanced Error Handling**: Comprehensive logging and error recovery in bash scripts
- **Backup & Restore**: Full system backup and restore functionality
- **Modern Dependencies**: Updated to latest secure versions (Ansible 9.0+, Python 3.8+)
- **Ubuntu 24.04 & Debian 12 Support**: Full compatibility with latest LTS releases
- **Improved Security**: Enhanced password policies (14-char minimum), SSH hardening, and audit rules

### 🔧 Technical Enhancements
- **Idempotent Scripts**: Safe to run multiple times
- **Pre-flight Checks**: System compatibility verification before execution
- **Rollback Capability**: One-click restore from backup
- **Comprehensive Logging**: Detailed audit trail of all changes
- **Validation Steps**: Post-hardening verification of security settings

## 🎯 Features

### Security Hardening
- **System Updates**: Automated system package updates and security patches
- **Firewall Configuration**: UFW (Uncomplicated Firewall) setup with rate limiting
- **Service Hardening**: Disables unnecessary and potentially vulnerable services
- **Password Policy**: Enforces strong password requirements (minimum 14 characters, 4 character classes)
- **SSH Security**: Disables root login, password authentication, adds security banners
- **File Permissions**: Secures sensitive system files and removes world-writable permissions

### Monitoring & Detection
- **File Integrity Monitoring**: Real-time monitoring of critical system files
- **Audit Logging**: Comprehensive system audit trail with auditd
- **Rootkit Detection**: Built-in rootkit scanning capabilities
- **Log Collection**: Centralized log monitoring and analysis
- **Intrusion Detection**: Integration with Wazuh SIEM platform

### Backup & Recovery
- **Full System Backup**: Comprehensive backup of configurations, users, packages
- **Incremental Backups**: Support for compressed and configuration-only backups
- **One-Click Restore**: Simple restore functionality with verification
- **Backup Verification**: Integrity checks for all backup archives
- **Automated Cleanup**: Configurable retention policies for old backups

### Automation
- **Ansible Playbooks**: Automated deployment and configuration management
- **Enhanced Bash Scripts**: Manual hardening with error handling and logging
- **Template-based Configuration**: Jinja2 templates for flexible configuration
- **Compatibility Testing**: Pre-deployment system verification
- **Rollback Automation**: Automatic backup creation before changes

## 📋 Prerequisites

### System Requirements
- **Operating System**: Ubuntu 22.04+ or Debian 12+ (tested on Ubuntu 24.04 LTS)
- **Architecture**: x86_64 or ARM64
- **Memory**: Minimum 2GB RAM (4GB+ recommended)
- **Storage**: Minimum 10GB free disk space
- **Network**: Internet connection for package installation

### Software Dependencies
- **Bash**: Version 4.0+
- **Ansible**: Version 9.0+ (for automated deployment)
- **Python**: Version 3.8+ (Ansible dependency)
- **Systemd**: Required for service management
- **Wazuh Agent**: Version 4.0+ (optional, for SIEM integration)

### User Requirements
- **Root Access**: Administrative privileges required for system modifications
- **SSH Access**: Working SSH connection for remote deployment
- **Backup**: System backup recommended before hardening (automatically created)

## 💻 Minimal Systems Installation

### Overview
Fortress Linux supports minimal system installations with resource constraints. This section provides optimized installation procedures for systems with limited memory, storage, or processing power.

### Minimal System Requirements
- **Operating System**: Ubuntu 22.04+ or Debian 12+ (minimal/server variants)
- **Architecture**: x86_64 or ARM64
- **Memory**: Minimum 512MB RAM (1GB+ recommended)
- **Storage**: Minimum 2GB free disk space (5GB+ recommended)
- **Network**: Internet connection for package installation (can be offline after installation)

### Lightweight Installation Options

#### Option 1: Core Hardening Only
```bash
# 1. Run compatibility check
./scripts/system_check.sh

# 2. Install minimal dependencies only
sudo apt update
sudo apt install -y --no-install-recommends \
    bash \
    ufw \
    auditd \
    systemd \
    coreutils

# 3. Run core hardening without backup
sudo ./scripts/linux_hardening.sh --minimal
```

#### Option 2: Minimal with Backup
```bash
# 1. Create compressed backup (minimal)
sudo ./scripts/backup_restore.sh backup --compress --config-only

# 2. Run lightweight hardening
sudo ./scripts/linux_hardening.sh --minimal --backup-skip

# 3. Verify critical services only
sudo systemctl status auditd sshd ufw
```

#### Option 3: Ansible Minimal Mode
```bash
# 1. Install minimal Ansible
sudo apt update
sudo apt install -y --no-install-recommends python3 python3-pip
pip3 install --no-cache-dir ansible-core

# 2. Run minimal playbook
ansible-playbook -i ansible/inventory/hosts \
    ansible/playbooks/minimal_hardening.yml \
    --skip-tags "monitoring,backup,logging"
```

### Resource Optimization Settings

#### Memory-Constrained Systems
```bash
# Create minimal configuration
cat > /tmp/fortress-minimal.conf << 'EOF'
# Minimal Fortress Linux Configuration
ENABLE_BACKUP=false
ENABLE_COMPRESSION=false
ENABLE_MONITORING=false
ENABLE_LOG_ROTATION=false
MAX_MEMORY_USAGE=256
SKIP_SERVICES="bluetooth,cups,avahi,rtkit"
EOF

# Apply minimal configuration
sudo ./scripts/linux_hardening.sh --config /tmp/fortress-minimal.conf
```

#### Storage-Constrained Systems
```bash
# Minimal backup with compression
sudo ./scripts/backup_restore.sh backup \
    --compress \
    --config-only \
    --max-size 100M

# Run hardening without backup creation
sudo ./scripts/linux_hardening.sh \
    --minimal \
    --backup-skip \
    --log-level error
```

#### Network-Constrained Systems
```bash
# Pre-download packages (offline installation)
sudo apt update
sudo apt install -d -y ufw auditd ssh

# Run hardening without network calls
sudo ./scripts/linux_hardening.sh \
    --minimal \
    --offline \
    --skip-updates
```

### Minimal Configuration Files

#### Lightweight SSH Configuration
```bash
# Create minimal SSH config for resource-constrained systems
sudo tee /etc/ssh/sshd_config.minimal << 'EOF'
# Minimal SSH Hardening
Port 22
Protocol 2
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
MaxAuthTries 3
ClientAliveInterval 300
MaxSessions 2
EOF
```

#### Minimal Firewall Rules
```bash
# Essential firewall rules only
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw --force enable
```

#### Minimal Audit Configuration
```bash
# Critical audit rules only
sudo tee /etc/audit/rules.d/minimal.rules << 'EOF'
# Essential audit rules for minimal systems
-w /etc/passwd -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/sudoers -p wa -k sudoers
-w /var/log/auth.log -p wa -k logins
-w /bin/sudo -p x -k sudo_commands
EOF

sudo systemctl restart auditd
```

### Performance Monitoring for Minimal Systems

#### Memory Usage Check
```bash
# Monitor memory usage during hardening
watch -n 1 'free -h; echo "---"; ps aux --sort=-%mem | head -10'
```

#### Disk Usage Check
```bash
# Monitor disk usage during operations
watch -n 1 'df -h / /var/log /tmp; echo "---"; du -sh /etc/fortress-backups/'
```

### Troubleshooting Minimal Systems

#### Common Issues and Solutions

**Issue: Out of Memory Errors**
```bash
# Check available memory
free -h

# Create swap file if needed
sudo fallocate -l 1G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Run hardening with reduced parallelism
sudo ./scripts/linux_hardening.sh --minimal --threads 1
```

**Issue: Disk Space Constraints**
```bash
# Check disk usage
df -h

# Clean package cache
sudo apt clean
sudo apt autoremove -y

# Remove old backups (keep only latest)
sudo ./scripts/backup_restore.sh clean 1

# Run with minimal logging
sudo ./scripts/linux_hardening.sh --minimal --log-level error
```

**Issue: Slow Performance**
```bash
# Run with reduced I/O priority
sudo ionice -c 3 ./scripts/linux_hardening.sh --minimal

# Disable unnecessary services first
sudo systemctl disable bluetooth cups avahi-daemon
sudo systemctl stop bluetooth cups avahi-daemon

# Run in single-user mode if needed
sudo systemctl isolate rescue
```

**Issue: Network Constraints**
```bash
# Use local package cache
sudo apt-get -o Acquire::Retries=3 update

# Skip package updates
sudo ./scripts/linux_hardening.sh --minimal --skip-updates

# Download packages for offline installation
sudo apt-get download ufw auditd ssh
```

### Minimal System Verification

#### Quick Health Check
```bash
# Verify critical services only
systemctl is-active auditd sshd ufw

# Check essential security settings
sudo ufw status
sudo sshd -T | grep -E "permitrootlogin|passwordauthentication"
sudo auditctl -l | head -5

# Verify minimal disk usage
df -h / /var/log /tmp
```

#### Resource Usage Report
```bash
# Generate minimal system report
{
    echo "=== Minimal System Status ==="
    echo "Memory Usage: $(free -h | grep Mem)"
    echo "Disk Usage: $(df -h / | tail -1)"
    echo "Active Services: $(systemctl list-units --type=service --state=running | wc -l)"
    echo "Security Services: $(systemctl is-active auditd sshd ufw 2>/dev/null | grep -c active)"
    echo "Backup Size: $(du -sh /etc/fortress-backups/ 2>/dev/null || echo 'No backups')"
} > /tmp/minimal-system-report.txt

cat /tmp/minimal-system-report.txt
```

### Minimal System Maintenance

#### Automated Cleanup
```bash
# Create minimal cleanup script
cat > /usr/local/bin/fortress-minimal-cleanup.sh << 'EOF'
#!/bin/bash
# Minimal system cleanup for Fortress Linux

# Clean package cache
sudo apt clean 2>/dev/null

# Rotate logs (keep last 2 days)
sudo find /var/log -name "*.log" -mtime +2 -delete 2>/dev/null

# Clean old backups (keep only latest)
sudo find /etc/fortress-backups -maxdepth 1 -type d ! -name "fortress-backups" | \
    sort -r | tail -n +2 | xargs -r sudo rm -rf

# Monitor disk usage
df -h / | tail -1 | awk '{print $5}' | sed 's/%//' | \
    awk '{if($1 > 90) print "WARNING: Disk usage above 90%"}'
EOF

sudo chmod +x /usr/local/bin/fortress-minimal-cleanup.sh

# Add to cron (weekly cleanup)
echo "0 2 * * 0 /usr/local/bin/fortress-minimal-cleanup.sh" | \
    sudo crontab -
```

#### Performance Optimization
```bash
# Optimize for minimal systems
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
echo 'vm.dirty_ratio=15' | sudo tee -a /etc/sysctl.conf
echo 'vm.dirty_background_ratio=5' | sudo tee -a /etc/sysctl.conf

# Apply sysctl changes
sudo sysctl -p
```

### Recovery Procedures for Minimal Systems

#### Emergency Restore
```bash
# Quick restore from latest backup
sudo ./scripts/backup_restore.sh restore $(ls -1t /etc/fortress-backups/ | head -1)

# Reset to minimal configuration
sudo ./scripts/linux_hardening.sh --reset --minimal
```

#### Manual Recovery
```bash
# If automated restore fails, manual recovery steps:
sudo systemctl restart auditd
sudo ufw --force enable
sudo systemctl restart sshd

# Verify basic security
sudo ufw status
sudo systemctl status auditd sshd
```

## 🚀 Quick Start

### Option 1: Compatibility Check (Recommended First)
```bash
# Verify system compatibility
./scripts/system_check.sh

# Or run comprehensive compatibility tests
./scripts/compatibility_test.sh
```

### Option 2: Safe Installation with Backup
```bash
# 1. Clone the repository
git clone https://github.com/your-username/fortress-linux.git
cd fortress-linux

# 2. Create a backup first
sudo ./scripts/backup_restore.sh backup --compress

# 3. Run system compatibility check
./scripts/system_check.sh

# 4. Execute hardening
sudo ./scripts/linux_hardening.sh
```

### Option 3: Traditional Manual Installation
```bash
# 1. Clone and prepare
git clone https://github.com/your-username/fortress-linux.git
cd fortress-linux
chmod +x scripts/linux_hardening.sh

# 2. Run hardening script
sudo ./scripts/linux_hardening.sh

# 3. Monitor progress
tail -f /var/log/fortress-hardening.log
```

### Option 4: Automated Installation (Ansible)
```bash
# 1. Install dependencies
sudo apt update
sudo apt install python3-pip python3-venv -y
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
ansible-galaxy collection install -r requirements.yml

# 2. Configure inventory
cp ansible/inventory/hosts.example ansible/inventory/hosts
nano ansible/inventory/hosts  # Add your target systems

# 3. Run Ansible playbook
ansible-playbook -i ansible/inventory/hosts ansible/playbooks/playbook_hardening.yml
```

## 📊 Enhanced Scripts

### System Hardening Script (`scripts/linux_hardening.sh`)
- **Error Handling**: Comprehensive error catching and logging
- **Pre-flight Checks**: System requirements validation
- **Automatic Backup**: Creates backup before making changes
- **Verification**: Post-hardening validation of security settings
- **Rollback Support**: One-command restore capability

### Backup & Restore Utility (`scripts/backup_restore.sh`)
```bash
# Create full backup
sudo ./scripts/backup_restore.sh backup --compress

# Create configuration-only backup
sudo ./scripts/backup_restore.sh backup --config-only

# List available backups
./scripts/backup_restore.sh list

# Restore from backup
sudo ./scripts/backup_restore.sh restore 20241201_143022

# Verify backup integrity
./scripts/backup_restore.sh verify 20241201_143022

# Clean old backups (older than 30 days)
sudo ./scripts/backup_restore.sh clean 30
```

### Compatibility Testing (`scripts/compatibility_test.sh`)
```bash
# Run full compatibility test
./scripts/compatibility_test.sh

# Quick system check
./scripts/system_check.sh
```

## ⚙️ Configuration

### Enhanced Logging
- **Main Log**: `/var/log/fortress-hardening.log`
- **Backup Log**: `/var/log/fortress-backup-restore.log`
- **Compatibility Log**: `/tmp/fortress-compatibility-test.log`

### Backup Locations
- **Backup Directory**: `/etc/fortress-backups/`
- **Format**: `YYYYMMDD_HHMMSS` (timestamped directories)
- **Compression**: Optional `.tar.gz` archives

### Security Configuration Updates

#### Password Policies (Enhanced)
```bash
# Updated settings in /etc/security/pwquality.conf
minlen = 14           # Increased from 12
minclass = 4
maxrepeat = 3
dcredit = -1
ucredit = -1
lcredit = -1
ocredit = -1
difok = 3
```

#### SSH Security (Enhanced)
```bash
# Additional security settings
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
X11Forwarding no
AllowTcpForwarding no
Banner /etc/ssh/banner
```

#### Firewall Rules (Enhanced)
```bash
# Rate limiting and logging
ufw logging medium
ufw limit ssh/tcp    # Rate limit SSH attempts
```

## 🛡️ Security Features

### Implemented Hardening Measures
- **Network Security**: Enhanced firewall configuration with rate limiting
- **Access Control**: Strengthened password policies and SSH security
- **File Security**: Comprehensive permission hardening and integrity monitoring
- **Service Security**: Unnecessary service disablement and monitoring
- **Monitoring**: Enhanced audit logging and intrusion detection
- **Patch Management**: Automated security updates with validation

### New Security Enhancements
- **Password Complexity**: 14-character minimum with character class requirements
- **SSH Hardening**: Connection timeouts, failed attempt limits, security banners
- **Audit Rules**: Comprehensive system call and file access monitoring
- **File Permissions**: Automatic removal of world-writable permissions
- **Service Isolation**: Disabled non-essential services for reduced attack surface

## 📈 Monitoring and Verification

### Real-time Monitoring
```bash
# Monitor hardening progress
tail -f /var/log/fortress-hardening.log

# Check system status after hardening
sudo ufw status verbose
sudo systemctl status auditd
sudo systemctl status sshd
```

### Verification Commands
```bash
# Verify firewall rules
sudo ufw status verbose

# Verify SSH configuration
sudo sshd -T | grep -E "permitrootlogin|passwordauthentication"

# Verify auditd rules
sudo auditctl -l

# Check password policy
grep minlen /etc/security/pwquality.conf
```

### System Health Check
```bash
# Run post-hardening verification
./scripts/system_check.sh

# Verify all security settings
sudo ./scripts/linux_hardening.sh verify  # If implemented
```

## 🔍 Troubleshooting

### Common Issues and Solutions

#### Pre-flight Check Failures
```bash
# Check system compatibility
./scripts/system_check.sh

# Verify dependencies
which python3 ansible systemctl ufw
```

#### Permission Denied Errors
```bash
# Ensure running as root
sudo ./scripts/linux_hardening.sh

# Check script permissions
ls -la scripts/linux_hardening.sh
```

#### SSH Connection Issues
```bash
# Test SSH configuration
sudo sshd -t

# Check SSH service status
sudo systemctl status sshd

# Verify firewall allows SSH
sudo ufw status
```

#### Backup Issues
```bash
# Check backup directory
ls -la /etc/fortress-backups/

# Verify backup integrity
./scripts/backup_restore.sh verify <backup_id>

# Check available disk space
df -h
```

### Recovery Procedures
```bash
# Restore from backup (if something goes wrong)
sudo ./scripts/backup_restore.sh restore <backup_id>

# Check logs for errors
tail -100 /var/log/fortress-hardening.log

# Manual configuration verification
sudo ufw status
sudo systemctl status auditd sshd
```

## 🧪 Testing

### Pre-deployment Testing
```bash
# System compatibility test
./scripts/compatibility_test.sh

# Syntax check scripts
bash -n scripts/linux_hardening.sh
bash -n scripts/backup_restore.sh

# Verify Ansible playbooks
ansible-playbook --syntax-check ansible/playbooks/playbook_hardening.yml
```

### Post-deployment Verification
```bash
# System health check
./scripts/system_check.sh

# Security verification
sudo ufw status verbose
sudo systemctl status auditd sshd
sudo sshd -T
```

## 📚 Documentation

### Updated Documentation Structure
- `README.md` - This file - Main documentation
- `docs/DEPLOYMENT.md` - Detailed deployment guide
- `docs/SECURITY.md` - Security configuration reference
- `CHANGELOG.md` - Version history and changes

### Script Documentation
- `scripts/linux_hardening.sh` - Main hardening script
- `scripts/backup_restore.sh` - Backup and restore utility
- `scripts/compatibility_test.sh` - System compatibility testing
- `scripts/system_check.sh` - Quick system verification

## 🤝 Contributing

### Development Workflow
1. Fork the repository
2. Create feature branch: `git checkout -b feature/new-feature`
3. Test changes with `./scripts/compatibility_test.sh`
4. Submit pull request with detailed description
5. Code review and testing

### Testing Requirements
- **Compatibility Testing**: Must pass on Ubuntu 22.04+ and Debian 12+
- **Error Handling**: Scripts must handle errors gracefully
- **Logging**: Comprehensive logging for all operations
- **Backup**: All operations must be reversible

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙋‍♂️ Support

### Getting Help
- **Documentation**: Read this README and inline code comments
- **Issues**: Create GitHub issue with detailed description
- **Compatibility**: Run `./scripts/system_check.sh` first
- **Logs**: Check `/var/log/fortress-hardening.log` for errors

### Emergency Recovery
If hardening causes issues:
```bash
# Immediately restore from backup
sudo ./scripts/backup_restore.sh restore <latest_backup>

# Or use restore function in hardening script
sudo ./scripts/linux_hardening.sh restore <backup_directory>
```

## 🎯 Roadmap

### Completed (2024 Update)
- ✅ Enhanced error handling and logging
- ✅ Comprehensive backup and restore functionality
- ✅ Updated dependencies to latest secure versions
- ✅ Ubuntu 22.04+ and Debian 12+ compatibility
- ✅ Pre-flight system validation
- ✅ Post-hardening verification

### Future Enhancements
- [ ] Web-based management interface
- [ ] Multi-system orchestration
- [ ] Compliance reporting dashboard
- [ ] Automated backup scheduling
- [ ] Container security hardening
- [ ] Cloud platform integration

### Version History
- **v2.0.0** - Major update with enhanced security and reliability
- **v1.2.0** - Added Wazuh integration and monitoring
- **v1.1.0** - Enhanced Ansible automation
- **v1.0.0** - Initial release with basic hardening

---

**⚠️ Important**: Always test hardening procedures in a development environment before production deployment. The enhanced scripts automatically create backups, but save your backup directory location for emergency recovery.

**🔒 Security First**: This tool follows defensive security best practices and includes comprehensive error handling, logging, and rollback capabilities to ensure safe system hardening.

**Made with ❤️ for Linux Security** - Enhanced 2024 Edition