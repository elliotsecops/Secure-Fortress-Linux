#!/bin/bash

# Script to automate the download and installation of dependencies for Secure Fortress Linux
# Updated with enhanced security measures and best practices

set -euo pipefail  # Exit on error, undefined variables, and pipe failures

# Function to check if a command is available
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to log messages with timestamps and log levels
LOG_FILE="${LOG_FILE:-install_dependencies.log}"
log() {
    local level="${1}"
    shift
    local message="$(date '+%Y-%m-%d %H:%M:%S') [${level}] $*"
    echo "$message" | tee -a "$LOG_FILE"
}

# Log levels
log_info() { log "INFO" "$@"; }
log_warn() { log "WARN" "$@"; }
log_error() { log "ERROR" "$@"; }
log_debug() { 
    if [[ "${DEBUG:-false}" == "true" ]]; then
        log "DEBUG" "$@"
    fi
}

# Function to prompt for confirmation
confirm() {
    local prompt="$1"
    local response
    read -p "$prompt [y/N]: " response
    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Validate OS and version
validate_os() {
    if [ ! -f /etc/os-release ]; then
        log_error "Unable to detect the Linux distribution. /etc/os-release not found."
        exit 1
    fi

    . /etc/os-release
    OS=$ID
    VERSION=$VERSION_ID
    VERSION_CODENAME=${VERSION_CODENAME:-$(lsb_release -c -s 2>/dev/null || echo "unknown")}

    # Check if it's a supported distribution
    case $OS in
        ubuntu|debian|centos|rhel|kali|fedora|opensuse-leap|amzn)
            log_info "Supported OS detected: $OS $VERSION"
            return 0
            ;;
        *)
            log_error "Unsupported Linux distribution: $OS. Supported: Ubuntu, Debian, CentOS, RHEL, Kali, Fedora, OpenSUSE, Amazon Linux"
            exit 1
            ;;
    esac
}

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
    log_error "Please run this script as root."
    exit 1
fi

# Check if sudo is available
SUDO=""
if command_exists sudo; then
    SUDO="sudo"
fi

# Verbose and debug modes
VERBOSE=false
DRY_RUN=false
DEBUG=false
SKIP_DEPENDENCIES=""

# Parse command-line options
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -v|--verbose) 
            VERBOSE=true
            log_info "Verbose mode enabled"
            ;;
        -d|--dry-run) 
            DRY_RUN=true
            log_info "Dry run mode enabled"
            ;;
        --debug)
            DEBUG=true
            log_info "Debug mode enabled"
            ;;
        --skip-dependencies)
            SKIP_DEPENDENCIES="${2:-}"
            log_info "Skipping dependencies: $SKIP_DEPENDENCIES"
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  -v, --verbose              Enable verbose output"
            echo "  --debug                    Enable debug output"
            echo "  -d, --dry-run              Show what actions would be taken without performing them"
            echo "  --skip-dependencies PKGS   Skip installation of specified packages (comma-separated)"
            echo "  -h, --help                 Display this help message"
            exit 0
            ;;
        *) 
            log_error "Unknown parameter passed: $1"
            exit 1 
            ;;
    esac
    shift
done

# Function to log to both file and console with proper formatting
log_info "Starting dependency installation process..."

# Trap for unexpected exits
trap 'log_error "Script interrupted. Exiting..."; exit 1' INT TERM

# Cleanup function
cleanup() {
    log_info "Performing cleanup..."
    # Remove temporary files if any
    rm -f /tmp/fortress_*.tmp 2>/dev/null || true
}

# Backup configuration files with timestamp
backup_config() {
    local file=$1
    local timestamp=$(date +%Y%m%d_%H%M%S)
    if [ -f "$file" ]; then
        local backup_file="${file}.backup.${timestamp}"
        cp "$file" "$backup_file"
        log_info "Backed up $file to $backup_file"
    fi
}

# Check version of installed commands
check_version() {
    local command=$1
    if command_exists "$command"; then
        local version
        version=$($command --version 2>&1 | head -n1 | awk '{print $NF; exit}' || true)
        log_info "$command version: ${version:-unknown}"
    else
        log_warn "$command is not installed"
    fi
}

# Verify integrity of downloaded content
verify_checksum() {
    local file=$1
    local expected_checksum=$2
    local actual_checksum
    
    if command_exists sha256sum; then
        actual_checksum=$(sha256sum "$file" | awk '{print $1}')
    elif command_exists shasum; then
        actual_checksum=$(shasum -a 256 "$file" | awk '{print $1}')
    else
        log_warn "No checksum utility found, skipping verification for $file"
        return 0
    fi
    
    if [ "$actual_checksum" = "$expected_checksum" ]; then
        log_info "Checksum verification passed for $file"
        return 0
    else
        log_error "Checksum verification failed for $file"
        return 1
    fi
}

