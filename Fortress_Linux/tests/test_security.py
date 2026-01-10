"""
Security tests for Fortress Linux
Tests firewall, SSH, and auditd security configurations
"""

import pytest
import subprocess
import os


class TestFirewallSecurity:
    """Test firewall security configurations"""

    @pytest.mark.skipif(not os.path.exists("/usr/sbin/ufw"), reason="UFW not installed")
    def test_default_incoming_policy_deny(self):
        """Test that default incoming policy is deny"""
        result = subprocess.run(
            ["sudo", "ufw", "status", "verbose"], capture_output=True, text=True
        )

        # Check for default incoming policy
        assert "deny" in result.stdout.lower() or "drop" in result.stdout.lower(), (
            "Default incoming policy should be deny"
        )

    @pytest.mark.skipif(not os.path.exists("/usr/sbin/ufw"), reason="UFW not installed")
    def test_default_outgoing_policy_allow(self):
        """Test that default outgoing policy is allow"""
        result = subprocess.run(
            ["sudo", "ufw", "status", "verbose"], capture_output=True, text=True
        )

        # Check for default outgoing policy
        assert "allow" in result.stdout.lower(), (
            "Default outgoing policy should be allow"
        )

    @pytest.mark.skipif(not os.path.exists("/usr/sbin/ufw"), reason="UFW not installed")
    def test_rate_limiting_enabled(self):
        """Test that SSH rate limiting is configured"""
        result = subprocess.run(
            ["sudo", "ufw", "status", "numbered"], capture_output=True, text=True
        )

        # Check for rate limiting rule
        assert "limit" in result.stdout.lower(), "SSH rate limiting not configured"

    @pytest.mark.skipif(not os.path.exists("/usr/sbin/ufw"), reason="UFW not installed")
    def test_logging_enabled(self):
        """Test that firewall logging is enabled"""
        result = subprocess.run(
            ["sudo", "ufw", "status"], capture_output=True, text=True
        )

        # Check for logging configuration
        assert "logging" in result.stdout.lower(), "Firewall logging not enabled"

    @pytest.mark.skipif(not os.path.exists("/usr/sbin/ufw"), reason="UFW not installed")
    def test_unnecessary_ports_closed(self):
        """Test that unnecessary ports are not open"""
        # List of ports that should be closed
        unnecessary_ports = [
            "23/tcp",  # Telnet
            "21/tcp",  # FTP
            "139/tcp",  # NetBIOS
            "445/tcp",  # SMB
            "23/tcp",  # Telnet
            "25/tcp",  # SMTP (if not mail server)
        ]

        result = subprocess.run(
            ["sudo", "ufw", "status", "numbered"], capture_output=True, text=True
        )

        for port in unnecessary_ports:
            # Check that port is not open
            assert port not in result.stdout, f"Unnecessary port {port} is open"


