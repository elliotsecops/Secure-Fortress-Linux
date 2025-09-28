#!/bin/bash

# Script to automate the download and installation of dependencies for Secure Fortress Linux

# Function to check if a command is available
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to log messages
LOG_FILE="install_dependencies.log"
log() {
    local message="$(date '+%Y-%m-%d %H:%M:%S') - $1"
    echo "$message" >> "$LOG_FILE"
    if [ "$VERBOSE" = true ]; then
        echo "$message"
    fi
}

# Function to prompt for confirmation
confirm() {
    read -p "$1 [y/N]: " response
    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
    log "Please run this script as root."
    exit 1
fi

# Check if sudo is available
SUDO=""
if command_exists sudo; then
    SUDO="sudo"
fi

# Verbose mode
VERBOSE=false
DRY_RUN=false

# Parse command-line options
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -v|--verbose) VERBOSE=true ;;
        -d|--dry-run) DRY_RUN=true ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  -v, --verbose    Enable verbose output"
            echo "  -d, --dry-run    Show what actions would be taken without performing them"
            echo "  -h, --help       Display this help message"
            exit 0
            ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Trap for unexpected exits
trap 'echo "Script interrupted. Exiting..."; exit 1' INT TERM

# Cleanup function
cleanup() {
    log "Performing cleanup..."
    # Add cleanup tasks here
}

# Backup configuration files
backup_config() {
    local file=$1
    if [ -f "$file" ]; then
        cp "$file" "${file}.bak"
        log "Backed up $file to ${file}.bak"
    fi
}

# Check version of installed commands
check_version() {
    local command=$1
    local version=$($command --version 2>&1 | awk '{print $NF; exit}')
    log "$command version: $version"
}

# Update package list
log "Updating package list..."
if [ "$DRY_RUN" = false ]; then
    $SUDO apt update || { log "Failed to update package list."; exit 1; }
fi

# Install Python 3.x
if ! command_exists python3; then
    if confirm "Do you want to install Python 3.x?"; then
        log "Installing Python 3.x..."
        if [ "$DRY_RUN" = false ]; then
            $SUDO apt install -y python3 || { log "Failed to install Python 3.x."; exit 1; }
        else
            log "Dry run: Would install Python 3.x"
        fi
    else
        log "Skipping Python 3.x installation."
    fi
else
    log "Python 3.x is already installed."
    check_version python3
fi

# Install Ansible
if ! command_exists ansible; then
    if confirm "Do you want to install Ansible?"; then
        log "Installing Ansible..."
        if [ "$DRY_RUN" = false ]; then
            $SUDO apt install -y software-properties-common || { log "Failed to install software-properties-common."; exit 1; }
            # Manually add the Ansible repository
            $SUDO apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367
            echo "deb http://ppa.launchpad.net/ansible/ansible/ubuntu focal main" | $SUDO tee /etc/apt/sources.list.d/ansible.list
            backup_config /etc/apt/sources.list.d/ansible.list
            $SUDO apt update || { log "Failed to update package list."; exit 1; }
            $SUDO apt install -y ansible || { log "Failed to install Ansible."; exit 1; }
        else
            log "Dry run: Would install Ansible"
        fi
    else
        log "Skipping Ansible installation."
    fi
else
    log "Ansible is already installed."
    check_version ansible
fi

