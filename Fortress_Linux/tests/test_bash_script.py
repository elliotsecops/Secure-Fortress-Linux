"""
Bash Script Tests for Fortress Linux
Tests the linux_hardening.sh script functionality
"""

import pytest
import testinfra
import subprocess
import tempfile
import os
import stat


class TestBashScript:
    """Test the Linux hardening bash script"""

    @pytest.fixture(scope="class")
    def script_path(self):
        """Return the path to the hardening script"""
        script_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        return os.path.join(script_dir, "scripts", "linux_hardening.sh")

    def test_script_exists(self, script_path):
        """Test that the hardening script exists"""
        assert os.path.exists(script_path), "Hardening script should exist"

    def test_script_executable(self, script_path):
        """Test that the script is executable"""
        file_stat = os.stat(script_path)
        assert stat.S_IMODE(file_stat.st_mode) & stat.S_IXUSR, (
            "Script should be executable by owner"
        )

    def test_script_syntax(self, script_path):
        """Test that the script has valid bash syntax"""
        try:
            result = subprocess.run(
                ["bash", "-n", script_path], capture_output=True, text=True, timeout=10
            )
            assert result.returncode == 0, f"Script has syntax errors: {result.stderr}"
        except subprocess.TimeoutExpired:
            pytest.fail("Script syntax check timed out")

    def test_script_shebang(self, script_path):
        """Test that the script has proper shebang"""
        with open(script_path, "r") as f:
            first_line = f.readline().strip()
        assert first_line == "#!/bin/bash", "Script should start with #!/bin/bash"

    def test_script_security_content(self, script_path):
        """Test that the script contains security-related content"""
        with open(script_path, "r") as f:
            content = f.read()

        # Check for essential security operations
        security_operations = [
            "ufw",
            "firewall",
            "ssh",
            "passwd",
            "shadow",
            "auditd",
            "systemctl",
            "chmod",
            "chown",
        ]

        found_operations = []
        for operation in security_operations:
            if operation in content.lower():
                found_operations.append(operation)

        assert len(found_operations) >= 5, (
            f"Script should contain security operations, found: {found_operations}"
        )

    def test_script_error_handling(self, script_path):
        """Test that the script has proper error handling"""
        with open(script_path, "r") as f:
            content = f.read()

        # Check for error handling patterns
        error_handling = [
            "set -e",
            "set -u",
            "set -o pipefail",
            "||",
            "&&",
            "if",
            "exit",
        ]

        found_handling = []
        for pattern in error_handling:
            if pattern in content:
                found_handling.append(pattern)

        assert len(found_handling) >= 2, (
            f"Script should have error handling, found: {found_handling}"
        )

    def test_script_sudo_usage(self, script_path):
        """Test that the script properly uses sudo for privileged operations"""
        with open(script_path, "r") as f:
            content = f.read()

        # Should use sudo for system-level operations
        sudo_operations = [
            "sudo apt",
            "sudo systemctl",
            "sudo ufw",
            "sudo chmod",
            "sudo chown",
        ]

        found_sudo = []
        for operation in sudo_operations:
            if operation in content.lower():
                found_sudo.append(operation)

        # Should have some sudo operations for system hardening
        assert len(found_sudo) >= 2, (
            f"Script should use sudo for privileged operations, found: {found_sudo}"
        )

    def test_script_backup_operations(self, script_path):
        """Test that the script includes backup operations"""
        with open(script_path, "r") as f:
            content = f.read()

        # Should include backup or safety measures
        backup_patterns = ["backup", "cp", "mv", "before", "original"]

        found_backup = []
        for pattern in backup_patterns:
            if pattern in content.lower():
                found_backup.append(pattern)

        # Should have some backup considerations
        assert len(found_backup) >= 1, (
            f"Script should include backup considerations, found: {found_backup}"
        )

    def test_script_logging(self, script_path):
        """Test that the script includes logging"""
        with open(script_path, "r") as f:
            content = f.read()

        # Should include logging or status messages
        logging_patterns = ["echo", "logger", "log", "status", "info", "warning"]

        found_logging = []
        for pattern in logging_patterns:
            if pattern in content.lower():
                found_logging.append(pattern)

        assert len(found_logging) >= 2, (
            f"Script should include logging, found: {found_logging}"
        )

    def test_script_security_hardening_functions(self, script_path):
        """Test that the script implements specific security hardening functions"""
        with open(script_path, "r") as f:
            content = f.read()

        # Check for specific hardening functions
        hardening_functions = [
            "update",
            "upgrade",
            "ufw",
            "firewall",
            "ssh",
            "password",
            "audit",
            "permission",
        ]

        found_functions = []
        for function in hardening_functions:
            if function in content.lower():
                found_functions.append(function)

        assert len(found_functions) >= 4, (
            f"Script should implement security hardening functions, found: {found_functions}"
        )

    def test_script_configuration_files(self, script_path):
        """Test that the script modifies configuration files properly"""
        with open(script_path, "r") as f:
            content = f.read()

        # Should modify security configuration files
        config_files = [
            "/etc/ssh/sshd_config",
            "/etc/security/pwquality.conf",
            "/etc/audit/rules.d/",
            "/etc/passwd",
            "/etc/shadow",
            "/etc/group",
        ]

        found_configs = []
        for config_file in config_files:
            if config_file in content:
                found_configs.append(config_file)

        assert len(found_configs) >= 3, (
            f"Script should modify configuration files, found: {found_configs}"
        )

    def test_script_service_management(self, script_path):
        """Test that the script manages services properly"""
        with open(script_path, "r") as f:
            content = f.read()

        # Should manage system services
        service_operations = [
            "systemctl enable",
            "systemctl disable",
            "systemctl start",
            "systemctl restart",
            "systemctl status",
        ]

        found_services = []
        for operation in service_operations:
            if operation in content.lower():
                found_services.append(operation)

        assert len(found_services) >= 2, (
            f"Script should manage services, found: {found_services}"
        )

    def test_script_package_management(self, script_path):
        """Test that the script manages packages properly"""
        with open(script_path, "r") as f:
            content = f.read()

        # Should use package management
        package_operations = [
            "apt update",
            "apt upgrade",
            "apt install",
            "apt remove",
            "apt purge",
        ]

        found_packages = []
        for operation in package_operations:
            if operation in content.lower():
                found_packages.append(operation)

        assert len(found_packages) >= 1, (
            f"Script should manage packages, found: {found_packages}"
        )

    def test_script_user_management(self, script_path):
        """Test that the script includes user management considerations"""
        with open(script_path, "r") as f:
            content = f.read()

        # Should include user and group management
        user_operations = ["user", "group", "permission", "chmod", "chown", "chgrp"]

        found_user_mgmt = []
        for operation in user_operations:
            if operation in content.lower():
                found_user_mgmt.append(operation)

        assert len(found_user_mgmt) >= 2, (
            f"Script should include user management, found: {found_user_mgmt}"
        )

    def test_script_network_security(self, script_path):
        """Test that the script includes network security measures"""
        with open(script_path, "r") as f:
            content = f.read()

        # Should include network security
        network_security = [
            "ufw",
            "firewall",
            "iptables",
            "netfilter",
            "network",
            "port",
        ]

        found_network = []
        for security in network_security:
            if security in content.lower():
                found_network.append(security)

        assert len(found_network) >= 2, (
            f"Script should include network security, found: {found_network}"
        )

    def test_script_script_structure(self, script_path):
        """Test that the script has good structure and organization"""
        with open(script_path, "r") as f:
            content = f.read()

        # Should have good structure
        structure_elements = [
            "#",  # Comments
            "echo",  # Status messages
            "if",  # Conditional logic
            "then",  # Conditional blocks
            "fi",  # End conditionals
        ]

        found_structure = []
        for element in structure_elements:
            if element in content.lower():
                found_structure.append(element)

        assert len(found_structure) >= 3, (
            f"Script should have good structure, found: {found_structure}"
        )

    def test_script_safety_measures(self, script_path):
        """Test that the script includes safety measures"""
        with open(script_path, "r") as f:
            content = f.read()

        # Should include safety measures
        safety_measures = ["check", "verify", "test", "validate", "confirm"]

        found_safety = []
        for measure in safety_measures:
            if measure in content.lower():
                found_safety.append(measure)

        assert len(found_safety) >= 1, (
            f"Script should include safety measures, found: {found_safety}"
        )