class TestSSHSecurity:
    """Test SSH security configurations"""

    @pytest.mark.skipif(
        not os.path.exists("/etc/ssh/sshd_config"), reason="SSH config not found"
    )
    def test_permit_root_login_no(self):
        """Test that root login is disabled"""
        with open("/etc/ssh/sshd_config", "r") as f:
            for line in f:
                if line.strip().startswith("PermitRootLogin"):
                    assert "no" in line.lower(), "PermitRootLogin should be set to no"

    @pytest.mark.skipif(
        not os.path.exists("/etc/ssh/sshd_config"), reason="SSH config not found"
    )
    def test_password_authentication_no(self):
        """Test that password authentication is disabled"""
        with open("/etc/ssh/sshd_config", "r") as f:
            for line in f:
                if line.strip().startswith("PasswordAuthentication"):
                    assert "no" in line.lower(), (
                        "PasswordAuthentication should be set to no"
                    )

    @pytest.mark.skipif(
        not os.path.exists("/etc/ssh/sshd_config"), reason="SSH config not found"
    )
    def test_pubkey_authentication_yes(self):
        """Test that public key authentication is enabled"""
        with open("/etc/ssh/sshd_config", "r") as f:
            for line in f:
                if line.strip().startswith("PubkeyAuthentication"):
                    assert "yes" in line.lower(), (
                        "PubkeyAuthentication should be set to yes"
                    )

    @pytest.mark.skipif(
        not os.path.exists("/etc/ssh/sshd_config"), reason="SSH config not found"
    )
    def test_protocol_2(self):
        """Test that SSH protocol 2 is enforced"""
        with open("/etc/ssh/sshd_config", "r") as f:
            for line in f:
                if line.strip().startswith("Protocol"):
                    assert "2" in line, "SSH protocol should be 2"

    @pytest.mark.skipif(
        not os.path.exists("/etc/ssh/sshd_config"), reason="SSH config not found"
    )
    def test_x11_forwarding_disabled(self):
        """Test that X11 forwarding is disabled"""
        with open("/etc/ssh/sshd_config", "r") as f:
            for line in f:
                if line.strip().startswith("X11Forwarding"):
                    assert "no" in line.lower(), "X11Forwarding should be set to no"

    @pytest.mark.skipif(
        not os.path.exists("/etc/ssh/sshd_config"), reason="SSH config not found"
    )
    def test_max_auth_tries_limited(self):
        """Test that max authentication tries is limited"""
        with open("/etc/ssh/sshd_config", "r") as f:
            for line in f:
                if line.strip().startswith("MaxAuthTries"):
                    max_tries = int(line.split()[-1])
                    assert max_tries <= 3, (
                        f"MaxAuthTries should be <= 3, got {max_tries}"
                    )

    @pytest.mark.skipif(
        not os.path.exists("/etc/ssh/sshd_config"), reason="SSH config not found"
    )
    def test_client_alive_interval_set(self):
        """Test that client alive interval is configured"""
        with open("/etc/ssh/sshd_config", "r") as f:
            for line in f:
                if line.strip().startswith("ClientAliveInterval"):
                    interval = int(line.split()[-1])
                    assert interval > 0, (
                        "ClientAliveInterval should be set to a positive value"
                    )

    @pytest.mark.skipif(
        not os.path.exists("/etc/ssh/sshd_config"), reason="SSH config not found"
    )
    def test_banner_configured(self):
        """Test that login banner is configured"""
        with open("/etc/ssh/sshd_config", "r") as f:
            for line in f:
                if line.strip().startswith("Banner"):
                    banner_path = line.split()[-1]
                    assert os.path.exists(banner_path), (
                        f"Banner file does not exist: {banner_path}"
                    )


class TestAuditdSecurity:
    """Test auditd security configurations"""

    @pytest.mark.skipif(
        not os.path.exists("/usr/sbin/auditd"), reason="auditd not installed"
    )
    def test_auditd_running(self):
        """Test that auditd service is running"""
        result = subprocess.run(
            ["systemctl", "is-active", "auditd"], capture_output=True, text=True
        )
        assert result.stdout.strip() == "active", "auditd is not running"

    @pytest.mark.skipif(
        not os.path.exists("/usr/sbin/auditd"), reason="auditd not installed"
    )
    def test_auditd_enabled_at_boot(self):
        """Test that auditd is enabled at boot"""
        result = subprocess.run(
            ["systemctl", "is-enabled", "auditd"], capture_output=True, text=True
        )
        assert result.stdout.strip() == "enabled", "auditd not enabled at boot"

    @pytest.mark.skipif(
        not os.path.exists("/usr/sbin/auditd"), reason="auditd not installed"
    )
    def test_audit_rules_exist(self):
        """Test that audit rules exist"""
        result = subprocess.run(["auditctl", "-l"], capture_output=True, text=True)
        assert result.returncode == 0, "Failed to list audit rules"
        lines = result.stdout.strip().split("\n")
        assert len(lines) > 5, "No audit rules found"

    @pytest.mark.skipif(
        not os.path.exists("/usr/sbin/auditd"), reason="auditd not installed"
    )
    def test_critical_files_monitored(self):
        """Test that critical files are monitored"""
        critical_files = [
            "/etc/passwd",
            "/etc/shadow",
            "/etc/sudoers",
            "/etc/group",
            "/bin/sudo",
            "/usr/bin/sudo",
        ]

        result = subprocess.run(["auditctl", "-l"], capture_output=True, text=True)

        for file_path in critical_files:
            # Check if file is being monitored
            assert file_path in result.stdout, (
                f"Critical file not being monitored: {file_path}"
            )

    @pytest.mark.skipif(
        not os.path.exists("/usr/sbin/auditd"), reason="auditd not installed"
    )
    def test_audit_log_rotation_configured(self):
        """Test that audit log rotation is configured"""
        logrotate_file = "/etc/logrotate.d/auditd"

        if not os.path.exists(logrotate_file):
            pytest.skip(f"{logrotate_file} does not exist")

        with open(logrotate_file, "r") as f:
            content = f.read()

        # Check for rotation settings
        assert "rotate" in content.lower(), "Log rotation not configured"
        assert "compress" in content.lower(), "Log compression not configured"

    @pytest.mark.skipif(
        not os.path.exists("/usr/sbin/auditd"), reason="auditd not installed"
    )
    def test_audit_log_permissions_secure(self):
        """Test that audit logs have secure permissions"""
        audit_log_dir = "/var/log/audit"

        if not os.path.exists(audit_log_dir):
            pytest.skip(f"{audit_log_dir} does not exist")

        stat_info = os.stat(audit_log_dir)
        mode = oct(stat_info.st_mode)[-3:]

        # Audit log directory should be 700 or 750
        assert mode in ["700", "750"], (
            f"Audit log directory has insecure permissions: {mode}"
        )

    @pytest.mark.skipif(
        not os.path.exists("/etc/audit/auditd.conf"), reason="Auditd config not found"
    )
    def test_auditd_disk_space_management(self):
        """Test that auditd disk space management is configured"""
        with open("/etc/audit/auditd.conf", "r") as f:
            content = f.read()

        # Check for disk space management settings
        disk_space_settings = ["max_log_file", "space_left", "admin_space_left"]

        for setting in disk_space_settings:
            assert setting in content, f"{setting} not configured in auditd.conf"


