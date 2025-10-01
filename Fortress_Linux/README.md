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