# Update package list with retry mechanism
update_package_list() {
    local max_attempts=3
    local attempt=1
    local success=false
    
    while [ $attempt -le $max_attempts ] && [ "$success" = false ]; do
        log_info "Updating package list (attempt $attempt of $max_attempts)..."
        if [ "$DRY_RUN" = false ]; then
            if $SUDO apt update || $SUDO yum updateinfo || $SUDO dnf check-update; then
                success=true
            else
                log_warn "Package list update failed on attempt $attempt"
                ((attempt++))
                sleep 5
            fi
        else
            log_info "Dry run: Would update package list"
            success=true
        fi
    done
    
    if [ "$success" = false ]; then
        log_error "Failed to update package list after $max_attempts attempts"
        exit 1
    fi
}

# Install packages with retry mechanism and verification
install_packages() {
    local packages=("$@")
    local package_manager=""
    
    # Determine package manager based on OS
    if command_exists apt; then
        package_manager="apt"
    elif command_exists yum; then
        package_manager="yum"
    elif command_exists dnf; then
        package_manager="dnf"
    elif command_exists zypper; then
        package_manager="zypper"
    else
        log_error "No supported package manager found"
        exit 1
    fi
    
    log_info "Installing packages using $package_manager: ${packages[*]}"
    
    if [ "$DRY_RUN" = false ]; then
        case $package_manager in
            apt)
                $SUDO apt install -y "${packages[@]}"
                ;;
            yum)
                $SUDO yum install -y "${packages[@]}"
                ;;
            dnf)
                $SUDO dnf install -y "${packages[@]}"
                ;;
            zypper)
                $SUDO zypper install -y "${packages[@]}"
                ;;
        esac
        
        # Verify installation
        for pkg in "${packages[@]}"; do
            if ! command_exists "$pkg"; then
                # For packages with different command names, check with dpkg/rpm
                case $pkg in
                    ansible)
                        if command_exists ansible-playbook; then
                            continue
                        fi
                        ;;
                esac
                log_warn "Package $pkg may not have installed correctly"
            fi
        done
    else
        log_info "Dry run: Would install packages: ${packages[*]}"
    fi
}

# Validate and check for required dependencies
validate_dependencies() {
    local deps=("$@")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if [[ ! "$SKIP_DEPENDENCIES" =~ (^|,)"$dep"(|,)$ ]]; then
            if ! command_exists "$dep"; then
                missing_deps+=("$dep")
            fi
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_info "Missing dependencies: ${missing_deps[*]}"
        echo "${missing_deps[@]}"
        return 1
    else
        log_info "All required dependencies are present"
        return 0
    fi
}

# Main installation process
log_info "Validating OS and system requirements..."
validate_os

log_info "Updating package lists..."
update_package_list

# Define required packages
required_packages=()

# Add Python if not skipped
if [[ ! "$SKIP_DEPENDENCIES" =~ (^|,)python3(|,)$ ]]; then
    required_packages+=("python3")
fi

# Add Ansible if not skipped
if [[ ! "$SKIP_DEPENDENCIES" =~ (^|,)ansible(|,)$ ]]; then
    required_packages+=("ansible")
fi

# Add Wazuh if not skipped
if [[ ! "$SKIP_DEPENDENCIES" =~ (^|,)wazuh-agent(|,)$ ]]; then
    required_packages+=("curl" "wget" "gnupg")  # Dependencies for Wazuh
fi

# Install required packages
if [ ${#required_packages[@]} -gt 0 ]; then
    install_packages "${required_packages[@]}"
else
    log_info "No packages to install based on skip settings"
fi

# Install Wazuh Agent with security enhancements
if [[ ! "$SKIP_DEPENDENCIES" =~ (^|,)wazuh-agent(|,)$ ]]; then
    if confirm "Do you want to install Wazuh Agent?"; then
        log_info "Installing Wazuh Agent..."
        
        # Get the latest Wazuh GPG key
        local wazuh_gpg_key="https://packages.wazuh.com/key/GPG-KEY-WAZUH"
        local wazuh_key_path="/tmp/wazuh_gpg_key_$(date +%s)"
        
        if [ "$DRY_RUN" = false ]; then
            # Download and verify Wazuh GPG key
            if curl -sSfL "$wazuh_gpg_key" -o "$wazuh_key_path"; then
                $SUDO apt-key add "$wazuh_key_path" || { 
                    log_error "Failed to add Wazuh GPG key"; 
                    exit 1; 
                }
                rm "$wazuh_key_path"
            else
                log_error "Failed to download Wazuh GPG key"
                exit 1
            fi
            
            case $OS in
                ubuntu|debian|kali)
                    # Add Wazuh repository with gpg key
                    local wazuh_repo_file="/etc/apt/sources.list.d/wazuh.list"
                    backup_config "$wazuh_repo_file"
                    
                    echo "deb [signed-by=/usr/share/keyrings/wazuh-archive-keyring.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | $SUDO tee "$wazuh_repo_file"
                    
                    # Alternative method with proper gpg keyring
                    curl -sSfL https://packages.wazuh.com/key/WAZUH-GPG-KEY | gpg --batch --yes --dearmor -o /usr/share/keyrings/wazuh-archive-keyring.gpg
                    echo "deb [signed-by=/usr/share/keyrings/wazuh-archive-keyring.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | $SUDO tee /etc/apt/sources.list.d/wazuh.list
                    
                    # Update package lists again
                    $SUDO apt update
                    
                    # Install Wazuh agent
                    $SUDO apt install -y wazuh-agent
                    ;;
                centos|rhel|fedora|amzn)
                    # Add Wazuh repository for Red Hat systems
                    local wazuh_repo_path="/etc/yum.repos.d/wazuh.repo"
                    backup_config "$wazuh_repo_path"
                    
                    cat << EOF | $SUDO tee "$wazuh_repo_path"
