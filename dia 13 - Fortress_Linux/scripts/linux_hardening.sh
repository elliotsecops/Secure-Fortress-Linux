#!/bin/bash

# Function to log messages
log() {
    echo \"[$(date +'%Y-%m-%d %H:%M:%S')] $1\" | tee -a /var/log/linux_hardening.log
}

# Function to backup files before modification
backup_file() {
    local file=\"$1\"
    if [ -f \"$file\" ]; then
        cp \"$file\" \"$file.backup.$(date +%Y%m%d_%H%M%S)\"
        log \"Backed up $file to $file.backup.$(date +%Y%m%d_%H%M%S)\"
    fi
}

log \"Starting Linux system hardening process...\"

# Function to update the system safely
update_system() {
    log \"Updating the system...\"
    apt update -y && apt upgrade -y
    # Upgrade to full distribution upgrade but without removing packages
    apt full-upgrade -y --no-remove
    # Clean up unnecessary packages
    apt autoremove -y
    apt autoclean
}

# Execute system update
update_system

# Verify the distribution and set appropriate settings
DISTRO=$(lsb_release -i | awk -F':\t' '{print $2}' | tr '[:upper:]' '[:lower:]')

# Change SSH port from default to reduce automated attacks
SSH_PORT=\"${SSH_PORT:-2222}\"  # Use environment variable or default to 2222
log \"Configuring SSH to use port $SSH_PORT instead of default 22...\"

# Backup SSH config before changes
backup_file /etc/ssh/sshd_config

# Update SSH configuration with comprehensive security settings
sed -i \"s/^#Port 22/Port $SSH_PORT/\" /etc/ssh/sshd_config
sed -i \"s/Port 22/Port $SSH_PORT/\" /etc/ssh/sshd_config 2>/dev/null || echo \"Port $SSH_PORT\" >> /etc/ssh/sshd_config
sed -i \"s/^#PermitRootLogin.*/PermitRootLogin no/\" /etc/ssh/sshd_config
sed -i \"s/^PermitRootLogin.*/PermitRootLogin no/\" /etc/ssh/sshd_config
sed -i \"s/^#PasswordAuthentication.*/PasswordAuthentication no/\" /etc/ssh/sshd_config
sed -i \"s/^PasswordAuthentication.*/PasswordAuthentication no/\" /etc/ssh/sshd_config
sed -i \"s/^#PubkeyAuthentication.*/PubkeyAuthentication yes/\" /etc/ssh/sshd_config
sed -i \"s/^#PermitEmptyPasswords.*/PermitEmptyPasswords no/\" /etc/ssh/sshd_config
sed -i \"s/^#MaxAuthTries.*/MaxAuthTries 3/\" /etc/ssh/sshd_config
sed -i \"s/^#MaxSessions.*/MaxSessions 3/\" /etc/ssh/sshd_config
sed -i \"s/^#LoginGraceTime.*/LoginGraceTime 60/\" /etc/ssh/sshd_config
sed -i \"s/^#ClientAliveInterval.*/ClientAliveInterval 300/\" /etc/ssh/sshd_config
sed -i \"s/^#ClientAliveCountMax.*/ClientAliveCountMax 2/\" /etc/ssh/sshd_config
sed -i \"s/^#StrictModes.*/StrictModes yes/\" /etc/ssh/sshd_config
sed -i \"s/^#X11Forwarding.*/X11Forwarding no/\" /etc/ssh/sshd_config
sed -i \"s/^#AllowTcpForwarding.*/AllowTcpForwarding yes/\" /etc/ssh/sshd_config
sed -i \"s/^#PrintLastLog.*/PrintLastLog yes/\" /etc/ssh/sshd_config

# Restart SSH service after changes
systemctl restart ssh
systemctl restart sshd 2>/dev/null || true  # Try both service names

# Enable and configure UFW firewall
log \"Configuring firewall UFW...\"
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow $SSH_PORT/tcp comment \"SSH access\"
ufw logging on

# Only enable UFW after successful SSH configuration check
if systemctl is-active --quiet ssh || systemctl is-active --quiet sshd; then
    ufw --force enable
    log \"UFW firewall enabled with SSH port $SSH_PORT\"
else
    log \"WARNING: SSH service not running, UFW not enabled to avoid lockout\"
fi

# Disable unnecessary services based on distribution
log \"Disabling unnecessary services...\"
services_to_disable=(
    \"avahi-daemon\"
    \"cups\"
    \"nfs-server\"
    \"rpcbind\"
    \"bluetooth\"
    \"ModemManager\"
    \"whoopsie\"
    \"speech-dispatcher\"
    \"cups-browsed\"
    \"avahi-daemon\"
)

for service in \"${services_to_disable[@]}\"; do
    if systemctl is-enabled --quiet \"$service\" 2>/dev/null; then
        systemctl stop \"$service\" 2>/dev/null
        systemctl disable \"$service\"
        log \"Disabled service: $service\"
    fi
done

# Configure password policies using pam_pwquality
log \"Configuring password policies...\"
if ! command -v libpam-pwquality >/dev/null 2>&1; then
    apt install -y libpam-pwquality
fi

backup_file /etc/security/pwquality.conf

# Configure password quality requirements with stronger settings
cat <<EOF > /etc/security/pwquality.conf
# Configuration for the pam_pwquality module
# Number of characters in the new password that must not be present in the old password
difok = 3
# Minimum acceptable size for the new password (plus 1 for each character missing from other classes)
minlen = 14
# Minimum number of characters that must be from a different class than the previous character
minclass = 4
# Maximum number of characters from the same class that can be present consecutively
maxrepeat = 2
# Maximum number of allowed same consecutive characters in the same class in the new password
maxclassrepeat = 4
# Whether to check for characters from classes that are common for this locale
gecoscheck = 1
# Whether to check for palindromes
enforcing = 1
# Number of changes in case of wrong old password
dictcheck = 1
# Maximum credit for having digits in the password
dcredit = -1
# Maximum credit for having uppercase letters in the password
ucredit = -1
# Maximum credit for having lowercase letters in the password
lcredit = -1
# Maximum credit for having other characters in the password
ocredit = -1
EOF

# Configure password aging and account settings
backup_file /etc/login.defs

# Set password aging parameters in login.defs
sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS   90/' /etc/login.defs
sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS   7/' /etc/login.defs
sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE   14/' /etc/login.defs

# Configure limits for users
cat <<EOF >> /etc/security/limits.conf

# Security limits for all users
*               hard    core            0
*               hard    nproc           250
*               hard    nofile          2048
*               hard    fsize           2097152
*               hard    sigpending      30968
*               hard    msgqueue        819200
*               hard    memlock         65536
*               hard    locks           1024
EOF

# Configure auditd for comprehensive monitoring
log \"Configuring auditd for comprehensive monitoring...\"
backup_file /etc/audit/rules.d/hardening.rules

cat <<EOF > /etc/audit/rules.d/fortress.rules
## First rule: delete all
-D

## Increase the buffers to survive stress events.
## Make this 8192 if you have lots of users, sparc users, 64bit, or run lots of
## java programs.
-b 8192

## Set failure mode to syslog (use LOG_AUDEIT for auditd logging)
-f 1

## User/group id changes
-w /etc/passwd -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/group -p wa -k identity
-w /etc/gshadow -p wa -k identity
-w /etc/security/opasswd -p wa -k identity

## Network configuration changes
-w /etc/hosts -p wa -k network
-w /etc/network/ -p wa -k network

## Monitor sudoers file
-w /etc/sudoers -p wa -k scope
-w /etc/sudoers.d/ -p wa -k scope

## Monitor cron jobs
-w /etc/crontab -p wa -k cron
-w /etc/cron.d/ -p wa -k cron
-w /etc/cron.daily/ -p wa -k cron
-w /etc/cron.hourly/ -p wa -k cron
-w /etc/cron.monthly/ -p wa -k cron
-w /etc/cron.weekly/ -p wa -k cron
-w /var/spool/cron/crontabs/ -p wa -k cron

## Monitor system log files
-w /var/log/wtmp -p wa -k logins
-w /var/run/utmp -p wa -k logins
-w /etc/utmp -p wa -k logins

## Monitor system administration
-w /etc/sudoers -p rwxa -k admin
-w /usr/sbin/useradd -p x -k admin
-w /usr/sbin/userdel -p x -k admin
-w /usr/sbin/usermod -p x -k admin
-w /usr/sbin/groupadd -p x -k admin
-w /usr/sbin/groupdel -p x -k admin
-w /usr/sbin/groupmod -p x -k admin

## Monitor critical system binaries
-w /bin/mount -p x -k privileged
-w /bin/umount -p x -k privileged
-w /usr/bin/passwd -p x -k privileged
-w /usr/sbin/userdel -p x -k privileged
-w /usr/sbin/usermod -p x -k privileged
-w /usr/bin/su -p x -k privileged
-w /usr/bin/sudo -p x -k privileged
-w /etc/sudoers -p rwxa -k privileged
-w /etc/sudoers.d/ -p rwxa -k privileged

## Monitor kernel modules
-w /sbin/insmod -p x -k modules
-w /sbin/rmmod -p x -k modules
-w /sbin/modprobe -p x -k modules

## Monitor file system changes
-a always,exit -F arch=b64 -S creat -S open -S openat -S truncate -S faccessat -F exit=-EACCES -k access
-a always,exit -F arch=b64 -S creat -S open -S openat -S truncate -S faccessat -F exit=-EPERM -k access
EOF

# Restart auditd to apply new rules
systemctl restart auditd

# Configure system file permissions
log \"Configuring system file and directory permissions...\"
chmod 644 /etc/passwd
chmod 640 /etc/shadow
chmod 644 /etc/group
chmod 600 /etc/gshadow
chmod 600 /etc/hosts.allow
chmod 644 /etc/hosts.deny

# Set more secure permissions for network configuration
chmod 600 /etc/hosts
chmod 644 /etc/resolv.conf
chmod 600 /etc/crontab
chmod 600 /etc/cron.d/
chmod 600 /etc/cron.daily/
chmod 600 /etc/cron.hourly/
chmod 600 /etc/cron.monthly/
chmod 600 /etc/cron.weekly/

# Secure home directories
log \"Securing user home directories...\"
for user_home in /home/*; do
    if [ -d \"$user_home\" ]; then
        chmod 750 \"$user_home\"
        chmod 600 \"$user_home/.bash_history\" 2>/dev/null || true
        chmod 600 \"$user_home/.ssh/authorized_keys\" 2>/dev/null || true
        chmod 600 \"$user_home/.ssh/config\" 2>/dev/null || true
        chmod 600 \"$user_home/.ssh/known_hosts\" 2>/dev/null || true
    fi
done

# Configure fail2ban for SSH protection
log \"Configuring fail2ban for SSH protection...\"
if command -v fail2ban-server >/dev/null 2>&1; then
    backup_file /etc/fail2ban/jail.local
    
    cat <<EOF > /etc/fail2ban/jail.local
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3
banaction = ufw
backend = systemd

[sshd]
enabled = true
port = $SSH_PORT
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
findtime = 600
EOF

    systemctl restart fail2ban
    log \"fail2ban configured for SSH protection on port $SSH_PORT\"
else
    log \"fail2ban not installed, skipping configuration\"
fi

# Configure automatic security updates
log \"Configuring automatic security updates...\"
if command -v unattended-upgrade >/dev/null 2>&1; then
    dpkg-reconfigure --priority=low unattended-upgrades
    log \"Automatic security updates enabled\"
fi

# Kernel security parameters
log \"Configuring kernel security parameters...\"
backup_file /etc/sysctl.conf

cat <<EOF >> /etc/sysctl.conf
# IP Spoofing protection
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Ignore ICMP broadcast requests
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Disable source packet routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0

# Ignore send redirects
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# Block SYN attacks
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 5

# Log Martians
net.ipv4.conf.all.log_martians = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1

# Ignore ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0

# Make sure /proc is properly mounted
fs.suid_dumpable = 0

# Protect against time-wait assassination
net.ipv4.tcp_rfc1337 = 1

# Prevent against tcp desync attacks
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_intvl = 60
net.ipv4.tcp_keepalive_probes = 3

# Protect against SYN flood attacks
net.ipv4.tcp_synack_retries = 2

# DCCP settings
net.dccp.default CCID 2

# RPC settings
sunrpc.tcp_fin_timeout = 15

# Randomize virtual memory area placement
kernel.randomize_va_space = 2

# Disable acceptance of IPv6 router advertisements
net.ipv6.conf.all.accept_ra = 0
net.ipv6.conf.default.accept_ra = 0

# Disable forwarding of IPv6 router advertisements
net.ipv6.conf.all.accept_ra_rt_info_max_plen = 0

# Additional security settings
kernel.kptr_restrict = 1
kernel.dmesg_restrict = 1
kernel.unprivileged_bpf_disabled = 1
net.core.bpf_jit_harden = 2
EOF

# Apply the kernel security parameters
sysctl -p

# Additional security configurations
log \"Configuring additional security measures...\"

# Secure shared memory
if ! grep -q \"/dev/shm.*tmpfs.*noexec,nosuid,nodev\" /etc/fstab; then
    echo \"tmpfs /dev/shm tmpfs defaults,noexec,nosuid,nodev 0 0\" >> /etc/fstab
    mount -o remount /dev/shm
    log \"Secured shared memory (/dev/shm)\"
fi

# Check for and remove any .rhosts files
find / -name .rhosts -print -delete 2>/dev/null | tee -a /var/log/linux_hardening.log

# Remove insecure services from inetd if present
if [ -f /etc/inetd.conf ]; then
    backup_file /etc/inetd.conf
    sed -i 's/^/#/' /etc/inetd.conf  # Comment out all services
fi

# Verify no one has root UID (0) in /etc/passwd except root
if awk -F: '($3 == 0 && $1 != \"root\") { print $1 }' /etc/passwd; then
    log \"WARNING: Found non-root user with UID 0!\"
fi

# Set MOTD (Message of the Day) to inform about monitoring
cat <<EOF > /etc/motd
*************************************************************************
*                                                                       *
* This system is for authorized use only.                               *
* All activities are monitored and recorded.                            *
* Disconnect immediately if you are not an authorized user.            *
*                                                                       *
*************************************************************************
EOF

# Set a more detailed issue banner
cat <<EOF > /etc/issue
This system is for authorized use only.
All activities are monitored and recorded.
Disconnect immediately if you are not authorized.
EOF

# Set the same banner for SSH
cat <<EOF > /etc/issue.net
This system is for authorized use only.
All activities are monitored and recorded.
EOF

# Configure SSH to display the banner
echo \"Banner /etc/issue.net\" >> /etc/ssh/sshd_config
systemctl restart ssh
systemctl restart sshd 2>/dev/null || true

log \"Linux hardening completed. Please review /var/log/linux_hardening.log for details.\"
log \"Important: Test SSH access using port $SSH_PORT before disconnecting from current session.\"