"""
Pytest configuration and fixtures for Fortress Linux tests
"""

import pytest
import testinfra
import subprocess
import tempfile
import os

@pytest.fixture(scope="session")
def ssh_config():
    """SSH configuration for remote testing"""
    return {
        'user': 'test',
        'key_file': '~/.ssh/id_rsa_test',
        'timeout': 30
    }

@pytest.fixture(scope="session")
def test_environment():
    """Test environment configuration"""
    return {
        'docker_image': 'ubuntu:22.04',
        'ansible_inventory': 'tests/inventory',
        'molecule_scenario': 'default'
    }

@pytest.fixture(scope="session")
def security_baseline():
    """Security baseline expectations"""
    return {
        'required_services': [
            'ufw',
            'auditd',
            'ssh',
            'rsyslog'
        ],
        'required_packages': [
            'ufw',
            'auditd',
            'apparmor',
            'fail2ban'
        ],
        'required_files': [
            '/etc/ssh/sshd_config',
            '/etc/audit/rules.d/hardening.rules',
            '/etc/security/pwquality.conf'
        ],
        'required_permissions': {
            '/etc/passwd': 0o644,
            '/etc/shadow': 0o640,
            '/etc/group': 0o644
        }
    }

@pytest.fixture(scope="function")
def host():
    """Default test host (localhost)"""
    return testinfra.get_host("local://")

@pytest.fixture(scope="function")
def docker_host(test_environment):
    """Docker test host"""
    docker_image = test_environment['docker_image']
    # This would require docker setup
    # For now, return localhost
    return testinfra.get_host("local://")

@pytest.fixture(scope="session")
def ansible_inventory():
    """Ansible inventory for testing"""
    inventory_path = "/home/elliot/Documents/Reto scripts 30 dias/Fortress_Linux/ansible/inventory/hosts"
    if os.path.exists(inventory_path):
        return inventory_path
    else:
        pytest.skip("Ansible inventory not found")

@pytest.fixture(scope="session")
def ansible_playbook():
    """Ansible playbook for testing"""
    playbook_path = "/home/elliot/Documents/Reto scripts 30 dias/Fortress_Linux/ansible/playbooks/playbook_hardening.yml"
    if os.path.exists(playbook_path):
        return playbook_path
    else:
        pytest.skip("Ansible playbook not found")

@pytest.fixture(scope="session")
def test_output_dir():
    """Test output directory"""
    output_dir = "/tmp/fortress-linux-tests"
    os.makedirs(output_dir, exist_ok=True)
    return output_dir

@pytest.fixture(scope="function", autouse=True)
def test_logger(test_output_dir):
    """Test logger fixture"""
    import logging

    # Setup logging
    log_file = f"{test_output_dir}/test.log"
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler(log_file),
            logging.StreamHandler()
        ]
    )

    logger = logging.getLogger(__name__)

    yield logger

    # Teardown
    logger.info("Test completed")

@pytest.fixture(scope="session")
def security_tools():
    """Security tools configuration"""
    return {
        'bandit_config': {
            'exclude_dirs': ['/tests/', '/.git/'],
            'severity_level': 'medium'
        },
        'safety_config': {
            'ignore_ids': [],
            'severity_threshold': 'medium'
        },
        'trivy_config': {
            'severity': 'CRITICAL,HIGH',
            'format': 'json'
        }
    }

@pytest.fixture(scope="session")
def compliance_standards():
    """Compliance standards configuration"""
    return {
        'cis_benchmark': {
            'level_1': True,
            'level_2': False
        },
        'nist_csf': {
            'identify': True,
            'protect': True,
            'detect': True,
            'respond': False,
            'recover': False
        },
        'iso_27001': {
            'information_security_policies': True,
            'access_control': True,
            'cryptography': True,
            'operations_security': True
        }
    }

@pytest.fixture(scope="function")
def test_container(test_environment):
    """Create a test container for integration tests"""
    # This fixture would create and return a docker container
    # For now, it's a placeholder that would need docker setup
    yield None
    # Cleanup container here

