# Secure Fortress Linux

Secure Fortress Linux is an automated hardening solution designed to secure Linux environments using best practices. By leveraging Ansible for configuration management and Wazuh for monitoring, it ensures robust system security while allowing continuous compliance monitoring and rootkit detection.

## Table of Contents
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Installation](#installation)
- [Usage](#usage)
- [Bash Script (`linux_hardening.sh`)](#bash-script-linux_hardeningsh)
- [Correlation Between Components](#correlation-between-components)
- [Contributing](#contributing)
- [License](#license)

## Features
- **Automated Linux Hardening:** Utilizes shell scripts to harden Linux systems.
- **Wazuh Integration:** Real-time monitoring and alerting with Wazuh.
- **Configurable with Ansible:** Scalable deployments using Ansible playbooks.
- **Logging:** Logs every step for easy auditing and troubleshooting.

## Prerequisites
Before you start, ensure you have the following installed:
- Ansible (version 2.9 or higher)
- Wazuh Agent (version 4.x)
- Python 3.x (for Ansible)

## Project Structure
```plaintext
.
├── config
│   ├── ansible.cfg
│   └── hosts
├── logs
│   └── deployment.log
├── playbooks
│   └── playbook_hardening.yml
├── scripts
│   └── linux_hardening.sh
└── templates
    └── wazuh-agent-config.j2
```
- **config/:** Ansible configuration files and inventory.
- **logs/:** Log files of the deployment process.
- **playbooks/:** Ansible playbooks for automating the hardening process.
- **scripts/:** The main shell script for hardening Linux systems.
- **templates/:** Template for Wazuh agent configuration.

## Installation
1. **Clone the Repository:**
   ```sh
   git clone https://github.com/elliotsecops/Secure-Fortress-Linux.git
   cd Secure-Fortress-Linux
   ```

2. **Install Prerequisites:**
   - Ensure Ansible, Wazuh Agent, and Python 3.x are installed on your system.

3. **Configure Ansible:**
   - Update the `config/hosts` file with your target server details.
   - Customize the `config/ansible.cfg` file if necessary.

4. **Run the Hardening Script:**
   ```sh
   ansible-playbook playbooks/playbook_hardening.yml
   ```

## Usage
1. **Customize Configuration:**
   - Modify the `templates/wazuh-agent-config.j2` file to match your Wazuh server configuration.
   - Adjust the `scripts/linux_hardening.sh` script to fit your specific hardening requirements.

2. **Execute the Playbook:**
   ```sh
   ansible-playbook playbooks/playbook_hardening.yml
   ```

3. **Review Logs:**
   - Check the `logs/deployment.log` file for detailed logs of the hardening process.

## Bash Script (`linux_hardening.sh`)
The `linux_hardening.sh` script performs various security hardening tasks on the system. Here's a breakdown of what it does:

1. **System Update:**
   - Updates the package list and upgrades all installed packages to their latest versions.

2. **Firewall Configuration:**
   - Configures the UFW (Uncomplicated Firewall) to block all incoming traffic by default and allow all outgoing traffic.
   - Allows SSH traffic.
   - Enables the UFW firewall.

3. **Service Disabling:**
   - Disables unnecessary services such as `avahi-daemon`, `cups`, and `nfs-server`.

4. **Password Security:**
   - Enhances password security by setting minimum password length to 12 characters and requiring at least four character classes (e.g., uppercase, lowercase, digits, special characters).

5. **Auditd Configuration:**
   - Configures `auditd` to monitor changes to critical files like `/etc/passwd`, `/etc/shadow`, `/etc/gshadow`, and `/etc/group`.

6. **File and Directory Permissions:**
   - Sets basic permissions on sensitive files and directories.

7. **SSH Configuration:**
   - Disables root login via SSH.
   - Disables password authentication for SSH, forcing the use of SSH keys.
   - Restarts the SSH service to apply the new configuration.

## Correlation Between Components
The components of Secure Fortress Linux work together to ensure comprehensive system hardening and monitoring:

1. **Ansible Configuration (`ansible.cfg`):**
   - Sets up the environment and behavior for Ansible, including inventory management, remote user settings, logging, privilege escalation, and SSH connection options.

2. **Bash Script (`linux_hardening.sh`):**
   - Performs the initial hardening tasks on the system, such as updating the system, configuring the firewall, and securing SSH.

3. **Wazuh Agent Configuration Template (`wazuh-agent-config.j2`):**
   - Configures the Wazuh agent to monitor and alert on security-related events, such as rootkit detection, file integrity monitoring, and log collection.

4. **Ansible Playbook (`playbook_hardening.yml`):**
   - Orchestrates the execution of the Bash script and the configuration of the Wazuh agent. It uses the `wazuh-agent-config.j2` template to generate the Wazuh agent configuration file and applies it to the target hosts.

### Summary:
The `linux_hardening.sh` Bash script performs the initial hardening tasks on the system, while the `wazuh-agent-config.j2` template configures the Wazuh agent to monitor and alert on security-related events. The Ansible playbook (`playbook_hardening.yml`) orchestrates the execution of these tasks, ensuring a seamless and automated hardening and monitoring process.

## Contributing
We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for more details.

## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.
