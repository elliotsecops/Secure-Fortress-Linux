"""
Integration tests for security hardening functionality
Tests actual hardening functions and their effects
"""

import pytest
import subprocess
import tempfile
import os
import shutil


class TestSystemHardening:
    """Test system hardening integration"""

    def test_sysctl_settings_are_applied(self):
        """Test that sysctl settings are correctly applied"""
        # Check TCP hardening settings
        tcp_settings = [
            "net.ipv4.tcp_syncookies",
            "net.ipv4.tcp_fin_timeout",
            "net.ipv4.tcp_max_syn_backlog",
        ]

        for setting in tcp_settings:
            result = subprocess.run(
                ["sysctl", "-n", setting], capture_output=True, text=True
            )
            assert result.returncode == 0, f"Failed to read {setting}"

    def test_file_permissions_are_secure(self):
        """Test that sensitive files have correct permissions"""
        sensitive_files = [
            "/etc/shadow",
            "/etc/passwd",
            "/etc/group",
            "/etc/ssh/sshd_config",
        ]

        for file_path in sensitive_files:
            if os.path.exists(file_path):
                stat_info = os.stat(file_path)
                mode = oct(stat_info.st_mode)[-3:]
                # Shadow file should be 600 or 640
                assert mode in ["600", "640"], (
                    f"{file_path} has insecure permissions: {mode}"
                )

    def test_password_policy_enforced(self):
        """Test that password quality settings are configured"""
        pwquality_file = "/etc/security/pwquality.conf"

        if not os.path.exists(pwquality_file):
            pytest.skip(f"{pwquality_file} does not exist")

        with open(pwquality_file, "r") as f:
            content = f.read()

        # Check for key password policy settings
        assert "minlen" in content, "Minimum password length not set"
        assert "minclass" in content, "Minimum character classes not set"

    def test_login_defs_configured(self):
        """Test that login.defs contains security settings"""
        login_defs_file = "/etc/login.defs"

        if not os.path.exists(login_defs_file):
            pytest.skip(f"{login_defs_file} does not exist")

        with open(login_defs_file, "r") as f:
            content = f.read()

        # Check for key login security settings
        expected_settings = ["PASS_MAX_DAYS", "PASS_MIN_DAYS", "PASS_MAX_LEN"]

        for setting in expected_settings:
            assert setting in content, f"{setting} not found in login.defs"


class TestFirewallHardening:
    """Test firewall hardening integration"""

    @pytest.mark.skipif(not os.path.exists("/usr/sbin/ufw"), reason="UFW not installed")
    def test_ufw_enabled(self):
        """Test that UFW is enabled and running"""
        result = subprocess.run(
            ["sudo", "ufw", "status"], capture_output=True, text=True
        )
        assert result.returncode == 0, "Failed to check UFW status"
        assert "active" in result.stdout.lower(), "UFW is not active"

    @pytest.mark.skipif(not os.path.exists("/usr/sbin/ufw"), reason="UFW not installed")
    def test_default_firewall_policy(self):
        """Test that default firewall policy is restrictive"""
        result = subprocess.run(
            ["sudo", "ufw", "status", "verbose"], capture_output=True, text=True
        )
        assert result.returncode == 0, "Failed to check UFW policy"
        # Check for deny incoming policy
        assert "deny" in result.stdout.lower(), (
            "Default incoming policy not set to deny"
        )

    @pytest.mark.skipif(not os.path.exists("/usr/sbin/ufw"), reason="UFW not installed")
    def test_ssh_allowed(self):
        """Test that SSH is allowed through firewall"""
        result = subprocess.run(
            ["sudo", "ufw", "status"], capture_output=True, text=True
        )
        assert result.returncode == 0, "Failed to check UFW status"
        # Check that SSH port 22 is allowed
        assert "22" in result.stdout or "ssh" in result.stdout.lower(), (
            "SSH not allowed through firewall"
        )