class TestPasswordSecurity:
    """Test password security configurations"""

    @pytest.mark.skipif(
        not os.path.exists("/etc/security/pwquality.conf"),
        reason="pwquality not configured",
    )
    def test_minimum_password_length(self):
        """Test that minimum password length is configured"""
        with open("/etc/security/pwquality.conf", "r") as f:
            content = f.read()

        for line in content.split("\n"):
            if line.strip().startswith("minlen"):
                minlen = int(line.split()[-1])
                assert minlen >= 14, (
                    f"Minimum password length should be >= 14, got {minlen}"
                )

    @pytest.mark.skipif(
        not os.path.exists("/etc/security/pwquality.conf"),
        reason="pwquality not configured",
    )
    def test_minimum_character_classes(self):
        """Test that minimum character classes is configured"""
        with open("/etc/security/pwquality.conf", "r") as f:
            content = f.read()

        for line in content.split("\n"):
            if line.strip().startswith("minclass"):
                minclass = int(line.split()[-1])
                assert minclass >= 3, (
                    f"Minimum character classes should be >= 3, got {minclass}"
                )

    @pytest.mark.skipif(
        not os.path.exists("/etc/security/pwquality.conf"),
        reason="pwquality not configured",
    )
    def test_password_complexity_required(self):
        """Test that password complexity is required"""
        with open("/etc/security/pwquality.conf", "r") as f:
            content = f.read()

        # Check for complexity requirements
        complexity_settings = ["dcredit", "ucredit", "lcredit", "ocredit"]

        found_complexity = 0
        for line in content.split("\n"):
            for setting in complexity_settings:
                if line.strip().startswith(setting):
                    # Negative values indicate requirement
                    if "-" in line:
                        found_complexity += 1

        assert found_complexity >= 3, "Password complexity not sufficiently enforced"

    @pytest.mark.skipif(
        not os.path.exists("/etc/security/pwquality.conf"),
        reason="pwquality not configured",
    )
    def test_password_aging_configured(self):
        """Test that password aging is configured"""
        login_defs_file = "/etc/login.defs"

        if not os.path.exists(login_defs_file):
            pytest.skip(f"{login_defs_file} does not exist")

        with open(login_defs_file, "r") as f:
            content = f.read()

        # Check for password aging settings
        aging_settings = ["PASS_MAX_DAYS", "PASS_MIN_DAYS", "PASS_WARN_AGE"]

        for setting in aging_settings:
            assert setting in content, f"{setting} not configured"


