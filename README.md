# Secure Fortress Linux

Secure Fortress Linux is an automated hardening solution designed to secure Linux environments using best practices. By leveraging **Ansible** for configuration management and **Wazuh** for monitoring, it ensures robust system security while allowing continuous compliance monitoring and rootkit detection.

## Features

- Automated Linux hardening via shell scripts.
- Integration with Wazuh for real-time monitoring and alerting.
- Configurable with Ansible for scalable deployments.
- Logs every step for easy auditing and troubleshooting.

## Prerequisites

Before you start, ensure you have the following installed:

- **Ansible** (version 2.9 or higher)
- **Wazuh Agent** (version 4.x)
- Python 3.x (for Ansible)
  
## Project Structure

```bash
.
├── config
│   ├── ansible.cfg
│   └── hosts
├── logs
│   └── deployment.log
├── playbooks
│   └── playbook_hardening.yml
├── scripts
│   └── linux_hardening.sh
└── templates
    └── wazuh-agent-config.j2
```

- **config/**: Ansible configuration files and inventory.
- **logs/**: Log files of the deployment process.
- **playbooks/**: Ansible playbooks for automating the hardening process.
- **scripts/**: The main shell script for hardening Linux systems.
- **templates/**: Template for Wazuh agent configuration.

---

## Installation

### 1. Clone the Repository

### 2. Install Dependencies

#### Install Ansible

For Ubuntu/Debian:

```bash
sudo apt update
sudo apt install ansible -y
```

For CentOS/RHEL:

```bash
sudo yum install epel-release -y
sudo yum install ansible -y
```

#### Install Wazuh Agent

Add the Wazuh repository:

```bash
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | sudo apt-key add -
echo "deb https://packages.wazuh.com/4.x/apt/ stable main" | sudo tee /etc/apt/sources.list.d/wazuh.list
```

Update your package list and install the agent:

```bash
sudo apt update
sudo apt install wazuh-agent
```

### 3. Configure Wazuh Agent

Update the `wazuh-agent-config.j2` template in `templates/` with your Wazuh Manager's IP address:

```xml
<agent_config>
  <client>
    <server>
      <address>{{ wazuh_manager_ip }}</address>
      <port>1514</port>
    </server>
  </client>

  <rootcheck>
    <disabled>no</disabled>
  </rootcheck>

  <syscheck>
    <disabled>no</disabled>
    <directories>/etc</directories>
    <directories>/var/log</directories>
    <ignore>/etc/mtab</ignore>
    <frequency>3600</frequency>
    <auto_ignore>no</auto_ignore>
    <alert_new_files>yes</alert_new_files>
    <scan_on_start>yes</scan_on_start>
  </syscheck>
</agent_config>
```

### 4. Run the Hardening Script with Ansible

Ensure your `hosts` file in `config/hosts` is set up correctly with your target machines:

```ini
[linux_hardened]
192.168.0.10 ansible_user=root
192.168.0.20 ansible_user=root
```

Then run the Ansible playbook:

```bash
ansible-playbook playbooks/playbook_hardening.yml
```

---

## Troubleshooting

### 1. **Wazuh Agent Installation Error** (`Directory not empty`)

If you see an error like:

```bash
mv: cannot overwrite '/var/ossec/etc/shared/default': Directory not empty
```

This means a prior Wazuh agent or manager installation may be causing conflicts. Try the following:

```bash
sudo apt purge wazuh-manager wazuh-agent
sudo rm -rf /var/ossec
```

Then, reinstall the agent:

```bash
sudo apt install wazuh-agent
```

### 2. **Ansible Connection Issues**

If Ansible cannot connect to the target machines (SSH errors):

- Ensure the correct user and SSH key are specified in the `config/hosts` file.
- Disable host key checking in `ansible.cfg`:

```ini
[defaults]
host_key_checking = False
```

- Test the connection manually:

```bash
ssh root@192.168.0.10
```

### 3. **Ansible Timeout**

If the playbook hangs or times out, increase the SSH timeout in `ansible.cfg`:

```ini
[defaults]
timeout = 60
```

### 4. **Wazuh Agent Not Connecting to Manager**

If the Wazuh agent isn't connecting to the manager, verify that:
- The Wazuh Manager IP in `wazuh-agent-config.j2` is correct.
- The ports (1514 and 1515) are open on the Wazuh Manager.
- Restart the agent:

```bash
sudo systemctl restart wazuh-agent
```

### 5. **Playbook Fails with Permission Denied**

Make sure the `remote_user` has sudo privileges on the target machines. You can use `become` in the playbook to escalate privileges:

```yaml
tasks:
  - name: Ensure script is executable
    file:
      path: /path/to/script.sh
      mode: '0755'
    become: yes
```

---

## Best Practices

- **Before Hardening**: Always backup your system configuration, data, and current state before applying any hardening procedures. Test the script on a non-production environment.
  
- **After Hardening**: Regularly monitor your system using Wazuh and verify the hardening measures remain intact with each update or change. Schedule periodic security scans and vulnerability assessments.

---

## License

This project is licensed under the MIT License.

---

This `README.md` provides all the steps needed to deploy, troubleshoot, and manage **Fortress Linux** effectively. Would you like to add anything else to the instructions?