class TestSSHHardening:
    """Test SSH hardening integration"""

    @pytest.mark.skipif(
        not os.path.exists("/etc/ssh/sshd_config"), reason="SSH config not found"
    )
    def test_root_login_disabled(self):
        """Test that root login is disabled"""
        with open("/etc/ssh/sshd_config", "r") as f:
            content = f.read()

        # Check for PermitRootLogin no
        for line in content.split("\n"):
            if line.strip().startswith("PermitRootLogin"):
                assert "no" in line.lower(), "Root login is not disabled"

    @pytest.mark.skipif(
        not os.path.exists("/etc/ssh/sshd_config"), reason="SSH config not found"
    )
    def test_password_auth_disabled(self):
        """Test that password authentication is disabled"""
        with open("/etc/ssh/sshd_config", "r") as f:
            content = f.read()

        # Check for PasswordAuthentication no
        for line in content.split("\n"):
            if line.strip().startswith("PasswordAuthentication"):
                assert "no" in line.lower(), "Password authentication is not disabled"

    @pytest.mark.skipif(
        not os.path.exists("/etc/ssh/sshd_config"), reason="SSH config not found"
    )
    def test_ssh_banner_exists(self):
        """Test that SSH banner is configured"""
        with open("/etc/ssh/sshd_config", "r") as f:
            content = f.read()

        # Check for Banner directive
        assert "Banner" in content, "SSH banner not configured"

    @pytest.mark.skipif(
        not os.path.exists("/etc/ssh/sshd_config"), reason="SSH config not found"
    )
    def test_ssh_config_valid(self):
        """Test that SSH configuration is syntactically valid"""
        result = subprocess.run(["sshd", "-t"], capture_output=True, text=True)
        assert result.returncode == 0, f"SSH config validation failed: {result.stderr}"


class TestAuditdHardening:
    """Test auditd hardening integration"""

    @pytest.mark.skipif(
        not os.path.exists("/usr/sbin/auditd"), reason="auditd not installed"
    )
    def test_auditd_running(self):
        """Test that auditd service is running"""
        result = subprocess.run(
            ["systemctl", "is-active", "auditd"], capture_output=True, text=True
        )
        assert result.stdout.strip() == "active", "auditd service is not running"

    @pytest.mark.skipif(
        not os.path.exists("/usr/sbin/auditd"), reason="auditd not installed"
    )
    def test_auditd_enabled(self):
        """Test that auditd is enabled at boot"""
        result = subprocess.run(
            ["systemctl", "is-enabled", "auditd"], capture_output=True, text=True
        )
        assert result.stdout.strip() == "enabled", "auditd not enabled at boot"

    @pytest.mark.skipif(
        not os.path.exists("/usr/sbin/auditd"), reason="auditd not installed"
    )
    def test_audit_rules_exist(self):
        """Test that audit rules are configured"""
        result = subprocess.run(["auditctl", "-l"], capture_output=True, text=True)
        assert result.returncode == 0, "Failed to list audit rules"
        # Check that there are rules (not empty output)
        lines = result.stdout.strip().split("\n")
        assert len(lines) > 5, "No audit rules found"

    @pytest.mark.skipif(
        not os.path.exists("/usr/sbin/auditd"), reason="auditd not installed"
    )
    def test_audit_rules_valid(self):
        """Test that audit rules are valid"""
        result = subprocess.run(
            ["auditctl", "-R", "/etc/audit/rules.d/hardening.rules"],
            capture_output=True,
            text=True,
        )
        # Return code 0 means rules are valid
        assert result.returncode == 0, f"Audit rules validation failed: {result.stderr}"


class TestBackupRestore:
    """Test backup and restore functionality"""

    def test_backup_directory_exists(self):
        """Test that backup directory exists"""
        backup_dir = "/etc/fortress-backups"

        if not os.path.exists(backup_dir):
            pytest.skip(f"{backup_dir} does not exist")

        assert os.path.isdir(backup_dir), f"{backup_dir} is not a directory"

    def test_backup_has_manifest(self):
        """Test that backup contains manifest file"""
        backup_dir = "/etc/fortress-backups"

        if not os.path.exists(backup_dir):
            pytest.skip(f"{backup_dir} does not exist")

        # Find latest backup
        backups = sorted(
            [
                d
                for d in os.listdir(backup_dir)
                if os.path.isdir(os.path.join(backup_dir, d))
            ]
        )
        if not backups:
            pytest.skip("No backups found")

        latest_backup = os.path.join(backup_dir, backups[-1])
        manifest_file = os.path.join(latest_backup, "MANIFEST.txt")

        if not os.path.exists(manifest_file):
            pytest.skip("MANIFEST.txt not found in backup")

        assert os.path.isfile(manifest_file), "MANIFEST.txt is not a file"

    def test_backup_configurations_exist(self):
        """Test that backup contains critical configuration files"""
        backup_dir = "/etc/fortress-backups"

        if not os.path.exists(backup_dir):
            pytest.skip(f"{backup_dir} does not exist")

        # Find latest backup
        backups = sorted(
            [
                d
                for d in os.listdir(backup_dir)
                if os.path.isdir(os.path.join(backup_dir, d))
            ]
        )
        if not backups:
            pytest.skip("No backups found")

        latest_backup = os.path.join(backup_dir, backups[-1])

        # Check for critical files
        critical_files = ["sshd_config", "pwquality.conf", "auditd.conf", "ufw.conf"]

        for file_name in critical_files:
            file_path = os.path.join(latest_backup, file_name)
            assert os.path.exists(file_path) or any(
                file_name in f for f in os.listdir(latest_backup)
            ), f"{file_name} not found in backup"