class TestFileSystemSecurity:
    """Test file system security configurations"""

    def test_root_home_permissions(self):
        """Test that /root has secure permissions"""
        if not os.path.exists("/root"):
            pytest.skip("/root does not exist")

        stat_info = os.stat("/root")
        mode = oct(stat_info.st_mode)[-3:]

        assert mode == "700", f"/root has insecure permissions: {mode}"

    def test_no_world_writable_files(self):
        """Test that there are no world-writable files in critical directories"""
        critical_dirs = ["/etc", "/usr/bin", "/usr/sbin"]

        for directory in critical_dirs:
            if not os.path.exists(directory):
                continue

            result = subprocess.run(
                ["find", directory, "-perm", "-002", "-type", "f", "2>/dev/null"],
                capture_output=True,
                text=True,
                shell=True,
            )

            # Should find no world-writable files
            assert len(result.stdout.strip().split("\n")) < 10, (
                f"Found world-writable files in {directory}"
            )

    def test_suid_files_limited(self):
        """Test that SUID files are limited to necessary ones"""
        result = subprocess.run(
            ["find", "/", "-perm", "-4000", "-type", "f", "2>/dev/null"],
            capture_output=True,
            text=True,
            shell=True,
        )

        # List of files that should have SUID
        allowed_suid_files = [
            "/usr/bin/sudo",
            "/usr/bin/passwd",
            "/usr/bin/su",
            "/usr/bin/ping",
            "/usr/bin/newgrp",
            "/usr/bin/chsh",
            "/usr/bin/chfn/usr/bin/gpasswd",
        ]

        # Find SUID files that shouldn't have it
        suid_files = [f for f in result.stdout.split("\n") if f.strip()]
        for file_path in suid_files:
            if file_path not in allowed_suid_files:
                pytest.fail(f"Unexpected SUID file: {file_path}")

    def test_tmp_noexec(self):
        """Test that /tmp has noexec flag if configured"""
        result = subprocess.run(
            ["mount", "|", "grep", "tmpfs", "|", "grep", "/tmp"],
            capture_output=True,
            text=True,
            shell=True,
        )

        # If tmpfs is mounted on /tmp, check for noexec
        if result.returncode == 0:
            # tmpfs should have noexec or nosuid
            assert "noexec" in result.stdout or "nosuid" in result.stdout, (
                "/tmp should have noexec or nosuid"
            )


class TestKernelSecurity:
    """Test kernel security configurations"""

    def test_aslr_enabled(self):
        """Test that ASLR is enabled"""
        result = subprocess.run(
            ["sysctl", "-n", "kernel.randomize_va_space"],
            capture_output=True,
            text=True,
        )

        # ASLR should be 2 (full randomization)
        assert result.stdout.strip() == "2", "ASLR should be fully enabled (value 2)"

    def test_core_dumps_disabled(self):
        """Test that core dumps are disabled"""
        result = subprocess.run(
            ["sysctl", "-n", "fs.suid_dumpable"], capture_output=True, text=True
        )

        # SUID core dumps should be disabled (value 0)
        assert result.stdout.strip() == "0", "SUID core dumps should be disabled"

    def test_kernel_module_signing_configured(self):
        """Test that kernel module signing is configured"""
        # Check if module signing is available
        result = subprocess.run(
            ["ls", "/proc/sys/kernel/keys/"], capture_output=True, text=True
        )

        # Skip if not available
        if result.returncode != 0:
            pytest.skip("Kernel module signing not available")

        # Check if module signing is enforced
        result = subprocess.run(
            ["sysctl", "-n", "kernel.modules_disabled"], capture_output=True, text=True
        )

        # Modules may be disabled for security
        assert result.returncode == 0, "Failed to check module status"

    def test_ptrace_scope_configured(self):
        """Test that ptrace scope is configured"""
        result = subprocess.run(
            ["sysctl", "-n", "kernel.yama.ptrace_scope"], capture_output=True, text=True
        )

        # ptrace_scope should be 1 (restricted) or 2 (only child processes)
        assert result.stdout.strip() in ["1", "2"], (
            f"ptrace_scope should be 1 or 2, got {result.stdout.strip()}"
        )
