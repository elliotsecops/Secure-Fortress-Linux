#!/bin/bash
# Pre-commit installation script for Fortress Linux

set -e

echo "=== Installing pre-commit hooks for Fortress Linux ==="

# Check if pre-commit is installed
if ! command -v pre-commit &> /dev/null; then
    echo "Installing pre-commit..."
    pip install pre-commit
fi

# Install pre-commit hooks
echo "Installing pre-commit hooks..."
pre-commit install

echo ""
echo "=== Pre-commit installation complete ==="
echo ""
echo "The following hooks have been installed:"
echo "  - Shell script linting (ShellCheck)"
echo "  - Python formatting (Black)"
echo "  - Python linting (Flake8)"
echo "  - Security checks (Bandit, detect-secrets)"
echo "  - YAML validation (yamllint)"
echo "  - Ansible linting (ansible-lint)"
echo "  - Dockerfile linting (hadolint)"
echo ""
echo "Pre-commit hooks will run automatically on:"
echo "  - git commit"
echo "  - git push (if configured)"
echo ""
echo "To run hooks manually:"
echo "  pre-commit run --all-files"
echo "  pre-commit run --files <file1> <file2>"
echo ""
echo "To update hooks:"
echo "  pre-commit autoupdate"
echo ""
echo "To uninstall hooks:"
echo "  pre-commit uninstall"