@pytest.fixture(scope="session")
def test_results(test_output_dir):
    """Test results collector"""
    results = {
        'passed': 0,
        'failed': 0,
        'skipped': 0,
        'errors': 0,
        'security_findings': [],
        'compliance_status': {},
        'performance_metrics': {}
    }

    yield results

    # Save results to file
    import json
    results_file = f"{test_output_dir}/test_results.json"
    with open(results_file, 'w') as f:
        json.dump(results, f, indent=2)

def pytest_configure(config):
    """Pytest configuration hook"""
    # Add custom markers
    config.addinivalue_line(
        "markers", "security: marks tests as security-related tests"
    )
    config.addinivalue_line(
        "markers", "compliance: marks tests as compliance-related tests"
    )
    config.addinivalue_line(
        "markers", "performance: marks tests as performance-related tests"
    )
    config.addinivalue_line(
        "markers", "integration: marks tests as integration tests"
    )
    config.addinivalue_line(
        "markers", "unit: marks tests as unit tests"
    )

def pytest_collection_modifyitems(config, items):
    """Modify test collection to add markers"""
    for item in items:
        # Add markers based on test names and paths
        if "security" in item.nodeid.lower():
            item.add_marker(pytest.mark.security)
        if "compliance" in item.nodeid.lower():
            item.add_marker(pytest.mark.compliance)
        if "performance" in item.nodeid.lower():
            item.add_marker(pytest.mark.performance)
        if "integration" in item.nodeid.lower():
            item.add_marker(pytest.mark.integration)
        if "unit" in item.nodeid.lower():
            item.add_marker(pytest.mark.unit)

def pytest_terminal_summary(terminalreporter, exitstatus, config):
    """Custom terminal summary"""
    if exitstatus == 0:
        terminalreporter.ensure_newline()
        terminalreporter.section("Fortress Linux Test Summary", bold=True, sep="=")
        terminalreporter.write_line("✅ All tests passed successfully!")
        terminalreporter.write_line("🛡️  Security hardening validated")
        terminalreporter.write_line("📋 Compliance checks completed")
        terminalreporter.write_line("🚀 Ready for production deployment")
    else:
        terminalreporter.ensure_newline()
        terminalreporter.section("Fortress Linux Test Summary", bold=True, sep="=")
        terminalreporter.write_line("❌ Some tests failed - review output above")
        terminalreporter.write_line("🔧 Address issues before deployment")

# Custom assertions for security testing
def assert_file_secure(host, file_path, expected_mode=None, expected_user=None, expected_group=None):
    """Assert that a file has secure permissions"""
    file_obj = host.file(file_path)

    assert file_obj.exists, f"File {file_path} should exist"

    if expected_mode:
        assert file_obj.mode == expected_mode, f"File {file_path} should have mode {oct(expected_mode)}"

    if expected_user:
        assert file_obj.user == expected_user, f"File {file_path} should be owned by {expected_user}"

    if expected_group:
        assert file_obj.group == expected_group, f"File {file_path} should belong to group {expected_group}"

def assert_service_running(host, service_name):
    """Assert that a service is running and enabled"""
    service = host.service(service_name)
    assert service.is_running, f"Service {service_name} should be running"
    assert service.is_enabled, f"Service {service_name} should be enabled"

def assert_package_installed(host, package_name):
    """Assert that a package is installed"""
    package = host.package(package_name)
    assert package.is_installed, f"Package {package_name} should be installed"

def assert_port_listening(host, port, protocol='tcp'):
    """Assert that a port is listening"""
    assert host.socket(f"{protocol}://{port}").is_listening, f"Port {port}/{protocol} should be listening"

def assert_command_succeeds(host, command):
    """Assert that a command succeeds"""
    result = host.run(command)
    assert result.rc == 0, f"Command '{command}' should succeed, but failed with RC {result.rc}"

def assert_command_fails(host, command):
    """Assert that a command fails"""
    result = host.run(command)
    assert result.rc != 0, f"Command '{command}' should fail, but succeeded with RC {result.rc}"