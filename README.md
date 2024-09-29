# **Fortress Linux: Building an Impenetrable Digital Stronghold**

**Fortress Linux** is an automated Linux hardening solution designed to improve your system's security posture. It integrates **Ansible** for streamlined deployment across multiple systems and **Wazuh** for continuous monitoring and alerting of security threats. With a focus on automation, scalability, and robust protection, Fortress Linux helps you lock down your servers and track potential risks in real-time.

---

## **Table of Contents**
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
  - [Install Dependencies](#install-dependencies)
  - [Install Wazuh](#install-wazuh)
  - [Install Ansible](#install-ansible)
- [Project Structure](#project-structure)
- [Usage](#usage)
  - [Run the Script with Ansible](#run-the-script-with-ansible)
  - [Monitoring with Wazuh](#monitoring-with-wazuh)
- [Best Practices](#best-practices)
- [License](#license)

---

## **Features**

- **Automated Hardening**: Secures Linux servers with firewall rules, SSH configuration, service management, password policies, and auditing.
- **Ansible Integration**: Automates the deployment of hardening policies across multiple systems.
- **Wazuh Monitoring**: Provides real-time monitoring and alerting on security-related events such as unauthorized file changes and suspicious log entries.
- **Scalable & Consistent**: Easily scalable to any number of servers with consistent application of security policies.
- **Modular & Extensible**: Flexible architecture allows for easy customization and expansion of the hardening policies.

---

## **Prerequisites**

Before you start, ensure that you have the following:
1. A **Linux server** or multiple servers for testing/deployment.
2. **Root or sudo access** to the servers.
3. **Ansible** installed on a control node for managing servers.
4. **Wazuh Manager** installed to collect alerts from agents (installed on the target servers).
5. **Git** for cloning this repository.

---

## **Installation**

### **Install Dependencies**

Ensure your system is updated and basic dependencies are installed.

```bash
sudo apt update
sudo apt install -y curl wget git
```

### **Install Wazuh**

Wazuh is an open-source security monitoring platform that will track changes and security events in real-time. Follow the steps below to install the **Wazuh Manager** and **Agent**.

#### **1. Install Wazuh Manager**

On the monitoring server, install Wazuh Manager:

```bash
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | sudo apt-key add -
echo "deb https://packages.wazuh.com/4.x/apt/ stable main" | sudo tee /etc/apt/sources.list.d/wazuh.list
sudo apt update
sudo apt install wazuh-manager
```

Start and enable the Wazuh Manager service:

```bash
sudo systemctl start wazuh-manager
sudo systemctl enable wazuh-manager
```

#### **2. Install Wazuh Agent**

On each server you want to monitor (where the hardening script will run), install Wazuh Agent:

```bash
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | sudo apt-key add -
echo "deb https://packages.wazuh.com/4.x/apt/ stable main" | sudo tee /etc/apt/sources.list.d/wazuh.list
sudo apt update
sudo apt install wazuh-agent
```

Configure the Wazuh Agent to point to your Wazuh Manager by editing the `/var/ossec/etc/ossec.conf` file. Replace `MANAGER_IP` with the actual IP of your Wazuh Manager:

```xml
<client>
  <address>MANAGER_IP</address>
  <port>1514</port>
</client>
```

Start and enable the Wazuh Agent:

```bash
sudo systemctl start wazuh-agent
sudo systemctl enable wazuh-agent
```

### **Install Ansible**

On the control node (your system from which you'll manage the servers), install **Ansible**:

1. Add the Ansible PPA repository:

   ```bash
   sudo apt update
   sudo apt install -y software-properties-common
   sudo add-apt-repository --yes --update ppa:ansible/ansible
   ```

2. Install Ansible:

   ```bash
   sudo apt install -y ansible
   ```

3. Verify Ansible installation:

   ```bash
   ansible --version
   ```

---

## **Project Structure**

The **Fortress Linux** project includes the following directories and files:

```
Fortress_Linux/
├── scripts/
│   └── linux_hardening.sh
├── playbooks/
│   └── playbook_hardening.yml
├── templates/
│   └── wazuh-agent-config.j2
├── config/
│   ├── ansible.cfg
│   ├── hosts
├── logs/
│   └── deployment.log
└── README.md
```

- **scripts/**: Contains the main Bash script (`linux_hardening.sh`) that performs the hardening steps.
- **playbooks/**: Ansible playbook for deploying the hardening script and installing Wazuh Agent.
- **templates/**: Contains a Jinja2 template for configuring Wazuh Agent (`wazuh-agent-config.j2`).
- **config/**: Configuration files for Ansible, including the inventory file (`hosts`) and `ansible.cfg`.
- **logs/**: Logs generated during the deployment process.

---

## **Usage**

### **Run the Script with Ansible**

1. Clone this repository to your Ansible control node:

   ```bash
   git clone https://github.com/your-repo/fortress-linux.git
   cd fortress-linux
   ```

2. Edit the `config/hosts` file to include the target servers:

   ```ini
   [hardening_targets]
   server1 ansible_host=192.168.1.10
   server2 ansible_host=192.168.1.11
   ```

3. Run the Ansible playbook to deploy the hardening script and Wazuh Agent:

   ```bash
   ansible-playbook -i config/hosts playbook_hardening.yml
   ```

This will:
- Update the target systems.
- Deploy the hardening script.
- Install and configure Wazuh Agent.
- Log the deployment process in `logs/deployment.log`.

### **Monitoring with Wazuh**

Once the hardening process is complete, Wazuh will start monitoring the hardened systems. From your **Wazuh Manager**'s dashboard, you can:

- **Track file integrity**: Monitor changes to critical files like `/etc/passwd` and `/etc/shadow`.
- **Log analysis**: Detect suspicious activity in system logs.
- **Receive alerts**: Get notified of any security-related events in real-time.

---

## **Best Practices**

### **Before Running the Script:**
1. **Test in a Staging Environment**: Always run the script on a non-production server to ensure that no unintended disruptions occur.
2. **Backups**: Ensure you have recent backups of your system and configuration files.
3. **Review SSH Settings**: Double-check SSH hardening measures, such as disabling root login, to avoid locking yourself out.

### **After Running the Script:**
1. **Monitor Continuously**: Use Wazuh to continuously monitor the security of the system and look for unauthorized changes.
2. **Review Logs**: Regularly check deployment and system logs for any potential issues.
3. **Update Regularly**: Keep the hardening script updated with the latest security recommendations.

---

## **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
