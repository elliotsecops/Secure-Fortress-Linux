#!/bin/bash

# Fortress Linux - System Security Hardening Script
# Enhanced with error handling, logging, and backup functionality

set -euo pipefail

# Configuration variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/var/log/fortress-hardening.log"
BACKUP_DIR="/etc/fortress-backups/$(date +%Y%m%d_%H%M%S)"
MIN_DISK_SPACE=1048576  # 1GB in KB
REQUIRED_SERVICES=("ssh" "ufw" "auditd")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

log_info() {
    log "INFO" "$@"
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    log "SUCCESS" "$@"
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warning() {
    log "WARNING" "$@"
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

log_error() {
    log "ERROR" "$@"
    echo -e "${RED}[ERROR]${NC} $*"
}

# Error handling
handle_error() {
    local line_number=$1
    log_error "Script failed at line $line_number. Check logs for details."
    log_error "Backup available at: $BACKUP_DIR"
    exit 1
}

trap 'handle_error $LINENO' ERR

# Pre-flight checks
check_root_privileges() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        exit 1
    fi
}

check_system_requirements() {
    log_info "Checking system requirements..."

    # Check OS
    if [[ ! -f /etc/os-release ]]; then
        log_error "Cannot determine operating system"
        exit 1
    fi

    source /etc/os-release
    log_info "Detected OS: $PRETTY_NAME"

    # Check if supported OS
    if [[ "$ID" != "ubuntu" && "$ID" != "debian" ]]; then
        log_warning "This script is designed for Ubuntu/Debian. Other distributions may require manual adjustments."
    fi

    # Check disk space
    local available_space=$(df -k / | awk 'NR==2 {print $4}')
    if [[ $available_space -lt $MIN_DISK_SPACE ]]; then
        log_error "Insufficient disk space. At least 1GB free space required."
        exit 1
    fi

    log_success "System requirements check passed"
}

check_connectivity() {
    log_info "Checking internet connectivity..."
    if ! ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        log_error "No internet connectivity. Required for package updates."
        exit 1
    fi
    log_success "Internet connectivity confirmed"
}

# Backup functions
create_backup() {
    log_info "Creating system backup..."
    mkdir -p "$BACKUP_DIR"

    # Backup configuration files
    local files_to_backup=(
        "/etc/ssh/sshd_config"
        "/etc/security/pwquality.conf"
        "/etc/audit/rules.d/hardening.rules"
        "/etc/audit/auditd.conf"
        "/etc/default/ufw"
        "/etc/passwd"
        "/etc/group"
        "/etc/shadow"
        "/etc/gshadow"
    )

    for file in "${files_to_backup[@]}"; do
        if [[ -f "$file" ]]; then
            cp "$file" "$BACKUP_DIR/" 2>/dev/null || log_warning "Could not backup $file"
        fi
    done

    # Backup UFW rules if they exist
    if command -v ufw >/dev/null 2>&1; then
        ufw status verbose > "$BACKUP_DIR/ufw_status.txt" 2>/dev/null || true
    fi

    # Backup auditd rules
    if command -v auditctl >/dev/null 2>&1; then
        auditctl -l > "$BACKUP_DIR/audit_rules.txt" 2>/dev/null || true
    fi

    log_success "Backup created at: $BACKUP_DIR"
}

# Hardening functions
update_system() {
    log_info "Updating system packages..."

    # Update package list
    if apt update; then
        log_success "Package list updated"
    else
        log_error "Failed to update package list"
        return 1
    fi

    # Upgrade packages
    if apt upgrade -y; then
        log_success "System packages upgraded"
    else
        log_error "Failed to upgrade packages"
        return 1
    fi

    # Clean up
    apt autoremove -y >/dev/null 2>&1 || true
    apt autoclean >/dev/null 2>&1 || true
}

configure_firewall() {
    log_info "Configuring UFW firewall..."

    # Check if UFW is installed
    if ! command -v ufw >/dev/null 2>&1; then
        log_info "Installing UFW..."
        apt install -y ufw
    fi

    # Configure default policies
    ufw --force reset >/dev/null 2>&1 || true
    ufw default deny incoming
    ufw default allow outgoing

    # Allow SSH (ensure we don't lock ourselves out)
    ufw allow OpenSSH
    ufw allow 22/tcp

    # Enable logging
    ufw logging medium

    # Enable firewall
    if ufw --force enable; then
        log_success "UFW firewall configured and enabled"
    else
        log_error "Failed to enable UFW firewall"
        return 1
    fi

    # Display status
    log_info "Firewall status:"
    ufw status verbose | tee -a "$LOG_FILE"
}

disable_unnecessary_services() {
    log_info "Disabling unnecessary services..."

    local services_to_disable=(
        "avahi-daemon"
        "cups"
        "cups-browsed"
        "nfs-server"
        "rpcbind"
        "bluetooth"
        "cupsd"
    )

    for service in "${services_to_disable[@]}"; do
        if systemctl is-enabled "$service" >/dev/null 2>&1; then
            systemctl disable "$service" 2>/dev/null || log_warning "Could not disable $service"
            systemctl stop "$service" 2>/dev/null || log_warning "Could not stop $service"
            log_info "Disabled service: $service"
        else
            log_info "Service already disabled: $service"
        fi
    done

    log_success "Unnecessary services disabled"
}

configure_password_policy() {
    log_info "Configuring password policies..."

    # Ensure pwquality package is installed
    if ! dpkg -l | grep -q pwquality; then
        apt install -y libpwquality-tools
    fi

    # Configure pwquality
    local pwquality_file="/etc/security/pwquality.conf"

    # Backup original file
    cp "$pwquality_file" "$BACKUP_DIR/pwquality.conf.bak" 2>/dev/null || true

    # Update or add password policies
    local policies=(
        "minlen = 14"
        "minclass = 4"
        "maxrepeat = 3"
        "dcredit = -1"
        "ucredit = -1"
        "lcredit = -1"
        "ocredit = -1"
        "difok = 3"
    )

    for policy in "${policies[@]}"; do
        local key=$(echo "$policy" | cut -d'=' -f1 | xargs)
        if grep -q "^#*$key" "$pwquality_file"; then
            sed -i "s/^#*$key.*/$policy/" "$pwquality_file"
        else
            echo "$policy" >> "$pwquality_file"
        fi
    done

    log_success "Password policies configured"
}

configure_auditd() {
    log_info "Configuring audit daemon..."

    # Ensure auditd is installed
    if ! dpkg -l | grep -q auditd; then
        apt install -y auditd
    fi

    # Create auditd rules
    local audit_rules_file="/etc/audit/rules.d/hardening.rules"

    # Backup existing rules
    if [[ -f "$audit_rules_file" ]]; then
        cp "$audit_rules_file" "$BACKUP_DIR/audit_rules.bak" 2>/dev/null || true
    fi

    # Create comprehensive audit rules
    cat > "$audit_rules_file" << 'EOF'
# Monitor identity and access
-w /etc/passwd -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/gshadow -p wa -k identity
-w /etc/group -p wa -k identity
-w /etc/sudoers -p wa -k sudo
-w /var/log/sudo.log -p wa -k sudo

# Monitor system calls
-a always,exit -F arch=b64 -S execve,execveat -F auid>=1000 -F auid!=-1 -k execution
-a always,exit -F arch=b64 -S open,creat,truncate,ftruncate,openat -F exit=-EACCES -F auid>=1000 -F auid!=-1 -k access
-a always,exit -F arch=b64 -S open,creat,truncate,ftruncate,openat -F exit=-EPERM -F auid>=1000 -F auid!=-1 -k access

# Monitor network activity
-a always,exit -F arch=b64 -S connect,bind,listen,accept -F auid>=1000 -F auid!=-1 -k network

# Monitor privileged operations
-a always,exit -F arch=b64 -S setuid,setgid,setreuid,setregid,setresuid,setresgid -F auid>=1000 -F auid!=-1 -k perm_mod

# Monitor file deletions
-a always,exit -F arch=b64 -S unlink,unlinkat,rename,renameat -F auid>=1000 -F auid!=-1 -k delete

# Monitor login events
-w /var/log/auth.log -p wa -k auth
-w /var/log/lastlog -p wa -k logins
-w /var/log/faillog -p wa -k logins
-w /var/run/utmp -p wa -k session
-w /var/log/wtmp -p wa -k logins
-w /var/log/btmp -p wa -k session

# Monitor time changes
-a always,exit -F arch=b64 -S adjtimex,settimeofday,clock_settime -F auid>=1000 -F auid!=-1 -k time-change

# Monitor kernel modules
-w /sbin/insmod -p x -k modules
-w /sbin/rmmod -p x -k modules
-w /sbin/modprobe -p x -k modules
-a always,exit -F arch=b64 -S init_module,finit_module,delete_module -F auid>=1000 -F auid!=-1 -k modules

# Monitor system configuration
-w /etc/hosts -p wa -k network
-w /etc/resolv.conf -p wa -k network
-w /etc/sysconfig/network -p wa -k network
-w /etc/issue -p wa -k system_info
EOF

    # Restart auditd
    if systemctl restart auditd; then
        log_success "Audit daemon configured and restarted"
    else
        log_error "Failed to restart auditd"
        return 1
    fi

    # Load rules
    if auditctl -R "$audit_rules_file" 2>/dev/null; then
        log_success "Audit rules loaded successfully"
    else
        log_warning "Some audit rules may not have loaded properly"
    fi
}

configure_file_permissions() {
    log_info "Configuring secure file permissions..."

    # Secure critical files
    chmod 640 /etc/shadow 2>/dev/null || log_warning "Could not set shadow permissions"
    chmod 600 /etc/gshadow 2>/dev/null || log_warning "Could not set gshadow permissions"
    chmod 644 /etc/passwd 2>/dev/null || log_warning "Could not set passwd permissions"
    chmod 644 /etc/group 2>/dev/null || log_warning "Could not set group permissions"

    # Secure SSH configuration
    chmod 600 /etc/ssh/sshd_config 2>/dev/null || log_warning "Could not secure SSH config"

    # Remove world-writable permissions
    find / -type f -perm -002 2>/dev/null | head -20 | while read file; do
        if [[ -f "$file" ]]; then
            chmod o-w "$file" 2>/dev/null || log_warning "Could not remove world-writable permission from $file"
        fi
    done

    log_success "File permissions configured"
}

configure_ssh_security() {
    log_info "Configuring SSH security settings..."

    local ssh_config="/etc/ssh/sshd_config"

    # Backup SSH config
    cp "$ssh_config" "$BACKUP_DIR/sshd_config.bak" 2>/dev/null || true

    # Secure SSH configuration
    local ssh_settings=(
        "PermitRootLogin no"
        "PasswordAuthentication no"
        "PubkeyAuthentication yes"
        "Protocol 2"
        "PermitEmptyPasswords no"
        "MaxAuthTries 3"
        "ClientAliveInterval 300"
        "ClientAliveCountMax 2"
        "X11Forwarding no"
        "AllowTcpForwarding no"
        "Banner /etc/ssh/banner"
    )

    for setting in "${ssh_settings[@]}"; do
        local key=$(echo "$setting" | cut -d' ' -f1)
        if grep -q "^#\?$key" "$ssh_config"; then
            sed -i "s/^#\?$key.*/$setting/" "$ssh_config"
        else
            echo "$setting" >> "$ssh_config"
        fi
    done

    # Create SSH banner
    cat > /etc/ssh/banner << 'EOF'
***************************************************************************
                            AUTHORIZED ACCESS ONLY
***************************************************************************
This system is for authorized users only. Individual use of this system
and/or network without authority, or in excess of your authority, is
strictly prohibited. Unauthorized access is a violation of state and
federal, civil and criminal laws.
***************************************************************************
EOF

    # Test SSH configuration
    if sshd -t; then
        log_success "SSH configuration is valid"
    else
        log_error "SSH configuration has errors"
        return 1
    fi

    # Restart SSH service
    if systemctl restart sshd; then
        log_success "SSH service restarted with secure configuration"
    else
        log_error "Failed to restart SSH service"
        return 1
    fi
}

# System hardening verification
verify_hardening() {
    log_info "Verifying hardening implementation..."

    local verification_failed=false

    # Check UFW status
    if ufw status | grep -q "Status: active"; then
        log_success "✓ UFW firewall is active"
    else
        log_error "✗ UFW firewall is not active"
        verification_failed=true
    fi

    # Check SSH configuration
    if grep -q "PermitRootLogin no" /etc/ssh/sshd_config; then
        log_success "✓ Root login via SSH is disabled"
    else
        log_error "✗ Root login via SSH is still enabled"
        verification_failed=true
    fi

    # Check auditd status
    if systemctl is-active auditd >/dev/null 2>&1; then
        log_success "✓ Audit daemon is running"
    else
        log_error "✗ Audit daemon is not running"
        verification_failed=true
    fi

    # Check password policy
    if grep -q "minlen = 14" /etc/security/pwquality.conf; then
        log_success "✓ Password policy is configured"
    else
        log_error "✗ Password policy is not properly configured"
        verification_failed=true
    fi

    if [[ "$verification_failed" == "true" ]]; then
        log_error "Some verifications failed. Please review the configuration."
        return 1
    else
        log_success "All verifications passed successfully"
    fi
}

# Cleanup function
cleanup() {
    log_info "Performing cleanup..."

    # Remove any temporary files
    rm -f /tmp/fortress-* 2>/dev/null || true

    # Update file database
    updatedb >/dev/null 2>&1 || true

    log_success "Cleanup completed"
}

# Restore function (for rollback)
restore_from_backup() {
    if [[ $# -eq 0 ]]; then
        log_error "Usage: $0 restore <backup_directory>"
        exit 1
    fi

    local backup_dir="$1"

    if [[ ! -d "$backup_dir" ]]; then
        log_error "Backup directory does not exist: $backup_dir"
        exit 1
    fi

    log_info "Restoring from backup: $backup_dir"

    # Restore configuration files
    local files_to_restore=(
        "sshd_config:/etc/ssh/sshd_config"
        "pwquality.conf:/etc/security/pwquality.conf"
        "hardening.rules:/etc/audit/rules.d/hardening.rules"
        "auditd.conf:/etc/audit/auditd.conf"
        "passwd:/etc/passwd"
        "group:/etc/group"
        "shadow:/etc/shadow"
        "gshadow:/etc/gshadow"
    )

    for file_pair in "${files_to_restore[@]}"; do
        local backup_file="${file_pair%%:*}"
        local target_file="${file_pair##*:}"

        if [[ -f "$backup_dir/$backup_file" ]]; then
            cp "$backup_dir/$backup_file" "$target_file"
            log_info "Restored: $target_file"
        fi
    done

    # Restart services
    systemctl restart sshd 2>/dev/null || true
    systemctl restart auditd 2>/dev/null || true

    log_success "System restored from backup"
}

# Main execution
main() {
    log_info "Starting Fortress Linux hardening..."
    log_info "Log file: $LOG_FILE"
    log_info "Backup directory: $BACKUP_DIR"

    # Handle restore mode
    if [[ "${1:-}" == "restore" ]]; then
        restore_from_backup "${2:-}"
        exit 0
    fi

    # Pre-flight checks
    check_root_privileges
    check_system_requirements
    check_connectivity

    # Create backup
    create_backup

    # Execute hardening steps
    log_info "Starting system hardening procedures..."

    update_system
    configure_firewall
    disable_unnecessary_services
    configure_password_policy
    configure_auditd
    configure_file_permissions
    configure_ssh_security

    # Verification
    verify_hardening

    # Cleanup
    cleanup

    log_success "Fortress Linux hardening completed successfully!"
    log_info "Backup location: $BACKUP_DIR"
    log_info "Log file: $LOG_FILE"
    log_info "To restore: $0 restore $BACKUP_DIR"

    # Display summary
    echo
    echo "=== HARDENING SUMMARY ==="
    echo "✓ System packages updated"
    echo "✓ Firewall configured and enabled"
    echo "✓ Unnecessary services disabled"
    echo "✓ Password policies strengthened"
    echo "✓ Audit daemon configured"
    echo "✓ File permissions secured"
    echo "✓ SSH security enhanced"
    echo "✓ System verified"
    echo
    echo "IMPORTANT: Save this backup directory: $BACKUP_DIR"
    echo "Restore command: sudo $0 restore $BACKUP_DIR"
    echo
}

# Execute main function
main "$@"