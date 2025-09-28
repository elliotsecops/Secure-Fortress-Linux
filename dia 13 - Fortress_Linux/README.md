# Secure Fortress Linux

A comprehensive security hardening framework for Linux systems, implementing industry best practices for system hardening, monitoring, and protection against modern threats.

## Overview

Secure Fortress Linux is a security automation framework that uses both Ansible playbooks and bash scripts to harden Linux systems. It implements multiple layers of security controls including SSH hardening, firewall configuration, file integrity monitoring, log analysis, and intrusion detection.

## Features

### Security Hardening
- **SSH Security**: Enhanced SSH configuration with non-standard ports, key-based authentication, and strict access controls
- **Firewall Configuration**: UFW firewall with comprehensive rules and port restrictions
- **Password Policies**: Strong password requirements and account security measures
- **System Hardening**: Secure file permissions, kernel parameters, and service configurations
- **Network Security**: Protection against IP spoofing, ICMP attacks, and SYN flooding

### Monitoring and Detection
- **Wazuh Integration**: Complete SIEM solution with real-time monitoring and alerting
- **File Integrity Monitoring**: AIDE and auditd for detecting unauthorized changes
- **Intrusion Detection**: fail2ban protection against brute-force attacks
- **Rootkit Detection**: rkhunter for rootkit and malware detection

### Automation and Maintenance
- **Unattended Updates**: Automatic security patches
- **Regular Monitoring**: Scheduled integrity checks and security scans
- **Comprehensive Logging**: Detailed audit trails and security logs

## Prerequisites

- Ansible 2.9 or higher
- Python 3.6 or higher
- Target systems: Ubuntu 20.04, Ubuntu 22.04, Ubuntu 24.04, Debian 11, Debian 12, CentOS 8, or RHEL 8/9
- SSH access with sudo privileges to target systems

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/elliotsecops/Secure-Fortress-Linux.git
cd Secure-Fortress-Linux
```

### 2. Install Dependencies

Run the dependency installation script:

```bash
sudo ./install_dependencies.sh
```

This script will install:
- Python 3
- Ansible
- Wazuh agent
- Other security tools

### 3. Configure Target Hosts

Edit the inventory file to specify your target systems:

```bash
nano config/hosts
```

Example configuration:
```ini
[fortress_linux]
192.168.1.10 ansible_user=ansible
192.168.1.11 ansible_user=ansible
```

### 4. Configure Wazuh Manager

Update the `wazuh_manager_ip` variable in your inventory or in the playbook:

```yaml
# In your inventory group_vars or in the playbook
wazuh_manager_ip: "YOUR_WAZUH_MANAGER_IP"
```

## Usage

### Method 1: Using Ansible Playbook (Recommended)

```bash
ansible-playbook -i config/hosts playbooks/playbook_hardening.yml
```

### Method 2: Using Bash Script

For single systems, you can use the bash hardening script:

```bash
sudo ./scripts/linux_hardening.sh
```

> **Note**: When using the bash script, you may need to set a custom SSH port:
> ```bash
> export SSH_PORT=2222
> sudo ./scripts/linux_hardening.sh
> ```

## Configuration Details

### Playbook Variables

The main playbook `playbooks/playbook_hardening.yml` supports the following variables:

- `wazuh_manager_ip`: IP address of your Wazuh manager server
- `ssh_port`: SSH port to use (default: 2222)
- `enable_http`: Enable HTTP port in firewall (default: false)
- `enable_https`: Enable HTTPS port in firewall (default: false)

### Security Settings Applied

#### SSH Hardening
- SSH port changed from default 22 to 2222
- Root login disabled
- Password authentication disabled (key-based only)
- Login grace time limited to 60 seconds
- Max authentication attempts set to 3
- Client alive interval set to 300 seconds

#### Firewall Rules
- Default deny for incoming connections
- Default allow for outgoing connections
- SSH access allowed on custom port
- HTTP/HTTPS allowed if enabled

#### Password Policies
- Minimum 14 characters
- At least 4 character classes (uppercase, lowercase, numbers, special chars)
- Password aging (90 days max)
- Password reuse prevention

#### File Integrity Monitoring
- AIDE database initializes for file integrity checking
- auditd rules monitor critical system files
- Scheduled integrity checks

## Post-Installation Verification

After running the hardening process:

1. Verify SSH service is running on the new port
2. Check firewall status: `sudo ufw status`
3. Verify Wazuh agent status: `sudo systemctl status wazuh-agent`
4. Check auditd status: `sudo systemctl status auditd`
5. Review logs in `/var/log/linux_hardening.log`

## Security Best Practices

- Always test in a non-production environment first
- Keep a backup access method before running security scripts
- Regularly update Wazuh agent definitions
- Monitor logs for security events
- Perform regular security audits
- Ensure the Wazuh manager is properly configured to receive agent data

## Troubleshooting

### SSH Access Issues
- If you cannot access the system after hardening, verify the new SSH port (default 2222)
- Check that your SSH client is configured to use the correct port
- Verify that the firewall allows SSH access on the new port

### Wazuh Agent Issues
- Ensure the Wazuh manager IP is correctly configured
- Check network connectivity between agent and manager
- Verify that ports 1514 and 1515 are accessible from agent to manager

### Firewall Issues
- If you accidentally block necessary access, temporarily disable UFW:
  ```bash
  sudo ufw disable
  ```
- Then adjust the firewall rules as needed

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

## Disclaimer

This tool is provided as-is, without warranty of any kind. Always test security hardening scripts in a non-production environment first. The authors are not responsible for any issues that may arise from using this tool.