[wazuh-base]
name=Wazuh repository
gpgcheck=1
gpgkey=https://packages.wazuh.com/key/GPG-KEY-WAZUH
enabled=1
baseurl=https://packages.wazuh.com/4.x/yum/
protect=1
EOF
                    
                    # Install Wazuh agent
                    if command_exists dnf; then
                        $SUDO dnf install -y wazuh-agent
                    else
                        $SUDO yum install -y wazuh-agent
                    fi
                    ;;
                *)
                    log_error "Unsupported Linux distribution for Wazuh: $OS"
                    exit 1
                    ;;
            esac
            
            log_info "Wazuh Agent installed successfully"
        else
            log_info "Dry run: Would install Wazuh Agent"
        fi
    else
        log_info "Skipping Wazuh Agent installation."
    fi
else
    log_info "Wazuh Agent installation skipped per command line option."
fi

# Verify installations
log_info "Verifying installations..."
check_version python3
check_version ansible
check_version wazuh-agent 2>/dev/null || log_warn "Wazuh agent not found"

# Check and start services if installed
check_and_start_services() {
    local services=("wazuh-agent")
    
    for service in "${services[@]}"; do
        command_exists "$service" && {
            if command_exists systemctl; then
                if systemctl is-enabled --quiet "$service" 2>/dev/null; then
                    if systemctl is-active --quiet "$service" 2>/dev/null; then
                        log_info "$service is already running"
                    else
                        log_info "Starting $service..."
                        if [ "$DRY_RUN" = false ]; then
                            systemctl start "$service"
                            sleep 3
                            if systemctl is-active --quiet "$service" 2>/dev/null; then
                                log_info "$service started successfully"
                            else
                                log_warn "$service failed to start"
                            fi
                        else
                            log_info "Dry run: Would start $service"
                        fi
                    fi
                else
                    log_info "$service is not enabled, enabling and starting..."
                    if [ "$DRY_RUN" = false ]; then
                        systemctl enable "$service"
                        systemctl start "$service"
                        sleep 3
                        if systemctl is-active --quiet "$service" 2>/dev/null; then
                            log_info "$service enabled and started successfully"
                        else
                            log_warn "$service failed to start"
                        fi
                    else
                        log_info "Dry run: Would enable and start $service"
                    fi
                fi
            else
                log_warn "systemctl not found. Unable to manage $service service."
            fi
        }
    done
}

check_and_start_services

# Validate system security requirements
validate_security_settings() {
    log_info "Validating security settings..."
    
    # Check if auditd is available and running
    if command_exists auditctl; then
        if auditctl -l &>/dev/null; then
            log_info "auditd is running and properly configured"
        else
            log_warn "auditd is installed but may not be running properly"
        fi
    else
        log_info "auditd is not installed (this is normal if not installed as part of hardening)"
    fi
    
    # Check for common security tools
    local security_tools=("fail2ban" "ufw" "iptables")
    for tool in "${security_tools[@]}"; do
        if command_exists "$tool"; then
            log_info "Security tool $tool is available"
        else
            log_info "Security tool $tool is not installed (this is normal if not installed as part of hardening)"
        fi
    done
}

validate_security_settings

# Generate summary
log_info "Dependency installation completed successfully."
log_info "Summary of installed components:"
command_exists python3 && log_info "  - Python 3: $(python3 --version 2>&1)"
command_exists ansible && log_info "  - Ansible: $(ansible --version | head -n1 | awk '{print $2}')"
command_exists wazuh-agent && log_info "  - Wazuh Agent: Available"

log_info "Next steps:"
log_info "  1. Review the installation log: $LOG_FILE"
log_info "  2. Run the Linux hardening script: ./scripts/linux_hardening.sh"
log_info "  3. Configure the Ansible playbook: ./playbooks/playbook_hardening.yml"
log_info "  4. Update the Wazuh manager IP in the configuration files"

# Clean up
cleanup

log_info "Installation process finished at $(date)"