#!/bin/bash

# Fortress Linux - Installation Script
# This script provides an easy way to install and set up Fortress Linux

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Installation variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_MODE="manual"
ANSIBLE_CONFIG="$SCRIPT_DIR/ansible/ansible.cfg"
INVENTORY_FILE="$SCRIPT_DIR/ansible/inventory/hosts"
REQUIREMENTS_FILE="$SCRIPT_DIR/requirements.txt"
ANSIBLE_REQUIREMENTS="$SCRIPT_DIR/requirements.yml"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root for security reasons."
        exit 1
    fi
}

# Function to check system requirements
check_requirements() {
    print_status "Checking system requirements..."

    # Check OS
    if [[ ! -f /etc/os-release ]]; then
        print_error "Cannot determine operating system"
        exit 1
    fi

    source /etc/os-release
    if [[ "$ID" != "ubuntu" && "$ID" != "debian" ]]; then
        print_warning "This script is designed for Ubuntu/Debian. Other distributions may require manual adjustments."
    fi

    # Check memory
    total_mem=$(free -m | awk 'NR==2{printf "%.0f", $2}')
    if [[ $total_mem -lt 2048 ]]; then
        print_warning "System has less than 2GB RAM. Performance may be affected."
    fi

    # Check disk space
    available_space=$(df -k "$SCRIPT_DIR" | awk 'NR==2 {print $4}')
    if [[ $available_space -lt 10485760 ]]; then # 10GB in KB
        print_error "Insufficient disk space. At least 10GB free space required."
        exit 1
    fi

    print_success "System requirements check passed"
}

# Function to install dependencies
install_dependencies() {
    print_status "Installing dependencies..."

    # Update package list
    sudo apt update

    # Install basic dependencies
    sudo apt install -y \
        git \
        curl \
        wget \
        python3 \
        python3-pip \
        python3-venv \
        python3-dev \
        build-essential \
        software-properties-common

    # Install Ansible if not present
    if ! command -v ansible &> /dev/null; then
        print_status "Installing Ansible..."
        sudo apt install -y ansible
    else
        print_success "Ansible already installed: $(ansible --version | head -n1)"
    fi

    print_success "Dependencies installed successfully"
}

# Function to setup Python virtual environment
setup_venv() {
    print_status "Setting up Python virtual environment..."

    if [[ ! -d "$SCRIPT_DIR/.venv" ]]; then
        python3 -m venv "$SCRIPT_DIR/.venv"
    fi

    source "$SCRIPT_DIR/.venv/bin/activate"

    # Install Python requirements
    if [[ -f "$REQUIREMENTS_FILE" ]]; then
        pip install -r "$REQUIREMENTS_FILE"
    fi

    print_success "Python virtual environment setup completed"
}

# Function to install Ansible collections
install_ansible_collections() {
    print_status "Installing Ansible collections..."

    if [[ -f "$ANSIBLE_REQUIREMENTS" ]]; then
        ansible-galaxy collection install -r "$ANSIBLE_REQUIREMENTS"
    fi

    print_success "Ansible collections installed"
}

# Function to configure Ansible
configure_ansible() {
    print_status "Configuring Ansible..."

    # Copy ansible.cfg if it doesn't exist
    if [[ ! -f "$ANSIBLE_CONFIG" ]]; then
        if [[ -f "$SCRIPT_DIR/config/ansible.cfg" ]]; then
            cp "$SCRIPT_DIR/config/ansible.cfg" "$ANSIBLE_CONFIG"
        fi
    fi

    # Update ansible.cfg with correct paths
    if [[ -f "$ANSIBLE_CONFIG" ]]; then
        sed -i "s|inventory = ./config/hosts|inventory = $INVENTORY_FILE|g" "$ANSIBLE_CONFIG"
        sed -i "s|log_path = ./logs/deployment.log|log_path = $SCRIPT_DIR/logs/deployment.log|g" "$ANSIBLE_CONFIG"
    fi

    print_success "Ansible configuration completed"
}

# Function to setup inventory file
setup_inventory() {
    print_status "Setting up inventory file..."

    if [[ ! -f "$INVENTORY_FILE" ]]; then
        print_warning "Inventory file not found. Creating template..."
        mkdir -p "$SCRIPT_DIR/ansible/inventory"

        cat > "$INVENTORY_FILE" << EOF
# Fortress Linux - Host Inventory File
# Add your target systems below

# Localhost for testing
[localhost]
127.0.0.1 ansible_connection=local ansible_python_interpreter=/usr/bin/python3

# Example remote systems
#[webservers]
#server1 ansible_user=admin ansible_host=192.168.1.10
#server2 ansible_user=admin ansible_host=192.168.1.11

#[databases]
#db1 ansible_user=admin ansible_host=192.168.1.20

[all:vars]
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF
    fi

    print_success "Inventory file setup completed"
}

# Function to test connectivity
test_connectivity() {
    print_status "Testing connectivity..."

    if command -v ansible &> /dev/null; then
        if ansible -i "$INVENTORY_FILE" localhost -m ping -c local; then
            print_success "Connectivity test passed"
        else
            print_warning "Connectivity test failed. Check your inventory file."
        fi
    else
        print_warning "Ansible not available. Skipping connectivity test."
    fi
}

