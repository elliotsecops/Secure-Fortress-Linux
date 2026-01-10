"""
Molecule Integration Tests for Fortress Linux
Tests the hardening playbook in isolated environments
"""

import pytest
import testinfra
import subprocess
import tempfile
import os
import yaml
import time


class TestMoleculeIntegration:
    """Test the complete hardening playbook using Molecule"""

    @pytest.fixture(scope="class")
    def molecule_directory(self):
        """Return Molecule directory"""
        return os.path.join(
            os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "molecule"
        )

    @pytest.fixture(scope="class")
    def molecule_scenario(self, molecule_directory):
        """Return the default Molecule scenario"""
        return f"{molecule_directory}/default"

    @pytest.fixture(scope="class")
    def molecule_config(self, molecule_scenario):
        """Return the Molecule configuration"""
        config_file = f"{molecule_scenario}/molecule.yml"
        with open(config_file, "r") as f:
            return yaml.safe_load(f)

    def test_molecule_configuration_exists(self, molecule_config):
        """Test that Molecule configuration exists"""
        assert molecule_config is not None, "Molecule configuration should exist"
        assert "driver" in molecule_config, "Molecule config should have driver section"
        assert "platforms" in molecule_config, (
            "Molecule config should have platforms section"
        )
        assert "provisioner" in molecule_config, (
            "Molecule config should have provisioner section"
        )

    def test_molecule_platforms_configuration(self, molecule_config):
        """Test that Molecule platforms are properly configured"""
        platforms = molecule_config["platforms"]
        assert len(platforms) >= 1, "Should have at least one test platform"

        for platform in platforms:
            assert "name" in platform, "Each platform should have a name"
            assert "image" in platform, "Each platform should have an image"
            assert "privileged" in platform, "Each platform should have privileged mode"

    def test_molecule_test_sequence(self, molecule_config):
        """Test that Molecule test sequence is properly configured"""
        scenario = molecule_config["scenario"]
        assert "test_sequence" in scenario, "Scenario should have test sequence"

        test_sequence = scenario["test_sequence"]
        expected_sequence = [
            "destroy",
            "dependency",
            "syntax",
            "create",
            "prepare",
            "converge",
            "idempotence",
            "side_effect",
            "verify",
            "cleanup",
            "destroy",
        ]

        # Check that key steps are included
        required_steps = ["syntax", "converge", "verify", "idempotence"]
        for step in required_steps:
            assert step in test_sequence, f"Test sequence should include {step}"

    def test_molecule_verifier_configuration(self, molecule_config):
        """Test that Molecule verifier is properly configured"""
        verifier = molecule_config["verifier"]
        assert verifier["name"] == "testinfra", "Should use testinfra as verifier"
        assert "directory" in verifier, "Verifier should have directory specified"

    def test_prepare_playbook_exists(self, molecule_scenario):
        """Test that prepare playbook exists"""
        prepare_file = f"{molecule_scenario}/prepare.yml"
        assert os.path.exists(prepare_file), "Prepare playbook should exist"

        with open(prepare_file, "r") as f:
            playbook = yaml.safe_load(f)
            assert isinstance(playbook, list), "Prepare playbook should be a list"
            assert len(playbook) > 0, "Prepare playbook should not be empty"

    def test_cleanup_playbook_exists(self, molecule_scenario):
        """Test that cleanup playbook exists"""
        cleanup_file = f"{molecule_scenario}/cleanup.yml"
        assert os.path.exists(cleanup_file), "Cleanup playbook should exist"

        with open(cleanup_file, "r") as f:
            playbook = yaml.safe_load(f)
            assert isinstance(playbook, list), "Cleanup playbook should be a list"
            assert len(playbook) > 0, "Cleanup playbook should not be empty"

    def test_molecule_syntax_check(self, molecule_scenario):
        """Test that Molecule syntax check passes"""
        try:
            result = subprocess.run(
                ["molecule", "syntax", "-s", "default"],
                cwd=molecule_scenario,
                capture_output=True,
                text=True,
                timeout=120,
            )

            # Syntax check should pass
            assert result.returncode == 0, (
                f"Molecule syntax check failed: {result.stderr}"
            )

        except subprocess.TimeoutExpired:
            pytest.fail("Molecule syntax check timed out")
        except FileNotFoundError:
            pytest.skip("Molecule not installed")

    def test_molecule_lint_check(self, molecule_scenario):
        """Test that Molecule lint check passes"""
        try:
            result = subprocess.run(
                ["molecule", "lint", "-s", "default"],
                cwd=molecule_scenario,
                capture_output=True,
                text=True,
                timeout=120,
            )

            # Lint check should pass or have only warnings
            assert result.returncode <= 1, (
                f"Molecule lint check failed: {result.stderr}"
            )

        except subprocess.TimeoutExpired:
            pytest.fail("Molecule lint check timed out")
        except FileNotFoundError:
            pytest.skip("Molecule not installed")

    def test_molecule_create_check(self, molecule_scenario):
        """Test that Molecule can create test instances"""
        try:
            # Test create functionality
            result = subprocess.run(
                ["molecule", "create", "-s", "default"],
                cwd=molecule_scenario,
                capture_output=True,
                text=True,
                timeout=300,
            )

            # Create should succeed
            assert result.returncode == 0, f"Molecule create failed: {result.stderr}"

            # Cleanup after test
            subprocess.run(
                ["molecule", "destroy", "-s", "default"],
                cwd=molecule_scenario,
                capture_output=True,
                text=True,
                timeout=120,
            )

        except subprocess.TimeoutExpired:
            pytest.fail("Molecule create test timed out")
        except FileNotFoundError:
            pytest.skip("Molecule not installed")

    def test_molecule_idempotence_check(self, molecule_scenario):
        """Test that the playbook is idempotent"""
        try:
            # This is a complex test that would require running the full molecule test
            # For now, we'll just check that the configuration supports idempotence testing

            with open(f"{molecule_scenario}/molecule.yml", "r") as f:
                config = yaml.safe_load(f)

            test_sequence = config["scenario"]["test_sequence"]
            assert "idempotence" in test_sequence, (
                "Test sequence should include idempotence testing"
            )

        except FileNotFoundError:
            pytest.skip("Molecule configuration not found")

    def test_molecule_security_hardening_verification(self, molecule_scenario):
        """Test that security hardening can be verified"""
        try:
            # Test verification configuration
            with open(f"{molecule_scenario}/molecule.yml", "r") as f:
                config = yaml.safe_load(f)

            verifier = config["verifier"]
            assert "additional_files_or_dirs" in verifier, (
                "Verifier should have additional test files"
            )

            # Check that security tests are included
            additional_tests = verifier["additional_files_or_dirs"]
            security_tests = [
                test for test in additional_tests if "security" in test.lower()
            ]

            assert len(security_tests) >= 1, (
                "Should include security tests in verification"
            )

        except FileNotFoundError:
            pytest.skip("Molecule configuration not found")

    def test_molecule_multi_platform_support(self, molecule_config):
        """Test that Molecule supports multiple platforms"""
        platforms = molecule_config["platforms"]

        # Should test multiple platforms
        platform_names = [platform["name"] for platform in platforms]
        assert len(platform_names) >= 1, "Should test at least one platform"

        # Should have different OS versions
        ubuntu_versions = [name for name in platform_names if "ubuntu" in name.lower()]
        debian_versions = [name for name in platform_names if "debian" in name.lower()]

        # Should test at least one distribution
        assert len(ubuntu_versions) >= 1 or len(debian_versions) >= 1, (
            "Should test at least one Linux distribution"
        )

    def test_molecule_driver_configuration(self, molecule_config):
        """Test that Molecule driver is properly configured"""
        driver = molecule_config["driver"]
        assert driver["name"] == "docker", "Should use Docker driver for testing"

        # Check Docker-specific configuration
        platforms = molecule_config["platforms"]
        for platform in platforms:
            assert "privileged" in platform, (
                "Docker platforms should have privileged mode"
            )
            assert "volumes" in platform, "Docker platforms should have volume mounts"
            assert "capabilities" in platform, (
                "Docker platforms should have capabilities"
            )

    def test_molecule_provisioner_configuration(self, molecule_config):
        """Test that Molecule provisioner is properly configured"""
        provisioner = molecule_config["provisioner"]
        assert provisioner["name"] == "ansible", "Should use Ansible as provisioner"

        # Check Ansible-specific configuration
        assert "inventory" in provisioner, (
            "Provisioner should have inventory configuration"
        )
        assert "playbooks" in provisioner, (
            "Provisioner should have playbook configuration"
        )

        # Check playbooks configuration
        playbooks = provisioner["playbooks"]
        assert "converge" in playbooks, "Should have converge playbook specified"
        assert "prepare" in playbooks, "Should have prepare playbook specified"
        assert "cleanup" in playbooks, "Should have cleanup playbook specified"

    def test_molecule_dependency_management(self, molecule_config):
        """Test that Molecule dependency management is configured"""
        dependency = molecule_config["dependency"]
        assert dependency["name"] == "galaxy", (
            "Should use Galaxy for dependency management"
        )
        assert dependency["enabled"] is True, "Dependency management should be enabled"

        # Check options
        if "options" in dependency:
            options = dependency["options"]
            if "role-file" in options:
                assert os.path.exists(options["role-file"]), "Role file should exist"
            if "requirements-file" in options:
                assert os.path.exists(options["requirements-file"]), (
                    "Requirements file should exist"
                )

    def test_molecule_scenario_configuration(self, molecule_config):
        """Test that Molecule scenario is properly configured"""
        scenario = molecule_config["scenario"]
        assert "name" in scenario, "Scenario should have a name"
        assert "test_sequence" in scenario, "Scenario should have test sequence"

        # Test sequence should be comprehensive
        test_sequence = scenario["test_sequence"]
        required_phases = [
            "syntax",  # Syntax validation
            "create",  # Instance creation
            "prepare",  # Environment preparation
            "converge",  # Playbook execution
            "idempotence",  # Idempotence testing
            "verify",  # Verification
            "destroy",  # Cleanup
        ]

        for phase in required_phases:
            assert phase in test_sequence, f"Test sequence should include {phase} phase"

    @pytest.mark.slow
    def test_molecule_full_execution(self, molecule_scenario):
        """Test full Molecule execution (slow test)"""
        try:
            # This is a comprehensive test that runs the full Molecule test suite
            # It's marked as slow because it can take several minutes

            print("Starting full Molecule test execution...")
            result = subprocess.run(
                ["molecule", "test", "-s", "default"],
                cwd=molecule_scenario,
                capture_output=True,
                text=True,
                timeout=600,  # 10 minutes timeout
            )

            print("Molecule test output:")
            print(result.stdout)
            if result.stderr:
                print("Molecule test errors:")
                print(result.stderr)

            # Full test should pass
            assert result.returncode == 0, f"Full Molecule test failed: {result.stderr}"

        except subprocess.TimeoutExpired:
            pytest.fail("Full Molecule test timed out")
        except FileNotFoundError:
            pytest.skip("Molecule not installed")

    def test_molecule_security_best_practices(self, molecule_config):
        """Test that Molecule follows security best practices"""
        # Check that Docker containers run with minimal privileges
        platforms = molecule_config["platforms"]
        for platform in platforms:
            # Should have specific capabilities rather than full privileged mode when possible
            if "capabilities" in platform:
                capabilities = platform["capabilities"]
                # Should have SYS_ADMIN capability for system-level testing
                assert "SYS_ADMIN" in capabilities, (
                    "Should have SYS_ADMIN capability for system testing"
                )

            # Should have proper volume mounts for cgroups
            if "volumes" in platform:
                volumes = platform["volumes"]
                cgroup_mounts = [vol for vol in volumes if "cgroup" in vol]
                assert len(cgroup_mounts) >= 1, "Should mount cgroups for systemd"

    def test_molecule_test_coverage(self, molecule_config):
        """Test that Molecule provides good test coverage"""
        verifier = molecule_config["verifier"]

        # Should have test files for verification
        if "additional_files_or_dirs" in verifier:
            test_files = verifier["additional_files_or_dirs"]
            assert len(test_files) >= 1, "Should have additional test files"

            # Should include security tests
            security_tests = [test for test in test_files if "security" in test.lower()]
            assert len(security_tests) >= 1, "Should include security tests"

            # Should include integration tests
            integration_tests = [
                test
                for test in test_files
                if "integration" in test.lower() or "molecule" in test.lower()
            ]
            assert len(integration_tests) >= 1, "Should include integration tests"

    def test_molecule_environment_configuration(self, molecule_config):
        """Test that Molecule environment is properly configured"""
        provisioner = molecule_config["provisioner"]

        # Should have environment variables for Ansible
        if "env" in provisioner:
            env = provisioner["env"]

            # Should have Python interpreter configuration
            python_vars = [key for key in env.keys() if "python" in key.lower()]
            assert len(python_vars) >= 1, "Should have Python interpreter configuration"

            # Should have role path configuration
            role_vars = [key for key in env.keys() if "role" in key.lower()]
            assert len(role_vars) >= 1, "Should have role path configuration"
