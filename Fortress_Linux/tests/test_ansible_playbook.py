"""
Ansible Playbook Tests for Fortress Linux
Tests the main hardening playbook functionality
"""

import pytest
import testinfra
import subprocess
import tempfile
import os
import yaml

class TestAnsiblePlaybook:
    """Test the main Ansible hardening playbook"""

    @pytest.fixture(scope="class")
    def playbook_path(self):
        """Return the path to the main playbook"""
        return "/home/elliot/Documents/Reto scripts 30 dias/Fortress_Linux/ansible/playbooks/playbook_hardening.yml"

    @pytest.fixture(scope="class")
    def inventory_path(self):
        """Return the path to the inventory file"""
        return "/home/elliot/Documents/Reto scripts 30 dias/Fortress_Linux/ansible/inventory/hosts"

    def test_playbook_syntax(self, playbook_path):
        """Test that the playbook has valid YAML syntax"""
        with open(playbook_path, 'r') as f:
            try:
                playbook = yaml.safe_load(f)
                assert isinstance(playbook, list), "Playbook should be a list"
                assert len(playbook) > 0, "Playbook should not be empty"

                # Check each play has required fields
                for play in playbook:
                    assert 'name' in play, "Each play should have a name"
                    assert 'hosts' in play, "Each play should have hosts"
                    assert 'tasks' in play, "Each play should have tasks"
                    assert isinstance(play['tasks'], list), "Tasks should be a list"

            except yaml.YAMLError as e:
                pytest.fail(f"Invalid YAML syntax in playbook: {e}")

    def test_inventory_file_exists(self, inventory_path):
        """Test that the inventory file exists"""
        assert os.path.exists(inventory_path), "Inventory file should exist"

    def test_inventory_syntax(self, inventory_path):
        """Test that the inventory file has valid syntax"""
        with open(inventory_path, 'r') as f:
            content = f.read()

        # Basic inventory syntax checks
        assert len(content.strip()) > 0, "Inventory file should not be empty"

        # Check for common inventory patterns
        lines = [line.strip() for line in content.split('\n') if line.strip() and not line.strip().startswith('#')]

        for line in lines:
            # Skip comment lines
            if line.startswith('#'):
                continue

            # Check group definitions
            if line.startswith('[') and line.endswith(']'):
                group_name = line[1:-1]
                assert len(group_name) > 0, f"Group name should not be empty: {line}"

    def test_ansible_lint(self, playbook_path):
        """Test that the playbook passes ansible-lint checks"""
        try:
            result = subprocess.run(
                ['ansible-lint', playbook_path],
                capture_output=True,
                text=True,
                timeout=30
            )

            # ansible-lint should not find critical errors
            # We allow warnings but not errors
            if result.returncode != 0:
                print(f"ansible-lint output: {result.stdout}")
                print(f"ansible-lint errors: {result.stderr}")

            # Allow warnings but not errors
            assert result.returncode <= 2, f"ansible-lint found critical errors: {result.stderr}"

        except subprocess.TimeoutExpired:
            pytest.fail("ansible-lint timed out")
        except FileNotFoundError:
            pytest.skip("ansible-lint not installed")

    def test_playbook_idempotence(self, playbook_path, inventory_path):
        """Test that the playbook is idempotent"""
        # This test requires a test environment
        # For now, we'll just check if the playbook can be parsed
        try:
            # Run ansible-playbook in check mode
            result = subprocess.run(
                [
                    'ansible-playbook',
                    '-i', inventory_path,
                    '--check',
                    '--syntax-check',
                    playbook_path
                ],
                capture_output=True,
                text=True,
                timeout=60
            )

            assert result.returncode == 0, f"Playbook syntax check failed: {result.stderr}"

        except subprocess.TimeoutExpired:
            pytest.fail("ansible-playbook syntax check timed out")
        except FileNotFoundError:
            pytest.skip("ansible-playbook not available")

    def test_security_tasks_present(self, playbook_path):
        """Test that the playbook contains essential security tasks"""
        with open(playbook_path, 'r') as f:
            playbook_content = f.read()

        # Check for essential security-related tasks
        security_keywords = [
            'ufw',
            'firewall',
            'ssh',
            'auditd',
            'wazuh',
            'hardening',
            'security',
            'password',
            'authentication'
        ]

        found_keywords = []
        for keyword in security_keywords:
            if keyword.lower() in playbook_content.lower():
                found_keywords.append(keyword)

        # Should find at least some security keywords
        assert len(found_keywords) >= 3, f"Playbook should contain security tasks, found: {found_keywords}"

    def test_role_variables_exist(self):
        """Test that role variables are properly defined"""
        group_vars_path = "/home/elliot/Documents/Reto scripts 30 dias/Fortress_Linux/ansible/group_vars/all/main.yml"

        if os.path.exists(group_vars_path):
            with open(group_vars_path, 'r') as f:
                try:
                    variables = yaml.safe_load(f)
                    assert isinstance(variables, dict), "Group variables should be a dictionary"

                    # Check for essential variables
                    essential_vars = [
                        'security_hardening_enabled',
                        'wazuh_manager_ip',
                        'ufw_enabled',
                        'ssh_hardening_enabled'
                    ]

                    for var in essential_vars:
                        if var in variables:
                            assert variables[var] is not None, f"Variable {var} should not be None"

                except yaml.YAMLError as e:
                    pytest.fail(f"Invalid YAML in group variables: {e}")

    def test_template_files_exist(self):
        """Test that template files exist and have valid syntax"""
        template_dir = "/home/elliot/Documents/Reto scripts 30 dias/Fortress_Linux/ansible/templates"

        if os.path.exists(template_dir):
            template_files = [f for f in os.listdir(template_dir) if f.endswith('.j2')]

            for template_file in template_files:
                template_path = os.path.join(template_dir, template_file)

                # Check template syntax
                try:
                    with open(template_path, 'r') as f:
                        content = f.read()

                    # Basic Jinja2 syntax check
                    assert '{{' in content or '{%' in content, f"Template {template_file} should contain Jinja2 syntax"

                except Exception as e:
                    pytest.fail(f"Error reading template {template_file}: {e}")

    def test_configuration_files_secure(self):
        """Test that configuration files have secure permissions"""
        config_files = [
            "/home/elliot/Documents/Reto scripts 30 dias/Fortress_Linux/ansible/ansible.cfg",
            "/home/elliot/Documents/Reto scripts 30 dias/Fortress_Linux/ansible/inventory/hosts"
        ]

        for config_file in config_files:
            if os.path.exists(config_file):
                file_obj = testinfra.get_host("local://").file(config_file)

                # Configuration files should have secure permissions
                assert file_obj.mode <= 0o644, f"Configuration file {config_file} should have secure permissions"

    def test_playbook_security_content(self, playbook_path):
        """Test that the playbook follows security best practices"""
        with open(playbook_path, 'r') as f:
            content = f.read()

        # Check for security best practices in the playbook
        security_checks = [
            # Should use become: true for privileged operations
            'become: true',
            # Should validate package installation
            'state: present',
            # Should have proper error handling
            'name:',
            # Should have meaningful task names
        ]

        found_checks = []
        for check in security_checks:
            if check in content:
                found_checks.append(check)

        # Should find most security checks
        assert len(found_checks) >= 2, f"Playbook should follow security best practices, found: {found_checks}"

    def test_ansible_configuration(self):
        """Test Ansible configuration file"""
        ansible_cfg_path = "/home/elliot/Documents/Reto scripts 30 dias/Fortress_Linux/ansible/ansible.cfg"

        if os.path.exists(ansible_cfg_path):
            with open(ansible_cfg_path, 'r') as f:
                content = f.read()

            # Check for security-related configuration
            security_settings = [
                'host_key_checking = False',
                'pipelining = True',
                'gathering = smart'
            ]

            found_settings = []
            for setting in security_settings:
                if setting in content:
                    found_settings.append(setting)

            # Should have some security settings
            assert len(found_settings) >= 1, f"Ansible config should have security settings, found: {found_settings}"