# Install Wazuh Agent
if ! command_exists wazuh-agent; then
    if confirm "Do you want to install Wazuh Agent?"; then
        # Detect the Linux distribution
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            OS=$ID
            VERSION=$VERSION_ID
        else
            log "Unable to detect the Linux distribution."
            exit 1
        fi

        case $OS in
            ubuntu|debian|kali)
                log "Adding Wazuh repository for $OS $VERSION..."
                if [ "$DRY_RUN" = false ]; then
                    if ! grep -q "deb https://packages.wazuh.com/4.x/apt/ stable main" /etc/apt/sources.list.d/wazuh.list; then
                        wget -qO - https://packages.wazuh.com/key/GPG-KEY-WAZUH | $SUDO apt-key add - || { log "Failed to add Wazuh GPG key."; exit 1; }
                        echo "deb https://packages.wazuh.com/4.x/apt/ stable main" | $SUDO tee -a /etc/apt/sources.list.d/wazuh.list || { log "Failed to add Wazuh repository."; exit 1; }
                        backup_config /etc/apt/sources.list.d/wazuh.list
                        $SUDO apt-get update || { log "Failed to update package list."; exit 1; }
                        $SUDO apt-get install -y wazuh-agent || { log "Failed to install Wazuh Agent."; exit 1; }
                    else
                        log "Wazuh repository already exists. Skipping addition."
                    fi
                else
                    log "Dry run: Would add Wazuh repository and install Wazuh Agent"
                fi
                ;;
            centos|rhel)
                log "Adding Wazuh repository for $OS $VERSION..."
                if [ "$DRY_RUN" = false ]; then
                    if ! grep -q "baseurl=https://packages.wazuh.com/4.x/yum/" /etc/yum.repos.d/wazuh.repo; then
                        rpm --import https://packages.wazuh.com/key/GPG-KEY-WAZUH || { log "Failed to add Wazuh GPG key."; exit 1; }
                        echo -e "[wazuh]\ngpgcheck=1\ngpgkey=https://packages.wazuh.com/key/GPG-KEY-WAZUH\nenabled=1\nname=EL-$VERSION - Wazuh\nbaseurl=https://packages.wazuh.com/4.x/yum/\nprotect=1" | $SUDO tee /etc/yum.repos.d/wazuh.repo || { log "Failed to add Wazuh repository."; exit 1; }
                        backup_config /etc/yum.repos.d/wazuh.repo
                        $SUDO yum install -y wazuh-agent || { log "Failed to install Wazuh Agent."; exit 1; }
                    else
                        log "Wazuh repository already exists. Skipping addition."
                    fi
                else
                    log "Dry run: Would add Wazuh repository and install Wazuh Agent"
                fi
                ;;
            *)
                log "Unsupported Linux distribution: $OS"
                exit 1
                ;;
        esac

        log "Wazuh Agent installed successfully."
    else
        log "Skipping Wazuh Agent installation."
    fi
else
    log "Wazuh Agent is already installed."
fi

# Verify installations
log "Verifying installations..."
command_exists python3 && log "Python 3.x is installed." || log "Python 3.x is not installed."
command_exists ansible && log "Ansible is installed." || log "Ansible is not installed."

# Function to check and start Wazuh Agent service
check_and_start_wazuh() {
    if command_exists systemctl; then
        if systemctl is-active --quiet wazuh-agent; then
            log "Wazuh Agent is installed and running."
        else
            log "Wazuh Agent is installed but not running. Attempting to start..."
            if [ "$DRY_RUN" = false ]; then
                systemctl start wazuh-agent
                sleep 5
                if systemctl is-active --quiet wazuh-agent; then
                    log "Wazuh Agent successfully started."
                else
                    log "Failed to start Wazuh Agent. Please check the service manually."
                fi
            else
                log "Dry run: Would start Wazuh Agent"
            fi
        fi
    else
        log "systemctl not found. Unable to check Wazuh Agent service status."
    fi
}

# Add a longer delay before verifying the Wazuh Agent installation
log "Waiting for Wazuh Agent to initialize..."
sleep 15

# Check Wazuh Agent installation and service status
if command_exists wazuh-agent; then
    check_and_start_wazuh
    
    # Additional Wazuh Agent status information
    if command_exists wazuh-control; then
        log "Wazuh Agent status:"
        if [ "$DRY_RUN" = false ]; then
            wazuh-control status
        else
            log "Dry run: Would check Wazuh Agent status"
        fi
    else
        log "wazuh-control command not found. Unable to check detailed agent status."
    fi
else
    log "Wazuh Agent is not installed."
fi

log "Dependency installation and verification completed."