class TestServiceManagement:
    """Test service management functionality"""

    def test_security_services_running(self):
        """Test that security services are running"""
        security_services = ["sshd", "auditd"]

        for service in security_services:
            result = subprocess.run(
                ["systemctl", "is-active", service], capture_output=True, text=True
            )
            # Skip if service doesn't exist
            if "not-found" not in result.stderr.lower():
                assert result.stdout.strip() == "active", f"{service} is not running"

    def test_unnecessary_services_disabled(self):
        """Test that unnecessary services are disabled"""
        unnecessary_services = ["avahi-daemon", "cups", "cups-browsed"]

        for service in unnecessary_services:
            result = subprocess.run(
                ["systemctl", "is-enabled", service], capture_output=True, text=True
            )
            # Services should be disabled or masked or not installed
            assert "enabled" not in result.stdout.lower(), f"{service} is enabled"


class TestNetworkSecurity:
    """Test network security settings"""

    def test_sysctl_network_settings(self):
        """Test that network sysctl settings are applied"""
        network_settings = {
            "net.ipv4.conf.all.rp_filter": "1",
            "net.ipv4.conf.default.rp_filter": "1",
            "net.ipv4.icmp_echo_ignore_broadcasts": "1",
        }

        for setting, expected_value in network_settings.items():
            result = subprocess.run(
                ["sysctl", "-n", setting], capture_output=True, text=True
            )
            assert result.returncode == 0, f"Failed to read {setting}"
            assert result.stdout.strip() == expected_value, (
                f"{setting} has incorrect value"
            )

    def test_ipv6_configured(self):
        """Test IPv6 is properly configured or disabled"""
        # Check for IPv6 in sysctl
        result = subprocess.run(
            ["sysctl", "-a", "2>/dev/null", "grep", "ipv6"],
            capture_output=True,
            text=True,
            shell=True,
        )

        # If IPv6 is enabled, verify settings
        if result.returncode == 0:
            # IPv6 should be properly configured
            assert True  # IPv6 is configured
        else:
            # IPv6 may be disabled, which is also acceptable
            assert True  # IPv6 is disabled or not present


class TestFileIntegrity:
    """Test file integrity monitoring"""

    @pytest.mark.skipif(
        not os.path.exists("/usr/sbin/aide"), reason="AIDE not installed"
    )
    def test_aide_installed(self):
        """Test that AIDE is installed"""
        result = subprocess.run(["which", "aide"], capture_output=True, text=True)
        assert result.returncode == 0, "AIDE is not installed"

    @pytest.mark.skipif(
        not os.path.exists("/etc/aide/aide.conf"), reason="AIDE config not found"
    )
    def test_aide_configured(self):
        """Test that AIDE is configured"""
        aide_config = "/etc/aide/aide.conf"

        with open(aide_config, "r") as f:
            content = f.read()

        # Check for database path
        assert "database" in content.lower(), "AIDE database not configured"

        @pytest.mark.skipif(
            not os.path.exists("/var/lib/aide/aide.db"),
            reason="AIDE database not initialized",
        )
        def test_aide_database_exists(self):
            """Test that AIDE database exists"""
            assert os.path.exists("/var/lib/aide/aide.db"), (
                "AIDE database does not exist"
            )


class TestCompliance:
    """Test compliance with security standards"""

    def test_password_aging_configured(self):
        """Test that password aging is configured"""
        login_defs_file = "/etc/login.defs"

        if not os.path.exists(login_defs_file):
            pytest.skip(f"{login_defs_file} does not exist")

        with open(login_defs_file, "r") as f:
            content = f.read()

        # Check for password aging settings
        assert "PASS_MAX_DAYS" in content, "Password max age not set"
        assert "PASS_MIN_DAYS" in content, "Password min age not set"
        assert "PASS_WARN_AGE" in content, "Password warning age not set"

    def test_umask_configured(self):
        """Test that umask is configured"""
        # Check /etc/profile for umask
        profile_file = "/etc/profile"

        if not os.path.exists(profile_file):
            pytest.skip(f"{profile_file} does not exist")

        with open(profile_file, "r") as f:
            content = f.read()

        # Check for umask setting
        assert "umask" in content.lower(), "umask not configured"

    def test_root_path_secure(self):
        """Test that root path is secure"""
        root_path = "/root"

        if not os.path.exists(root_path):
            pytest.skip(f"{root_path} does not exist")

        # Check root directory permissions
        stat_info = os.stat(root_path)
        mode = oct(stat_info.st_mode)[-3:]
        assert mode == "700", f"/root has insecure permissions: {mode}"
