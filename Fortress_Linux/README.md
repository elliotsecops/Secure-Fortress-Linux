# Fortress Linux - System Security Hardening Framework

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Ansible](https://img.shields.io/badge/Ansible-9.0%2B-blue.svg)](https://www.ansible.com/)
[![Linux](https://img.shields.io/badge/Linux-Ubuntu%2022.04%2B%7CDebian%2012%2B-orange.svg)](https://www.linux.org/)
[![Python](https://img.shields.io/badge/Python-3.8%2B-blue.svg)](https://www.python.org/)

Fortress Linux is a comprehensive security hardening framework designed to enhance security posture of Linux systems through automated hardening scripts and Ansible playbooks. This project provides both manual and automated approaches to system hardening, with integrated monitoring capabilities and robust error handling.

## 🆕 What's New (2026 Updates)

### 🚀 Critical Improvements
- **Code Deduplication**: System hardening tasks reduced by 84% (1847→285 lines)
- **Complete Role Structure**: All roles now have proper defaults, handlers, tasks, and metadata
- **Pre-flight Validation**: System compatibility verification before hardening execution
- **Backup & Restore**: Full backup/restore playbooks with automatic rollback
- **Multi-environment Support**: Development, testing, production, and minimal configurations
- **Pre-commit Hooks**: Automated code quality checks (ShellCheck, Black, Flake8, etc.)
- **Enhanced Molecule**: Support for 6 platforms (Ubuntu 18.04, 20.04, 22.04, Debian 10, 11)

### 🔧 Technical Enhancements
- **Idempotent Scripts**: Safe to run multiple times
- **Variable Validation**: Comprehensive pre-flight checks for all variables
- **Rollback Capability**: One-click restore from backup with playbook
- **Comprehensive Logging**: Detailed audit trail of all changes
- **Template-based Configuration**: Jinja2 templates for flexible configuration
- **Molecule Testing**: Full integration testing with multiple OS versions

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
- **Pre-commit Hooks**: Automated code quality enforcement

### Terminal UX Experience
- **Step-by-Step Progress**: Clear progress indicators (1/12, 2/12, etc.)
- **Time Estimates**: Predicted duration for each operation
- **Progress Bars**: Visual progress for multi-item operations
- **Animated Spinners**: Real-time feedback for long operations
- **Interactive Confirmations**: Safety prompts for destructive changes
- **Enhanced Error Messages**: Contextual errors with fix suggestions
- **Verification Tables**: Compact summary of hardening status
- **Completion Dashboard**: Final summary with system status
- **Smart Verbosity**: Quiet, normal, verbose, and debug modes
- **Dry-run Mode**: Preview changes without making them

## 📋 Prerequisites

### System Requirements
- **Operating System**: Ubuntu 18.04+ or Debian 10+ (tested on Ubuntu 22.04 LTS)
- **Architecture**: x86_64 or ARM64
- **Memory**: Minimum 2GB RAM (4GB+ recommended)
- **Storage**: Minimum 10GB free disk space
- **Network**: Internet connection for package installation

### Software Dependencies
- **Bash**: Version 4.0+
- **Ansible**: Version 2.9+ (for automated deployment)
- **Python**: Version 3.6+ (Ansible dependency)
- **Systemd**: Required for service management
- **Wazuh Agent**: Version 4.0+ (optional, for SIEM integration)

### User Requirements
- **Root Access**: Administrative privileges required for system modifications
- **SSH Access**: Working SSH connection for remote deployment
- **Backup**: System backup recommended before hardening (automatically created)

## 🚀 Quick Start

### Option 1: Compatibility Check (Recommended First)
```bash
# Clone the repository
git clone https://github.com/elliotsecops/Secure-Fortress-Linux.git
cd Secure-Fortress-Linux/Fortress_Linux

# Set up development environment
sudo ./scripts/setup-dev-environment.sh

# Verify system compatibility
./scripts/system_check.sh
```

### Option 2: Bash Script Installation
```bash
# 1. Clone the repository
git clone https://github.com/elliotsecops/Secure-Fortress-Linux.git
cd Secure-Fortress-Linux/Fortress_Linux

# 2. Run hardening script with optimal UX
sudo bash scripts/linux_hardening.sh

# 3. Monitor progress (now with real-time feedback)
# The script provides:
#   • Step-by-step progress with time estimates
#   • Progress bars for multi-item operations
#   • Animated spinners for long operations
#   • Interactive confirmations for dangerous changes
#   • Enhanced error messages with fix suggestions
#   • Verification table showing hardening status
#   • Completion dashboard with summary

# Advanced options:
sudo bash scripts/linux_hardening.sh --verbose     # Detailed output
sudo bash scripts/linux_hardening.sh --quiet       # Errors only
sudo bash scripts/linux_hardening.sh --yes         # Skip confirmations
sudo bash scripts/linux_hardening.sh --dry-run     # Preview changes
```

### Option 3: Ansible Installation
```bash
# 1. Clone the repository
git clone https://github.com/elliotsecops/Secure-Fortress-Linux.git
cd Secure-Fortress-Linux/Fortress_Linux

# 2. Install dependencies
pip3 install -r requirements.txt

# 3. Configure inventory for your environment
cp ansible/inventory/development.ini ansible/inventory/custom.ini
nano ansible/inventory/custom.ini  # Edit as needed

# 4. Run pre-flight checks
ansible-playbook -i ansible/inventory/custom.ini ansible/playbooks/preflight_checks.yml

# 5. Create backup
ansible-playbook -i ansible/inventory/custom.ini ansible/playbooks/backup.yml

# 6. Execute hardening
ansible-playbook -i ansible/inventory/custom.ini ansible/playbooks/playbook_hardening.yml
```

### Option 4: Development Environment Setup
```bash
# 1. Clone the repository
git clone https://github.com/elliotsecops/Secure-Fortress-Linux.git
cd Secure-Fortress-Linux/Fortress_Linux

# 2. Run setup script
./scripts/setup-dev-environment.sh

# 3. Install pre-commit hooks
./scripts/setup-precommit.sh

# 4. Run tests
pytest tests/

# 5. Run Molecule tests
cd molecule/default
molecule test
```

## 💻 Minimal Systems Installation

### Overview
Fortress Linux supports minimal system installations with resource constraints. This section provides optimized installation procedures for systems with limited memory, storage, or processing power.

### Minimal System Requirements
- **Operating System**: Ubuntu 18.04+ or Debian 10+ (minimal/server variants)
- **Architecture**: x86_64 or ARM64
- **Memory**: Minimum 512MB RAM (1GB+ recommended)
- **Storage**: Minimum 2GB free disk space (5GB+ recommended)
- **Network**: Internet connection for package installation (can be offline after installation)

### Minimal Installation Using Inventory
```bash
# Use minimal inventory configuration
ansible-playbook -i ansible/inventory/minimal.ini ansible/playbooks/playbook_hardening.yml
```

### Minimal Hardening Script
```bash
# Run minimal hardening with backup disabled
sudo bash scripts/linux_hardening.sh --minimal --backup-skip

# Minimal with verbose output for debugging
sudo bash scripts/linux_hardening.sh --minimal --verbose

# Verify critical services only
sudo systemctl status auditd sshd ufw
```

### CLI Options Reference
```bash
# Verbosity Control
  --quiet, -q       Minimal output (errors only)
  --verbose, -v      Detailed output
  --debug, -vv       Very detailed with debug info

# Safety & Automation
  --yes, -y          Skip all confirmations (use with caution!)
  --dry-run          Show what would be done without making changes

# Minimal Mode
  --minimal           Enable minimal mode (resource-constrained systems)
  --backup-skip       Skip backup creation
  --skip-updates      Skip system package updates
  --offline           Run in offline mode (no network calls)

# Advanced
  --threads NUM       Set number of parallel threads (default: 4)
  --config FILE       Use custom configuration file
  --help             Show help message

# Commands
  restore <dir>       Restore from backup directory
```

### Minimal Hardening Script
```bash
# Run minimal hardening with backup disabled
sudo bash scripts/linux_hardening.sh --minimal --backup-skip

# Verify critical services only
sudo systemctl status auditd sshd ufw
```

## ⚙️ Configuration

### Available Inventory Examples
- **`ansible/inventory/development.ini`**: Development environment with medium security
- **`ansible/inventory/testing.ini`**: QA/testing with high security and monitoring
- **`ansible/inventory/production.ini`**: Critical security with full hardening
- **`ansible/inventory/minimal.ini`**: Resource-constrained systems

### Ansible Configuration
```bash
# Use the provided ansible.cfg for development
export ANSIBLE_CONFIG=./ansible/ansible.cfg

# Or customize for your environment
nano ansible/ansible.cfg
```

### Pre-commit Configuration
```bash
# Install pre-commit hooks
./scripts/setup-precommit.sh

# Run hooks manually
pre-commit run --all-files

# Update hooks
pre-commit autoupdate
```

### Molecule Testing
```bash
# Run full molecule test suite
cd molecule/default
molecule test

# Run specific tests
molecule verify
molecule converge
molecule idempotence
```

## 📊 Role Structure

### Available Roles
```
ansible/roles/
├── auditd/           # Auditd configuration and rules
├── firewall/         # Firewall (UFW) configuration
├── ssh_hardening/    # SSH hardening and security
└── system_hardening/ # Comprehensive system hardening
    ├── defaults/main.yml      # Default variables
    ├── handlers/main.yml       # Service handlers
    ├── tasks/main.yml         # Main tasks
    ├── templates/              # Jinja2 templates
    └── meta/main.yml          # Role metadata
```

### Available Playbooks
```
ansible/playbooks/
├── playbook_hardening.yml  # Main hardening playbook
├── preflight_checks.yml   # Pre-flight validation
├── backup.yml            # Create system backups
└── rollback.yml          # Restore from backups
```

## 🔍 Troubleshooting

### Pre-flight Check Failures
```bash
# Check system compatibility
./scripts/system_check.sh

# Verify dependencies
which python3 ansible systemctl ufw
```

### Permission Denied Errors
```bash
# Ensure running as root or with sudo
sudo bash scripts/linux_hardening.sh

# Or use Ansible with become
ansible-playbook -i inventory.ini playbook.yml --ask-become-pass
```

### SSH Connection Issues After Hardening
```bash
# If locked out, use rollback playbook
ansible-playbook -i inventory.ini ansible/playbooks/rollback.yml

# Or restore manually from backup
cd /etc/fortress-backups/
sudo cp <backup>/sshd_config /etc/ssh/sshd_config
sudo systemctl restart sshd
```

### Molecule Test Failures
```bash
# Check molecule configuration
cat molecule/default/molecule.yml

# Prepare environment manually
cd molecule/default
molecule create
molecule prepare
molecule converge
```

### Backup Issues
```bash
# Check backup directory
ls -la /etc/fortress-backups/

# Run backup playbook manually
ansible-playbook -i ansible/inventory/production.ini ansible/playbooks/backup.yml

# Verify backup integrity
cat /etc/fortress-backups/latest/MANIFEST.txt
```

### Recovery Procedures
```bash
# Restore from backup (if something goes wrong)
ansible-playbook -i ansible/inventory/custom.ini ansible/playbooks/rollback.yml

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
ansible-lint ansible/playbooks/

# Test UX functions (new!)
./scripts/test_ux.sh
```

### UX Testing
```bash
# Test all terminal UX functions
./scripts/test_ux.sh

# This tests:
#   ✓ Verbosity levels (debug, verbose, info, quiet)
#   ✓ Colored logging
#   ✓ Progress bars
#   ✓ Step counters
#   ✓ Animated spinners
#   ✓ Verification tables
#   ✓ Error messages with fix suggestions
#   ✓ Headers, sections, and dividers
#   ✓ Confirmation system
#   ✓ Dry-run mode
#   ✓ Auto-confirm detection
```
```

### Molecule Integration Testing
```bash
# Run full molecule test
cd molecule/default
molecule test

# Test specific platforms
molecule test --platform-name ubuntu-22.04
molecule test --platform-name debian-11

# Test idempotence
molecule create
molecule converge
molecule idempotence
molecule verify
molecule destroy
```

### Unit Tests
```bash
# Run all tests
pytest tests/

# Run specific test file
pytest tests/test_bash_script.py
pytest tests/test_molecule.py

# Run with coverage
pytest --cov=. tests/
```

## 📚 Documentation

### Documentation Structure
- `README.md` - This file - Main documentation
- `ansible/ansible.cfg` - Ansible configuration
- `ansible/inventory/` - Example inventory files
- `.pre-commit-config.yaml` - Pre-commit hooks configuration

### Script Documentation
- `scripts/linux_hardening.sh` - Main hardening script
- `scripts/backup_restore.sh` - Backup and restore utility
- `scripts/setup-dev-environment.sh` - Development environment setup
- `scripts/setup-precommit.sh` - Pre-commit installation

## 🤝 Contributing

### Development Workflow
1. Fork the repository
2. Create feature branch: `git checkout -b feature/new-feature`
3. Install development environment: `./scripts/setup-dev-environment.sh`
4. Install pre-commit hooks: `./scripts/setup-precommit.sh`
5. Test changes with `pytest tests/` and `molecule test`
6. Submit pull request with detailed description

### Code Quality Requirements
- All pre-commit hooks must pass
- Tests must pass for all supported platforms
- Code must follow project style guides
- All roles must have complete structure (defaults, tasks, handlers, meta, templates)

### Testing Requirements
- **Compatibility Testing**: Must pass on Ubuntu 18.04, 20.04, 22.04 and Debian 10, 11
- **Error Handling**: Scripts must handle errors gracefully
- **Logging**: Comprehensive logging for all operations
- **Backup**: All operations must be reversible

## 📄 License

This project is licensed under MIT License - see the [LICENSE](LICENSE) file for details.

## 🙋 Support

### Getting Help
- **Documentation**: Read this README and inline code comments
- **Issues**: Create GitHub issue with detailed description
- **Compatibility**: Run pre-flight checks before deployment
- **Logs**: Check `/var/log/fortress-hardening.log` for errors

### Emergency Recovery
If hardening causes issues:
```bash
# Immediately restore from backup
ansible-playbook -i ansible/inventory/custom.ini ansible/playbooks/rollback.yml

# Or manually restore
sudo cp /etc/fortress-backups/latest/* /etc/
sudo systemctl restart sshd ufw auditd
```

## 🎯 Roadmap

### Completed (2026 Phase 1-4)
- ✅ Code deduplication (84% reduction in system_hardening)
- ✅ Complete role structure with defaults, handlers, meta
- ✅ Pre-flight variable validation
- ✅ Backup/restore playbooks
- ✅ Pre-commit hooks setup
- ✅ Enhanced Molecule configuration (6 platforms)
- ✅ Development environment setup scripts

### Future Enhancements
- [ ] Multi-distribution support (CentOS, RHEL, Alpine)
- [ ] Cloud platform integration (AWS, Azure, GCP)
- [ ] Compliance reporting dashboard
- [ ] Automated backup scheduling in playbooks
- [ ] Container security hardening
- [ ] Web-based management interface

### Version History
- **v2.0.0** - Major refactoring with complete role structure, pre-commit hooks, and Molecule testing
- **v1.2.0** - Enhanced Ansible automation
- **v1.1.0** - Added Wazuh integration and monitoring
- **v1.0.0** - Initial release with basic hardening

---

**⚠️ Important**: Always test hardening procedures in a development environment before production deployment. The enhanced playbooks automatically create backups, but save your backup directory location (`/etc/fortress-backups/`) for emergency recovery.

**🔒 Security First**: This tool follows defensive security best practices and includes comprehensive error handling, logging, and rollback capabilities to ensure safe system hardening.

**Made with ❤️ for Linux Security** - Fortress Linux 2026 Edition