# Function to run security hardening
run_hardening() {
    print_status "Ready to run security hardening..."

    echo "Choose installation mode:"
    echo "1) Manual (Bash script)"
    echo "2) Automated (Ansible playbook)"
    echo "3) Test mode (Dry run)"
    read -p "Enter your choice [1-3]: " choice

    case $choice in
        1)
            print_status "Running manual hardening..."
            if [[ -f "$SCRIPT_DIR/scripts/linux_hardening.sh" ]]; then
                chmod +x "$SCRIPT_DIR/scripts/linux_hardening.sh"
                sudo "$SCRIPT_DIR/scripts/linux_hardening.sh"
            else
                print_error "Hardening script not found!"
                exit 1
            fi
            ;;
        2)
            print_status "Running automated hardening..."
            if [[ -f "$SCRIPT_DIR/ansible/playbooks/playbook_hardening.yml" ]]; then
                ansible-playbook -i "$INVENTORY_FILE" "$SCRIPT_DIR/ansible/playbooks/playbook_hardening.yml"
            else
                print_error "Ansible playbook not found!"
                exit 1
            fi
            ;;
        3)
            print_status "Running in test mode..."
            if [[ -f "$SCRIPT_DIR/ansible/playbooks/playbook_hardening.yml" ]]; then
                ansible-playbook -i "$INVENTORY_FILE" "$SCRIPT_DIR/ansible/playbooks/playbook_hardening.yml" --check
            else
                print_error "Ansible playbook not found!"
                exit 1
            fi
            ;;
        *)
            print_error "Invalid choice!"
            exit 1
            ;;
    esac
}

# Function to create backup
create_backup() {
    print_status "Creating system backup..."

    # Create backup directory
    BACKUP_DIR="$SCRIPT_DIR/backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"

    # Backup important configuration files
    cp -r /etc/ssh "$BACKUP_DIR/" 2>/dev/null || true
    cp -r /etc/ufw "$BACKUP_DIR/" 2>/dev/null || true
    cp -r /etc/auditd "$BACKUP_DIR/" 2>/dev/null || true
    cp /etc/passwd "$BACKUP_DIR/" 2>/dev/null || true
    cp /etc/group "$BACKUP_DIR/" 2>/dev/null || true
    cp /etc/shadow "$BACKUP_DIR/" 2>/dev/null || true

    # Backup current iptables rules if they exist
    if command -v iptables-save &> /dev/null; then
        iptables-save > "$BACKUP_DIR/iptables_rules.txt" 2>/dev/null || true
    fi

    print_success "Backup created at: $BACKUP_DIR"
}

# Function to display help
show_help() {
    cat << EOF
Fortress Linux Installation Script

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -h, --help          Show this help message
    -m, --mode MODE     Installation mode (manual|ansible|test)
    -b, --backup        Create backup before installation
    -s, --skip-deps     Skip dependency installation
    -t, --test          Test mode only (dry run)
    -v, --verbose       Verbose output

EXAMPLES:
    $0                  Interactive installation
    $0 -m manual        Install using manual bash script
    $0 -m ansible       Install using Ansible playbook
    $0 -m test          Test mode (dry run)
    $0 -b -m ansible     Create backup and install with Ansible

For more information, see the documentation in the docs/ directory.
EOF
}

# Main installation function
main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -m|--mode)
                INSTALL_MODE="$2"
                shift 2
                ;;
            -b|--backup)
                CREATE_BACKUP=true
                shift
                ;;
            -s|--skip-deps)
                SKIP_DEPS=true
                shift
                ;;
            -t|--test)
                TEST_MODE=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # Set verbose mode
    if [[ "$VERBOSE" == "true" ]]; then
        set -x
    fi

    print_status "Starting Fortress Linux installation..."
    print_status "Installation directory: $SCRIPT_DIR"

    # Pre-installation checks
    check_root
    check_requirements

    # Create backup if requested
    if [[ "$CREATE_BACKUP" == "true" ]]; then
        create_backup
    fi

    # Install dependencies
    if [[ "$SKIP_DEPS" != "true" ]]; then
        install_dependencies
    fi

    # Setup environment
    setup_venv
    install_ansible_collections
    configure_ansible
    setup_inventory

    # Test connectivity
    test_connectivity

    # Run hardening
    if [[ "$TEST_MODE" == "true" ]]; then
        print_status "Running in test mode..."
        ansible-playbook -i "$INVENTORY_FILE" "$SCRIPT_DIR/ansible/playbooks/playbook_hardening.yml" --check
    elif [[ "$INSTALL_MODE" == "manual" ]]; then
        run_hardening 1
    elif [[ "$INSTALL_MODE" == "ansible" ]]; then
        run_hardening 2
    elif [[ "$INSTALL_MODE" == "test" ]]; then
        run_hardening 3
    else
        run_hardening
    fi

    print_success "Fortress Linux installation completed!"
    print_status "Review the logs in $SCRIPT_DIR/logs/ for details."
    print_status "For configuration options, see $SCRIPT_DIR/docs/ directory."
}

# Run main function
main "$@"