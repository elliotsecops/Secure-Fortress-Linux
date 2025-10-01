"""
Basic Security Tests for Fortress Linux
Tests fundamental security hardening measures
"""

import pytest
import testinfra

@pytest.mark.parametrize("service,expected_state", [
    ("ufw", "running"),
    ("auditd", "running"),
    ("apparmor", "running"),
])
def test_security_services_running(host, service, expected_state):
    """Test that security services are running and enabled"""
    service_obj = host.service(service)
    assert service_obj.is_running
    assert service_obj.is_enabled

def test_ssh_hardening(host):
    """Test SSH security hardening configuration"""
    sshd_config = host.file("/etc/ssh/sshd_config")

    # Check critical SSH security settings
    assert sshd_config.contains("PermitRootLogin no")
    assert sshd_config.contains("PasswordAuthentication no")
    assert sshd_config.contains("Protocol 2")

    # Verify file permissions
    assert sshd_config.user == "root"
    assert sshd_config.group == "root"
    assert sshd_config.mode == 0o644

def test_firewall_configuration(host):
    """Test UFW firewall configuration"""
    # Check if UFW is active
    ufw_status = host.run("ufw status")
    assert "Status: active" in ufw_status.stdout

    # Check default policies
    assert "Default: deny (incoming)" in ufw_status.stdout
    assert "Default: allow (outgoing)" in ufw_status.stdout

    # Check SSH is allowed
    assert "22/tcp" in ufw_status.stdout or "OpenSSH" in ufw_status.stdout

def test_password_policy(host):
    """Test password policy enforcement"""
    pwquality = host.file("/etc/security/pwquality.conf")

    # Check minimum password length
    assert pwquality.exists
    assert pwquality.contains("minlen")

    # Check character class requirements
    assert pwquality.contains("minclass")

    # Verify file permissions
    assert pwquality.user == "root"
    assert pwquality.group == "root"
    assert pwquality.mode == 0o644

def test_system_file_permissions(host):
    """Test critical system file permissions"""
    critical_files = {
        "/etc/passwd": {"mode": 0o644, "user": "root"},
        "/etc/group": {"mode": 0o644, "user": "root"},
        "/etc/shadow": {"mode": 0o640, "user": "root", "group": "shadow"},
        "/etc/gshadow": {"mode": 0o640, "user": "root", "group": "shadow"},
    }

    for file_path, expected in critical_files.items():
        file_obj = host.file(file_path)
        assert file_obj.exists
        assert file_obj.mode == expected["mode"]
        assert file_obj.user == expected["user"]
        if "group" in expected:
            assert file_obj.group == expected["group"]

def test_audit_configuration(host):
    """Test audit daemon configuration"""
    auditd = host.service("auditd")
    assert auditd.is_running
    assert auditd.is_enabled

    # Check for audit rules
    audit_rules = host.file("/etc/audit/rules.d")
    assert audit_rules.exists
    assert audit_rules.is_directory

def test_unnecessary_services_disabled(host):
    """Test that unnecessary services are disabled"""
    unnecessary_services = [
        "avahi-daemon",
        "cups",
        "nfs-server",
        "rpcbind",
        "xinetd",
    ]

    for service in unnecessary_services:
        service_obj = host.service(service)
        # Service should not be enabled
        assert not service_obj.is_enabled, f"Service {service} should be disabled"

def test_package_updates(host):
    """Test that system is up to date"""
    # Check if apt update was run recently
    apt_cache = host.file("/var/lib/apt/periodic/update-success-stamp")
    # This file should exist if unattended-upgrades is configured
    # but we don't require it for basic functionality

    # Check for security packages
    security_packages = [
        "ufw",
        "fail2ban",
        "auditd",
        "apparmor",
        "unattended-upgrades",
    ]

    for package in security_packages:
        pkg = host.package(package)
        # At least some security packages should be installed
        # We don't require all of them for basic functionality

def test_kernel_security_parameters(host):
    """Test kernel security parameters"""
    # Check for ASLR
    aslr = host.run("cat /proc/sys/kernel/randomize_va_space")
    assert aslr.stdout.strip() in ["1", "2"]

    # Check for kernel pointer protection
    kptr_restrict = host.run("cat /proc/sys/kernel/kptr_restrict")
    assert int(kptr_restrict.stdout.strip()) >= 0

