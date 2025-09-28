# Fortress Linux - System Security Hardening Framework

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Ansible](https://img.shields.io/badge/Ansible-2.9%2B-blue.svg)](https://www.ansible.com/)
[![Linux](https://img.shields.io/badge/Linux-Ubuntu%7CDebian-orange.svg)](https://www.linux.org/)

Fortress Linux is a comprehensive security hardening framework designed to enhance the security posture of Linux systems through automated hardening scripts and Ansible playbooks. This project provides both manual and automated approaches to system hardening, with integrated monitoring capabilities.

## 🎯 Features

### Security Hardening
- **System Updates**: Automated system package updates and security patches
- **Firewall Configuration**: UFW (Uncomplicated Firewall) setup with SSH access
- **Service Hardening**: Disables unnecessary and potentially vulnerable services
- **Password Policy**: Enforces strong password requirements (minimum 12 characters, 4 character classes)
- **SSH Security**: Disables root login and password-based authentication
- **File Permissions**: Secures sensitive system files and directories

### Monitoring & Detection
- **File Integrity Monitoring**: Real-time monitoring of critical system files
- **Audit Logging**: Comprehensive system audit trail with auditd
- **Rootkit Detection**: Built-in rootkit scanning capabilities
- **Log Collection**: Centralized log monitoring and analysis
- **Intrusion Detection**: Integration with Wazuh SIEM platform

### Automation
- **Ansible Playbooks**: Automated deployment and configuration management
- **Bash Scripts**: Manual hardening capabilities for individual systems
- **Template-based Configuration**: Jinja2 templates for flexible configuration
- **Logging and Auditing**: Comprehensive deployment and system logs

## 📋 Prerequisites

### System Requirements
- **Operating System**: Ubuntu 18.04+ or Debian 9+
- **Architecture**: x86_64 or ARM64
- **Memory**: Minimum 2GB RAM
- **Storage**: Minimum 10GB free disk space
- **Network**: Internet connection for package installation

### Software Dependencies
- **Bash**: Version 4.0+
- **Ansible**: Version 2.9+ (for automated deployment)
- **Python**: Version 3.6+ (Ansible dependency)
- **Wazuh Agent**: Version 4.0+ (optional, for SIEM integration)

### User Requirements
- **Root Access**: Administrative privileges required for system modifications
- **SSH Access**: Working SSH connection for remote deployment
- **Backup**: System backup recommended before hardening

## 🚀 Installation

### Method 1: Manual Installation (Bash Script)

1. **Clone the Repository**
   ```bash
   git clone https://github.com/your-username/fortress-linux.git
   cd fortress-linux
   ```

2. **Make Script Executable**
   ```bash
   chmod +x scripts/linux_hardening.sh
   ```

3. **Run Hardening Script**
   ```bash
   sudo ./scripts/linux_hardening.sh
   ```

### Method 2: Automated Installation (Ansible)

1. **Install Ansible**
   ```bash
   sudo apt update
   sudo apt install ansible -y
   ```

2. **Configure Target Systems**
   ```bash
   # Edit config/hosts file with your server IP(s)
   nano config/hosts
   ```

3. **Configure Ansible Settings**
   ```bash
   # Update config/ansible.cfg with your SSH user
   nano config/ansible.cfg
   ```

4. **Run Ansible Playbook**
   ```bash
   ansible-playbook -i config/hosts playbooks/playbook_hardening.yml
   ```

## ⚙️ Configuration

### Ansible Configuration (`config/ansible.cfg`)

```ini
[defaults]
inventory = ./config/hosts
remote_user = your_ansible_user
host_key_checking = False
retry_files_enabled = False
log_path = ./logs/deployment.log
timeout = 30
forks = 10
gathering = smart
gather_facts = True

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False

[ssh_connection]
ssh_args = -o ForwardAgent=yes -o ControlMaster=auto -o ControlPersist=60s
pipelining = True
```

### Host Inventory (`config/hosts`)

```
[webservers]
192.168.1.10 ansible_user=admin
192.168.1.11 ansible_user=admin

[databases]
192.168.1.20 ansible_user=admin
```

### Wazuh Agent Configuration (`templates/wazuh-agent-config.j2`)

Key configuration options:
- **Server Address**: Wazuh manager IP address
- **Monitoring Directories**: `/etc`, `/var/log`, `/bin`
- **Scan Frequency**: Hourly file integrity checks
- **Rootkit Detection**: Enabled with 12-hour intervals
- **Real-time Monitoring**: Enabled for critical binaries

## 🔧 Usage

### Manual Hardening
The bash script performs the following actions automatically:

1. **System Updates**
   ```bash
   apt update && apt upgrade -y
   ```

2. **Firewall Configuration**
   ```bash
   ufw default deny incoming
   ufw default allow outgoing
   ufw allow OpenSSH
   ufw enable
   ```

3. **Service Hardening**
   ```bash
   systemctl disable avahi-daemon
   systemctl disable cups
   systemctl disable nfs-server
   ```

4. **Password Policy**
   ```bash
   echo "minlen = 12" >> /etc/security/pwquality.conf
   echo "minclass = 4" >> /etc/security/pwquality.conf
   ```

5. **SSH Security**
   ```bash
   sed -i "s/^#PermitRootLogin.*/PermitRootLogin no/" /etc/ssh/sshd_config
   sed -i "s/^#PasswordAuthentication.*/PasswordAuthentication no/" /etc/ssh/sshd_config
   ```

### Ansible Playbook Usage
The playbook provides automated deployment with the following tasks:

1. **Package Installation**: Installs security packages (UFW, fail2ban, auditd, Wazuh)
2. **Wazuh Configuration**: Deploys and configures Wazuh agent
3. **Firewall Setup**: Configures UFW with SSH access
4. **Service Management**: Enables and starts security services
5. **Auto Updates**: Configures unattended security updates

## 📊 Monitoring and Logging

### Log Files
- **Deployment Logs**: `logs/deployment.log`
- **System Logs**: `/var/log/auth.log`, `/var/log/syslog`
- **Audit Logs**: `/var/log/audit/audit.log`
- **Wazuh Logs**: `/var/ossec/logs/ossec.log`

### Monitoring Commands
```bash
# Check firewall status
sudo ufw status

# Verify auditd service
sudo systemctl status auditd

# Check Wazuh agent
sudo systemctl status wazuh-agent

# View recent security events
sudo tail -f /var/log/auth.log
```

## 🛡️ Security Features

### Implemented Hardening Measures
- **Network Security**: Firewall configuration, SSH hardening
- **Access Control**: Password policies, user permission management
- **File Security**: Permission hardening, integrity monitoring
- **Service Security**: Unnecessary service disablement
- **Monitoring**: Audit logging, intrusion detection
- **Patch Management**: Automated security updates

### Compliance Standards
- **CIS Benchmarks**: Aligns with CIS Ubuntu Linux Benchmark
- **NIST Standards**: Follows NIST cybersecurity framework
- **SOC 2**: Implements controls for security monitoring
- **GDPR**: Data protection and logging requirements

## 🔍 Troubleshooting

### Common Issues

#### SSH Connection Issues
```bash
# Check SSH service status
sudo systemctl status sshd

# Verify SSH configuration
sudo sshd -t

# Check firewall rules
sudo ufw status
```

#### Ansible Connection Problems
```bash
# Test SSH connectivity
ansible -i config/hosts all -m ping

# Check Ansible configuration
ansible --version

# Verify inventory file
ansible-inventory -i config/hosts --list
```

#### Wazuh Agent Issues
```bash
# Check Wazuh service
sudo systemctl status wazuh-agent

# Test connectivity to Wazuh manager
sudo /var/ossec/bin/agent_control -l

# Verify configuration
sudo /var/ossec/bin/ossec-logtest -f /var/ossec/etc/ossec.conf
```

### Error Resolution
1. **Permission Denied**: Ensure running with sudo privileges
2. **Package Installation**: Verify internet connectivity and package sources
3. **Service Failures**: Check system logs with `journalctl -u service-name`
4. **Configuration Errors**: Validate syntax and file paths

## 🧪 Testing

### Pre-deployment Testing
```bash
# Test in development environment first
# Create system backup
sudo timeshift --create --comments "pre-hardening"

# Verify script syntax
bash -n scripts/linux_hardening.sh

# Test Ansible playbook syntax
ansible-playbook --syntax-check playbooks/playbook_hardening.yml
```

### Post-deployment Verification
```bash
# Check system hardening status
sudo systemctl list-unit-files --state=enabled

# Verify firewall rules
sudo ufw status verbose

# Test password policy
chage -l username

# Check SSH configuration
sudo sshd -T | grep -E "permitrootlogin|passwordauthentication"
```

## 📚 Documentation

### Additional Resources
- [CIS Security Benchmarks](https://www.cisecurity.org/cis-benchmarks/)
- [Ansible Documentation](https://docs.ansible.com/)
- [Wazuh Documentation](https://documentation.wazuh.com/)
- [Ubuntu Security Guide](https://ubuntu.com/security)

### Configuration Files
- `scripts/linux_hardening.sh` - Main hardening script
- `playbooks/playbook_hardening.yml` - Ansible playbook
- `config/ansible.cfg` - Ansible configuration
- `config/hosts` - Host inventory
- `templates/wazuh-agent-config.j2` - Wazuh agent template

## 🤝 Contributing

### Development Workflow
1. Fork the repository
2. Create feature branch: `git checkout -b feature/new-feature`
3. Test changes in development environment
4. Submit pull request with detailed description
5. Code review and testing

### Guidelines
- Follow security best practices
- Test all changes thoroughly
- Update documentation for new features
- Use appropriate coding standards
- Consider backward compatibility

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙋‍♂️ Support

### Getting Help
- **Documentation**: Read this README and inline code comments
- **Issues**: Create GitHub issue with detailed description
- **Community**: Join our security community discussions
- **Email**: Contact support team for enterprise assistance

### Reporting Security Issues
For security vulnerabilities, please email security@example.com with details:
- Vulnerability description
- Affected versions
- Reproduction steps
- Potential impact

## 🎯 Roadmap

### Upcoming Features
- [ ] Multi-distribution support (CentOS, RHEL)
- [ ] Cloud platform integration
- [ ] Compliance reporting dashboard
- [ ] Automated backup and recovery
- [ ] Security scanning and assessment tools
- [ ] Container security hardening

### Version History
- **v1.0.0** - Initial release with basic hardening
- **v1.1.0** - Added Wazuh integration
- **v1.2.0** - Enhanced Ansible automation
- **v2.0.0** - Comprehensive monitoring framework

---

**⚠️ Important**: Always test hardening procedures in a development environment before production deployment. Create system backups and ensure you have alternative access methods before applying security changes.

**Made with ❤️ for Linux Security**
