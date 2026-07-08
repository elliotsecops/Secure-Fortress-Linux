#!/bin/bash

# Fortress Linux - Installation Script
# This script provides an easy way to install and set up Fortress Linux

set -euo pipefail

# Source UX core library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/scripts/ux_core.sh" || {
    echo "ERROR: Failed to load ux_core.sh"
    exit 1
}

# Installation variables
INSTALL_MODE="manual"
CREATE_BACKUP="false"
SKIP_DEPS="false"
TEST_MODE="false"
ANSIBLE_CONFIG="$SCRIPT_DIR/ansible/ansible.cfg"
INVENTORY_FILE="$SCRIPT_DIR/ansible/inventory/hosts"
REQUIREMENTS_FILE="$SCRIPT_DIR/requirements.txt"
ANSIBLE_REQUIREMENTS="$SCRIPT_DIR/requirements.yml"

# Function to check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        show_error "This script should not be run as root" "Run as regular user, script will use sudo where needed" ""
        exit 1
    fi
}

# Function to check system requirements
check_requirements() {
    print_section "System Requirements Check"
    
    # Check OS
    if [[ ! -f /etc/os-release ]]; then
        show_error "Cannot determine operating system" "Ensure /etc/os-release exists" ""
        exit 1
    fi
    
    source /etc/os-release
    if [[ "$ID" != "ubuntu" && "$ID" != "debian" ]]; then
        log_warning "This script is designed for Ubuntu/Debian. Other distributions may require manual adjustments."
    fi
    
    # Check memory
    total_mem=$(free -m | awk 'NR==2{printf "%.0f", $2}')
    if [[ $total_mem -lt 2048 ]]; then
        log_warning "System has less than 2GB RAM. Performance may be affected."
    fi
    
    # Check disk space
    available_space=$(df -k "$SCRIPT_DIR" | awk 'NR==2 {print $4}')
    if [[ $available_space -lt 10485760 ]]; then # 10GB in KB
        show_error "Insufficient disk space" "At least 10GB free space required. Check: df -h" ""
        exit 1
    fi
    
    log_success "System requirements check passed"
    echo
}

# Function to install dependencies
install_dependencies() {
    start_spinner "Updating package list"
    sudo apt update -qq
    stop_spinner "success" "Package list updated"

    start_spinner "Installing basic dependencies"
    sudo apt install -y -qq \
        git \
        curl \
        wget \
        python3 \
        python3-pip \
        python3-venv \
        python3-dev \
        build-essential \
        software-properties-common
    stop_spinner "success" "Basic dependencies installed"
    
    # Install Ansible if not present
    if ! command -v ansible &> /dev/null; then
        start_spinner "Installing Ansible"
        sudo apt install -y -qq ansible
        stop_spinner "success" "Ansible installed"
    else
        log_success "Ansible already installed: $(ansible --version | head -n1)"
    fi
    
    log_success "Dependencies installed successfully"
    echo
}

# Function to setup Python virtual environment
setup_venv() {
    if [[ ! -d "$SCRIPT_DIR/.venv" ]]; then
        start_spinner "Creating Python virtual environment"
        python3 -m venv "$SCRIPT_DIR/.venv"
        stop_spinner "success" "Virtual environment created"
    else
        log_verbose "Virtual environment already exists"
    fi
    
    source "$SCRIPT_DIR/.venv/bin/activate"
    
    # Install Python requirements
    if [[ -f "$REQUIREMENTS_FILE" ]]; then
        start_spinner "Installing Python requirements"
        pip install -r "$REQUIREMENTS_FILE" -qq
        stop_spinner "success" "Python requirements installed"
    fi
    
    log_success "Python virtual environment setup completed"
    echo
}

# Function to install Ansible collections
install_ansible_collections() {
    if [[ -f "$ANSIBLE_REQUIREMENTS" ]]; then
        start_spinner "Installing Ansible collections"
        ansible-galaxy collection install -r "$ANSIBLE_REQUIREMENTS" -qq
        stop_spinner "success" "Ansible collections installed"
        echo
    fi
}

# Function to configure Ansible
configure_ansible() {
    # Copy ansible.cfg if it doesn't exist
    if [[ ! -f "$ANSIBLE_CONFIG" ]]; then
        if [[ -f "$SCRIPT_DIR/config/ansible.cfg" ]]; then
            cp "$SCRIPT_DIR/config/ansible.cfg" "$ANSIBLE_CONFIG"
            log_verbose "Copied ansible.cfg template"
        fi
    fi
    
    # Update ansible.cfg with correct paths
    if [[ -f "$ANSIBLE_CONFIG" ]]; then
        sed -i "s|inventory = ./config/hosts|inventory = $INVENTORY_FILE|g" "$ANSIBLE_CONFIG"
        sed -i "s|log_path = ./logs/deployment.log|log_path = $SCRIPT_DIR/logs/deployment.log|g" "$ANSIBLE_CONFIG"
        log_success "Ansible configuration completed"
    fi
}

