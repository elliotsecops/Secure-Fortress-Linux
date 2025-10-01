# Fortress Linux - Changelog

All notable changes to the Fortress Linux project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2024-10-01

### 🚀 Major Critical Updates
- **BREAKING CHANGE**: Enhanced bash script with comprehensive error handling
- **BREAKING CHANGE**: Updated minimum Python version to 3.8+
- **BREAKING CHANGE**: Updated minimum Ubuntu version to 22.04+ and Debian 12+

### ✨ New Features
- **Backup & Restore System**: Complete backup and restore functionality
  - Full system backups with compression support
  - Configuration-only backup options
  - One-click restore from backup
  - Backup integrity verification
  - Automated cleanup of old backups
- **Enhanced Error Handling**: Comprehensive error catching and recovery
  - Pre-flight system checks
  - Detailed logging with timestamps
  - Rollback capability on failures
  - Script validation and syntax checking
- **Compatibility Testing**: System verification before deployment
  - OS compatibility validation
  - Dependency checking
  - System requirements validation
  - Post-deployment verification
- **Modern Dependencies**: Updated to latest secure versions
  - Ansible 9.0+ (from 2.9+)
  - Updated Python packages with latest security patches
  - Modern Ansible collections and roles

### 🔒 Security Enhancements
- **Password Policy**: Strengthened from 12 to 14 character minimum
- **SSH Security**: Enhanced with connection timeouts and attempt limits
- **Audit Rules**: Comprehensive system call and file access monitoring
- **File Permissions**: Automatic removal of world-writable permissions
- **Firewall**: Added rate limiting and enhanced logging
- **Service Isolation**: Disabled additional non-essential services

### 🛠️ Technical Improvements
- **Idempotent Scripts**: Safe to run multiple times
- **Logging System**: Comprehensive audit trail with colored output
- **Configuration Management**: Enhanced variable structure
- **Testing Framework**: Built-in compatibility and system testing
- **Documentation**: Completely updated with new features

### 📦 Dependency Updates
- **Ansible**: 2.9.0 → 9.0.0+
- **Python**: 3.6+ → 3.8+
- **pytest**: 7.0.0 → 8.0.0+
- **molecule**: 4.0.0 → 6.0.0+
- **bandit**: 1.7.0 → 1.7.9+
- **safety**: 2.3.0 → 3.0.0+
- **trivy**: 0.40.0 → 0.50.0+
- All other dependencies updated to latest stable versions

### 🧪 New Scripts
- `scripts/backup_restore.sh` - Comprehensive backup and restore utility
- `scripts/compatibility_test.sh` - Full system compatibility testing
- `scripts/system_check.sh` - Quick system verification

### 🔧 Modified Scripts
- `scripts/linux_hardening.sh` - Complete rewrite with error handling
- `install.sh` - Updated with new dependencies and features

### 📚 Documentation
- Complete README.md rewrite with 2024 updates
- New CHANGELOG.md file
- Enhanced troubleshooting section
- Added emergency recovery procedures

### 🐛 Bug Fixes
- Fixed bash script error handling issues
- Resolved dependency conflicts
- Fixed SSH configuration backup issues
- Corrected firewall rule ordering
- Fixed auditd rule validation

### ⚠️ Breaking Changes
- **Minimum Requirements**: Now requires Ubuntu 22.04+ or Debian 12+
- **Python Version**: Minimum Python 3.8+ required
- **Ansible Version**: Updated to Ansible 9.0+ for automation
- **Backup Format**: New backup directory structure and format
- **Log Locations**: Updated log file paths and formats

### 🔄 Migration Notes
- Backups from v1.x are **not compatible** with v2.0 restore functions
- Ansible playbooks may require variable updates for v2.0
- Configuration files have enhanced security settings
- Some default values have changed for better security

## [1.2.0] - 2023-12-15

### ✨ New Features
- **Wazuh Integration**: Added SIEM platform integration
- **Enhanced Monitoring**: Improved log collection and analysis
- **Service Templates**: Additional configuration templates
- **Compliance Checking**: Basic compliance validation

### 🔒 Security Enhancements
- **Audit Rules**: Enhanced file integrity monitoring
- **Network Security**: Additional firewall rules
- **SSH Configuration**: Improved security settings

### 🛠️ Improvements
- **Ansible Roles**: Modular role structure
- **Template System**: Enhanced Jinja2 templates
- **Logging**: Improved log formatting

### 📦 Dependency Updates
- Updated Ansible collections
- Enhanced testing frameworks
- Security tool updates

## [1.1.0] - 2023-06-20

### ✨ New Features
- **Ansible Automation**: Complete automation framework
- **Role-based Architecture**: Modular configuration system
- **Template Support**: Jinja2 template integration
- **Multi-environment Support**: Dev/staging/prod configurations

### 🔒 Security Enhancements
- **Enhanced Password Policies**: Improved complexity requirements
- **Service Hardening**: Additional service configurations
- **File Monitoring**: Expanded file integrity checks

### 🛠️ Improvements
- **Error Handling**: Basic error recovery
- **Logging**: Enhanced logging capabilities
- **Configuration**: Flexible configuration system

### 📦 Dependency Updates
- Added Ansible support
- Updated Python dependencies
- Enhanced testing tools

## [1.0.0] - 2023-01-10

### ✨ Initial Release
- **Basic Hardening**: Core security hardening features
- **Firewall Configuration**: UFW setup and configuration
- **SSH Security**: Basic SSH hardening
- **Service Management**: Unnecessary service disablement
- **Password Policies**: Basic password requirements
- **Audit Logging**: Basic auditd configuration

### 🔒 Security Features
- System updates and patch management
- File permission hardening
- User account security
- Basic monitoring capabilities

### 📚 Documentation
- Basic README documentation
- Installation instructions
- Configuration examples

---

## Migration Guide

### From v1.x to v2.0

1. **Backup Current System**
   ```bash
   # Using v1.x backup method
   sudo cp -r /etc/ssh /tmp/ssh-backup
   sudo cp /etc/security/pwquality.conf /tmp/
   ```

2. **Update Dependencies**
   ```bash
   # Update Python and Ansible
   sudo apt update
   sudo apt install python3.8+ ansible-core
   pip install -r requirements.txt
   ```

3. **Test Compatibility**
   ```bash
   ./scripts/system_check.sh
   ./scripts/compatibility_test.sh
   ```

4. **Create v2.0 Backup**
   ```bash
   sudo ./scripts/backup_restore.sh backup --compress
   ```

5. **Run v2.0 Hardening**
   ```bash
   sudo ./scripts/linux_hardening.sh
   ```

### Important Notes

- **Backups are not backwards compatible** between v1.x and v2.0
- **System requirements have increased** - verify compatibility
- **Default security settings are stronger** in v2.0
- **New logging and monitoring** capabilities in v2.0
- **Rollback is now automated** in v2.0

### Known Issues

- v1.x backups cannot be restored with v2.0 tools
- Some v1.x configurations may need manual updates
- Ansible playbooks from v1.x may require variable updates

### Support

For migration assistance:
1. Check the updated documentation
2. Run compatibility tests
3. Create full system backup before migration
4. Test in non-production environment first