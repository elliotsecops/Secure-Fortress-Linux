#!/bin/bash
# Development environment setup script for Fortress Linux

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=== Fortress Linux Development Environment Setup ==="
echo "Project root: $PROJECT_ROOT"
echo ""

# Check Python version
echo "Checking Python version..."
PYTHON_VERSION=$(python3 --version)
echo "  $PYTHON_VERSION"
echo ""

# Check if Python 3.6+ is available
PYTHON_MAJOR=$(python3 -c 'import sys; print(sys.version_info.major)')
PYTHON_MINOR=$(python3 -c 'import sys; print(sys.version_info.minor)')

if [ "$PYTHON_MAJOR" -lt 3 ] || ([ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -lt 6 ]); then
    echo "Error: Python 3.6+ is required"
    exit 1
fi

# Install Python dependencies
echo "Installing Python dependencies..."
pip3 install --upgrade pip

echo "  Installing test dependencies..."
pip3 install -r "$PROJECT_ROOT/requirements.txt"

echo "  Installing pre-commit..."
pip3 install pre-commit

echo "  Installing ansible-lint..."
pip3 install ansible-lint

echo "  Installing yamllint..."
pip3 install yamllint

echo "  Installing flake8..."
pip3 install flake8

echo "  Installing black..."
pip3 install black

echo "  Installing bandit..."
pip3 install bandit

echo ""
echo "=== Installing pre-commit hooks ==="
cd "$PROJECT_ROOT"
pre-commit install

echo ""
echo "=== Verifying tools ==="

# Verify Ansible is installed
if command -v ansible &> /dev/null; then
    ANSIBLE_VERSION=$(ansible --version | head -n 1)
    echo "✓ Ansible: $ANSIBLE_VERSION"
else
    echo "✗ Ansible not found"
fi

# Verify pytest is installed
if command -v pytest &> /dev/null; then
    PYTEST_VERSION=$(pytest --version)
    echo "✓ pytest: $PYTEST_VERSION"
else
    echo "✗ pytest not found"
fi

# Verify Molecule is installed
if command -v molecule &> /dev/null; then
    MOLECULE_VERSION=$(molecule --version)
    echo "✓ molecule: $MOLECULE_VERSION"
else
    echo "✗ molecule not found"
fi

# Verify Docker is available
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version)
    echo "✓ docker: $DOCKER_VERSION"
else
    echo "✗ docker not found"
fi

echo ""
echo "=== Development environment setup complete ==="
echo ""
echo "Quick commands:"
echo "  Run tests:        cd $PROJECT_ROOT && pytest tests/"
echo "  Run Molecule:     cd $PROJECT_ROOT && molecule test"
echo "  Run pre-commit:    cd $PROJECT_ROOT && pre-commit run --all-files"
echo "  Run ansible-lint:   cd $PROJECT_ROOT && ansible-lint ansible/"
echo "  Run yamllint:     cd $PROJECT_ROOT && yamllint ."
echo ""
echo "For more information, see README.md and CONTRIBUTING.md"