# Function to setup inventory file
setup_inventory() {
    if [[ ! -f "$INVENTORY_FILE" ]]; then
        log_warning "Inventory file not found. Creating template..."
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
        log_success "Inventory file setup completed"
    else
        log_verbose "Inventory file already exists"
    fi
}

# Function to test connectivity
test_connectivity() {
    if command -v ansible &> /dev/null; then
        start_spinner "Testing connectivity"
        if ansible -i "$INVENTORY_FILE" localhost -m ping -c local >/dev/null 2>&1; then
            stop_spinner "success" "Connectivity test passed"
            echo
        else
            stop_spinner "warning" "Connectivity test failed"
            log_warning "Check your inventory file configuration"
            echo
        fi
    else
        log_warning "Ansible not available. Skipping connectivity test."
    fi
}

# Function to run security hardening
run_hardening() {
    local mode="${1:-}"

    if [[ -z "$mode" ]]; then
        print_section "Choose Installation Mode"
        echo
        echo "  ${CYAN}1)${NC} Manual (Bash script) - Best for single systems"
        echo "  ${CYAN}2)${NC} Automated (Ansible) - Best for multiple systems"
        echo "  ${CYAN}3)${NC} Test mode (Dry run) - Preview changes only"
        echo
        read -p "Enter your choice [1-3]: " choice
        
        case $choice in
            1) mode=1 ;;
            2) mode=2 ;;
            3) mode=3 ;;
            *)
                show_error "Invalid choice" "Enter 1, 2, or 3" ""
                exit 1
                ;;
        esac
    fi

    case $mode in
        1)
            log_info "Running manual hardening..."
            if [[ -f "$SCRIPT_DIR/scripts/linux_hardening.sh" ]]; then
                chmod +x "$SCRIPT_DIR/scripts/linux_hardening.sh"
                sudo "$SCRIPT_DIR/scripts/linux_hardening.sh"
            else
                show_error "Hardening script not found" "Check path: $SCRIPT_DIR/scripts/linux_hardening.sh" ""
                exit 1
            fi
            ;;
        2)
            log_info "Running automated hardening..."
            if [[ -f "$SCRIPT_DIR/ansible/playbooks/playbook_hardening.yml" ]]; then
                ansible-playbook -i "$INVENTORY_FILE" "$SCRIPT_DIR/ansible/playbooks/playbook_hardening.yml"
            else
                show_error "Ansible playbook not found" "Check path: $SCRIPT_DIR/ansible/playbooks/playbook_hardening.yml" ""
                exit 1
            fi
            ;;
        3)
            log_info "Running in test mode..."
            if [[ -f "$SCRIPT_DIR/ansible/playbooks/playbook_hardening.yml" ]]; then
                ansible-playbook -i "$INVENTORY_FILE" "$SCRIPT_DIR/ansible/playbooks/playbook_hardening.yml" --check
            else
                show_error "Ansible playbook not found" "Check path: $SCRIPT_DIR/ansible/playbooks/playbook_hardening.yml" ""
                exit 1
            fi
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
${BOLD}Fortress Linux Installation Script${NC}

USAGE:
    $0 [OPTIONS]

OPTIONS:
    ${CYAN}-h, --help${NC}          Show this help message
    ${CYAN}-m, --mode MODE${NC}     Installation mode (manual|ansible|test)
    ${CYAN}-b, --backup${NC}        Create backup before installation
    ${CYAN}-s, --skip-deps${NC}     Skip dependency installation
    ${CYAN}-t, --test${NC}          Test mode only (dry run)
    ${CYAN}-q, --quiet${NC}         Minimal output (errors only)
    ${CYAN}-v, --verbose${NC}       Verbose output

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
    # Parse UX arguments first
    parse_ux_arguments "$@"

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
            *)
                shift
                ;;
        esac
    done
    
    # Display header
    print_header "🚀 Fortress Linux - Installation"

    echo
    log_info "Installation directory: $SCRIPT_DIR"
    echo
    
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
        log_info "Running in test mode..."
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
    
    print_header "✅ Installation Complete"
    echo
    log_info "Review the logs in $SCRIPT_DIR/logs/ for details."
    log_info "For configuration options, see $SCRIPT_DIR/docs/ directory."
    echo
}

# Run main function
main "$@"