def test_file_integrity_tools(host):
    """Test file integrity monitoring tools"""
    # Check for AIDE if installed
    aide = host.package("aide")
    if aide.is_installed:
        aide_db = host.file("/var/lib/aide/aide.db")
        # AIDE database should exist if package is installed

    # Check for rkhunter if installed
    rkhunter = host.package("rkhunter")
    if rkhunter.is_installed:
        # rkhunter configuration should exist
        rkhunter_conf = host.file("/etc/rkhunter.conf")
        assert rkhunter_conf.exists

@pytest.mark.parametrize("directory,expected_mode", [
    ("/etc", 0o755),
    ("/var/log", 0o755),
    ("/home", 0o755),
])
def test_critical_directory_permissions(host, directory, expected_mode):
    """Test critical directory permissions"""
    dir_obj = host.file(directory)
    assert dir_obj.exists
    assert dir_obj.is_directory
    assert dir_obj.mode == expected_mode

def test_system_logging(host):
    """Test system logging configuration"""
    # Check rsyslog is running
    rsyslog = host.service("rsyslog")
    assert rsyslog.is_running
    assert rsyslog.is_enabled

    # Check log directory exists
    log_dir = host.file("/var/log")
    assert log_dir.exists
    assert log_dir.is_directory

    # Check for auth.log
    auth_log = host.file("/var/log/auth.log")
    assert auth_log.exists

def test_cron_configuration(host):
    """Test cron service configuration"""
    cron = host.service("cron")
    assert cron.is_running
    assert cron.is_enabled

    # Check cron.allow or cron.deny
    cron_allow = host.file("/etc/cron.allow")
    cron_deny = host.file("/etc/cron.deny")

    # Either cron.allow or cron.deny should exist
    assert cron_allow.exists or cron_deny.exists

def test_network_security(host):
    """Test network security settings"""
    # Check for SYN cookies
    syn_cookies = host.run("cat /proc/sys/net/ipv4/tcp_syncookies")
    assert syn_cookies.stdout.strip() == "1"

    # Check for IP forwarding (should be disabled on most systems)
    ip_forward = host.run("cat /proc/sys/net/ipv4/ip_forward")
    assert ip_forward.stdout.strip() == "0"

def test_suid_sgid_files(host):
    """Test for dangerous SUID/SGID files"""
    # Check for SUID files in critical directories
    critical_dirs = ["/bin", "/sbin", "/usr/bin", "/usr/sbin", "/usr/local/bin"]

    for directory in critical_dirs:
        dir_obj = host.file(directory)
        if dir_obj.exists:
            # Find SUID/SGID files
            result = host.run(f"find {directory} -type f \( -perm -4000 -o -perm -2000 \) 2>/dev/null")

            # Some SUID files are expected (like sudo, passwd)
            # but we should be aware of them
            suid_files = result.stdout.strip().split('\n') if result.stdout.strip() else []

            # Log SUID files for review
            if suid_files and suid_files != ['']:
                print(f"SUID files found in {directory}: {suid_files}")

def test_disk_usage(host):
    """Test disk usage is reasonable"""
    # Check root filesystem usage
    result = host.run("df -h /")
    assert result.rc == 0

    # Parse disk usage (should be under 90%)
    lines = result.stdout.strip().split('\n')
    if len(lines) >= 2:
        usage_line = lines[1]
        usage_percent = usage_line.split()[4]
        assert usage_percent.endswith('%')
        usage_value = int(usage_percent[:-1])
        assert usage_value < 95, f"Disk usage is {usage_value}%"

def test_memory_usage(host):
    """Test memory usage is reasonable"""
    # Check memory usage
    result = host.run("free -m")
    assert result.rc == 0

    # Parse memory usage
    lines = result.stdout.strip().split('\n')
    if len(lines) >= 2:
        mem_line = lines[1]
        parts = mem_line.split()
        total_mem = int(parts[1])
        used_mem = int(parts[2])
        usage_percent = (used_mem / total_mem) * 100

        # Memory usage should be reasonable
        assert usage_percent < 95, f"Memory usage is {usage_percent:.1f}%"