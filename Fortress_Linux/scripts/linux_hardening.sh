#!/bin/bash

# Fortress Linux - System Security Hardening Script
# Enhanced with optimal terminal UX experience

set -euo pipefail

# Source UX core library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/ux_core.sh" || {
    echo "ERROR: Failed to load ux_core.sh"
    exit 1
}

# Configuration variables
LOG_FILE="/var/log/fortress-hardening.log"
BACKUP_DIR="/etc/fortress-backups/$(date +%Y%m%d_%H%M%S)"
MIN_DISK_SPACE=1048576  # 1GB in KB
START_TIME=$(date +%s)

# Minimal mode flags
MINIMAL_MODE=false
SKIP_BACKUP=false
SKIP_UPDATES=false
OFFLINE_MODE=false
THREADS=4
CUSTOM_CONFIG=""

# Error handling
handle_error() {
    local line_number=$1
    local duration=$(( $(date +%s) - START_TIME ))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))

    echo
    print_divider "!"
    log_error "Script failed at line $line_number. Check logs for details."

    if [[ "$SKIP_BACKUP" != true ]]; then
        echo "💾 Backup available at: $BACKUP_DIR"
        echo "   Restore: sudo $0 restore $BACKUP_DIR"
    fi

    echo "📄 Log: $LOG_FILE"
    echo "⏱️  Duration: ${minutes}m ${seconds}s"
    print_divider "!"

    exit 1
}

trap 'handle_error $LINENO' ERR

# Pre-flight checks
check_root_privileges() {
    if [[ $EUID -ne 0 ]]; then
        show_error "This script must be run as root" "Run with: sudo $0" ""
        exit 1
    fi
}

check_system_requirements() {
    log_verbose "Checking system requirements..."

    # Check OS
    if [[ ! -f /etc/os-release ]]; then
        show_error "Cannot determine operating system" "Ensure /etc/os-release exists" ""
        exit 1
    fi

    source /etc/os-release
    log_debug "Detected OS: $PRETTY_NAME"

    # Check if supported OS
    if [[ "$ID" != "ubuntu" && "$ID" != "debian" ]]; then
        log_warning "This script is designed for Ubuntu/Debian. Other distributions may require manual adjustments."
    fi

    # Check disk space
    local available_space=$(df -k / | awk 'NR==2 {print $4}')
    if [[ $available_space -lt $MIN_DISK_SPACE ]]; then
        show_error "Insufficient disk space" "At least 1GB free space required. Check: df -h" ""
        exit 1
    fi

    log_success "System requirements check passed"
}

check_connectivity() {
    log_verbose "Checking internet connectivity..."
    if ! ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        show_error "No internet connectivity" "Required for package updates. Check: ping -c 1 8.8.8.8" ""
        if [[ "$OFFLINE_MODE" != true ]]; then
            exit 1
        fi
    fi
    log_debug "Internet connectivity confirmed"
}

# Backup functions
create_backup() {
    mkdir -p "$BACKUP_DIR"

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

    local total=${#files_to_backup[@]}
    local current=0

    log_verbose "Creating system backup..."

    for file in "${files_to_backup[@]}"; do
        ((current++))
        show_progress_bar $current $total "Backing up: ${file##*/}"

        if [[ -f "$file" ]]; then
            cp "$file" "$BACKUP_DIR/" 2>/dev/null || log_debug "Could not backup $file"
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

    echo
    log_success "Backup created at: $BACKUP_DIR"
}

# Hardening functions
update_system() {
    start_spinner "Updating system packages"

    # Update package list
    if execute_command "apt update -qq"; then
        stop_spinner "success" "Package list updated"
    else
        stop_spinner "error" "Failed to update package list"
        show_error "Package update failed" "apt update && apt upgrade -y" ""
        return 1
    fi

    # Upgrade packages
    start_spinner "Upgrading packages"
    if execute_command "DEBIAN_FRONTEND=noninteractive apt upgrade -y -qq"; then
        stop_spinner "success" "Packages upgraded"
    else
        stop_spinner "error" "Failed to upgrade packages"
        show_error "Package upgrade failed" "Check log for details" ""
        return 1
    fi

    # Clean up
    log_debug "Cleaning up old packages..."
    execute_command "apt autoremove -y >/dev/null 2>&1 || true"
    execute_command "apt autoclean >/dev/null 2>&1 || true"

    log_success "System updated successfully"
}

configure_firewall() {
    start_spinner "Configuring UFW firewall"

    # Check if UFW is installed
    if ! command -v ufw >/dev/null 2>&1; then
        log_debug "Installing UFW..."
        execute_command "apt install -y ufw"
    fi

    # Configure default policies
    execute_command "ufw --force reset >/dev/null 2>&1 || true"
    execute_command "ufw default deny incoming"
    execute_command "ufw default allow outgoing"

    # Allow SSH (ensure we don't lock ourselves out)
    execute_command "ufw allow OpenSSH"
    execute_command "ufw allow 22/tcp"

    # Enable logging
    execute_command "ufw logging medium"

    # Enable firewall
    if execute_command "ufw --force enable"; then
        stop_spinner "success" "UFW firewall configured and enabled"
    else
        stop_spinner "error" "Failed to enable UFW firewall"
        show_error "UFW configuration failed" "sudo ufw --force reset && sudo ufw enable" ""
        return 1
    fi

    log_debug "Firewall status: $(ufw status 2>/dev/null | grep Status | cut -d: -f2 | xargs || echo 'Unknown')"
}

disable_unnecessary_services() {
    local services_to_disable=(
        "avahi-daemon"
        "cups"
        "cups-browsed"
        "nfs-server"
        "rpcbind"
        "bluetooth"
        "cupsd"
    )

    local total=${#services_to_disable[@]}
    local current=0
    local disabled_count=0

    log_verbose "Disabling unnecessary services..."

    for service in "${services_to_disable[@]}"; do
        ((current++))
        show_progress_bar $current $total "Processing: $service"

        if systemctl is-enabled "$service" >/dev/null 2>&1; then
            if execute_command "systemctl disable $service 2>/dev/null" && \
               execute_command "systemctl stop $service 2>/dev/null"; then
                ((disabled_count++))
                log_debug "Disabled service: $service"
            else
                log_debug "Could not disable $service"
            fi
        fi
    done

    echo
    log_success "Disabled $disabled_count/${total} unnecessary services"
}

configure_password_policy() {
    start_spinner "Configuring password policies"

    # Ensure pwquality package is installed
    if ! dpkg -l | grep -q pwquality; then
        execute_command "apt install -y libpwquality-tools"
    fi

    # Configure pwquality
    local pwquality_file="/etc/security/pwquality.conf"

    # Backup original file
    execute_command "cp \"$pwquality_file\" \"$BACKUP_DIR/pwquality.conf.bak\" 2>/dev/null || true"

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
            execute_command "sed -i \"s/^#*$key.*/$policy/\" \"$pwquality_file\""
        else
            execute_command "echo \"$policy\" >> \"$pwquality_file\""
        fi
    done

    stop_spinner "success" "Password policies configured (min 14 chars, 4 classes)"
}

configure_auditd() {
    start_spinner "Configuring audit daemon"

    # Ensure auditd is installed
    if ! dpkg -l | grep -q auditd; then
        execute_command "apt install -y auditd"
    fi

    # Create auditd rules
    local audit_rules_file="/etc/audit/rules.d/hardening.rules"

    # Backup existing rules
    if [[ -f "$audit_rules_file" ]]; then
        execute_command "cp \"$audit_rules_file\" \"$BACKUP_DIR/audit_rules.bak\" 2>/dev/null || true"
    fi

    # Create comprehensive audit rules
    execute_command "cat > \"$audit_rules_file\" << 'EOF'
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
EOF"

    # Restart auditd
    if execute_command "systemctl restart auditd"; then
        stop_spinner "success" "Audit daemon configured and restarted"
    else
        stop_spinner "error" "Failed to restart auditd"
        show_error "Auditd restart failed" "systemctl restart auditd; auditctl -R $audit_rules_file" ""
        return 1
    fi

    # Load rules
    if execute_command "auditctl -R \"$audit_rules_file\" 2>/dev/null"; then
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
    find / -type f -perm -002 2>/dev/null | head -20 | while IFS= read -r file; do
        if [[ -f "$file" ]]; then
            chmod o-w "$file" 2>/dev/null || log_warning "Could not remove world-writable permission from $file"
        fi
    done

    log_success "File permissions configured"
}

configure_ssh_security() {
    # Interactive confirmation for SSH hardening
    if ! should_auto_confirm; then
        if ! confirm_dangerous "SSH password authentication will be disabled and root login blocked. Ensure you have SSH keys set up before proceeding!"; then
            log_warning "SSH hardening skipped by user"
            return 0
        fi
    fi

    start_spinner "Configuring SSH security settings"

    local ssh_config="/etc/ssh/sshd_config"

    # Backup SSH config
    execute_command "cp \"$ssh_config\" \"$BACKUP_DIR/sshd_config.bak\" 2>/dev/null || true"

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
            execute_command "sed -i \"s/^#\?$key.*/$setting/\" \"$ssh_config\""
        else
            execute_command "echo \"$setting\" >> \"$ssh_config\""
        fi
    done

    # Create SSH banner
    execute_command "cat > /etc/ssh/banner << 'EOF'
***************************************************************************
                            AUTHORIZED ACCESS ONLY
***************************************************************************
This system is for authorized users only. Individual use of this system
and/or network without authority, or in excess of your authority, is
strictly prohibited. Unauthorized access is a violation of state and
federal, civil and criminal laws.
***************************************************************************
EOF"

    # Test SSH configuration
    if execute_command "sshd -t"; then
        stop_spinner "success" "SSH configuration is valid"
    else
        stop_spinner "error" "SSH configuration has errors"
        show_error "SSH configuration test failed" "Review SSH configuration: cat /etc/ssh/sshd_config" ""
        return 1
    fi

    # Restart SSH service
    start_spinner "Restarting SSH service"
    if execute_command "systemctl restart sshd"; then
        stop_spinner "success" "SSH service restarted with secure configuration"
    else
        stop_spinner "error" "Failed to restart SSH service"
        show_error "SSH service restart failed" "systemctl restart sshd" ""
        return 1
    fi

    log_success "SSH hardening: Root login disabled, password auth disabled"
}

# System hardening verification
verify_hardening() {
    log_verbose "Verifying hardening implementation..."

    # Check UFW status
    if ufw status 2>/dev/null | grep -q "Status: active"; then
        add_verification_result "UFW Firewall" "ok" "Active and configured"
    else
        add_verification_result "UFW Firewall" "error" "Not active"
    fi

    # Check SSH configuration
    if grep -q "PermitRootLogin no" /etc/ssh/sshd_config 2>/dev/null; then
        add_verification_result "SSH Hardening" "ok" "Root login disabled"
    else
        add_verification_result "SSH Hardening" "error" "Root login enabled"
    fi

    if grep -q "PasswordAuthentication no" /etc/ssh/sshd_config 2>/dev/null; then
        add_verification_result "SSH Password Auth" "ok" "Disabled (key-based only)"
    else
        add_verification_result "SSH Password Auth" "warning" "Still enabled"
    fi

    # Check auditd status
    if systemctl is-active auditd >/dev/null 2>&1; then
        add_verification_result "Audit Daemon" "ok" "Running and configured"
    else
        add_verification_result "Audit Daemon" "error" "Not running"
    fi

    # Check password policy
    if grep -q "minlen = 14" /etc/security/pwquality.conf 2>/dev/null; then
        add_verification_result "Password Policy" "ok" "Min 14 chars, 4 classes"
    else
        add_verification_result "Password Policy" "error" "Not properly configured"
    fi

    # Check file permissions
    if [[ $(stat -c %a /etc/shadow 2>/dev/null) == "640" ]]; then
        add_verification_result "File Permissions" "ok" "Critical files secured"
    else
        add_verification_result "File Permissions" "warning" "Some files may need review"
    fi

    # Check unnecessary services
    local services_stopped=0
    for service in avahi-daemon cups nfs-server rpcbind; do
        if ! systemctl is-enabled "$service" >/dev/null 2>&1; then
            ((services_stopped++))
        fi
    done
    add_verification_result "Service Hardening" "ok" "Stopped $services_stopped unnecessary services"

    return 0
}

# Cleanup function
cleanup() {
    log_verbose "Performing cleanup..."

    # Remove any temporary files
    execute_command "rm -f /tmp/fortress-* 2>/dev/null || true"

    # Update file database
    execute_command "updatedb >/dev/null 2>&1 || true"

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

# Display usage information
show_usage() {
    cat << EOF
${BOLD}Fortress Linux - System Security Hardening Script${NC}

USAGE:
    $0 [OPTIONS] [COMMAND]

COMMANDS:
    (no command)    Run full hardening process
    restore <dir>   Restore from backup directory

OPTIONS:
    ${CYAN}--minimal${NC}              Enable minimal mode (resource-constrained systems)
    ${CYAN}--backup-skip${NC}          Skip backup creation
    ${CYAN}--skip-updates${NC}         Skip system package updates
    ${CYAN}--offline${NC}              Run in offline mode (no network calls)
    ${CYAN}--quiet, -q${NC}            Minimal output (errors only)
    ${CYAN}--verbose, -v${NC}          Detailed output
    ${CYAN}--debug, -vv${NC}           Very detailed with debug info
    ${CYAN}--yes, -y${NC}              Skip all confirmations (use with caution!)
    ${CYAN}--dry-run${NC}              Show what would be done without making changes
    ${CYAN}--threads NUM${NC}          Set number of parallel threads (default: 4)
    ${CYAN}--config FILE${NC}          Use custom configuration file
    ${CYAN}--help${NC}                 Show this help message

MINIMAL MODE EXAMPLES:
    # Core hardening only
    $0 --minimal

    # Minimal with no backup
    $0 --minimal --backup-skip

    # Offline minimal hardening
    $0 --minimal --offline --skip-updates

    # Auto-confirm for automation
    $0 --yes --verbose

    # Dry run to see what would change
    $0 --dry-run

EOF
}

# Parse command line arguments
parse_arguments() {
    # Parse UX arguments first
    parse_ux_arguments "$@"

    while [[ $# -gt 0 ]]; do
        case $1 in
            --minimal)
                MINIMAL_MODE=true
                SKIP_BACKUP=true
                THREADS=1
                set_verbosity "warning"
                log_verbose "Minimal mode enabled"
                shift
                ;;
            --backup-skip)
                SKIP_BACKUP=true
                log_verbose "Backup creation disabled"
                shift
                ;;
            --skip-updates)
                SKIP_UPDATES=true
                log_verbose "System updates skipped"
                shift
                ;;
            --offline)
                OFFLINE_MODE=true
                log_verbose "Offline mode enabled"
                shift
                ;;
            --threads)
                THREADS="$2"
                if ! [[ "$THREADS" =~ ^[0-9]+$ ]] || [[ "$THREADS" -lt 1 ]]; then
                    show_error "Invalid thread count" "Use a positive integer" ""
                    exit 1
                fi
                if [[ "$THREADS" -gt 16 ]]; then
                    show_error "Thread count too high" "Maximum 16 threads allowed (requested: $THREADS)" ""
                    exit 1
                fi
                log_verbose "Thread count set to: $THREADS"
                shift 2
                ;;
            --config)
                CUSTOM_CONFIG="$2"
                if [[ ! -f "$CUSTOM_CONFIG" ]]; then
                    show_error "Configuration file not found" "$CUSTOM_CONFIG does not exist" ""
                    exit 1
                fi
                log_verbose "Using custom configuration: $CUSTOM_CONFIG"
                shift 2
                ;;
            --help)
                show_usage
                exit 0
                ;;
            restore)
                if [[ -z "${2:-}" ]]; then
                    show_error "Restore command requires backup directory" "Usage: $0 restore <directory>" ""
                    show_usage
                    exit 1
                fi
                restore_from_backup "$2"
                exit 0
                ;;
            *)
                shift
                ;;
        esac
    done
}

# Main execution
main() {
    # Parse command line arguments
    parse_arguments "$@"

    # Display header
    print_header "🛡️ Fortress Linux - System Security Hardening"

    echo
    log_always "Log file: $LOG_FILE"
    if [[ "$SKIP_BACKUP" != true ]]; then
        log_always "Backup directory: $BACKUP_DIR"
    fi

    if [[ "$MINIMAL_MODE" == true ]]; then
        log_always "${YELLOW}Running in MINIMAL MODE${NC}"
    fi

    if is_dry_run; then
        log_always "${YELLOW}Running in DRY-RUN mode - no changes will be made${NC}"
    fi

    echo

    # Define hardening steps
    declare -a HARDENING_STEPS=()
    if [[ "$OFFLINE_MODE" != true ]]; then
        HARDENING_STEPS+=("check_connectivity:Network connectivity")
    fi
    HARDENING_STEPS+=("check_system_requirements:System requirements")
    if [[ "$SKIP_BACKUP" != true ]]; then
        HARDENING_STEPS+=("create_backup:Creating backup")
    fi
    if [[ "$SKIP_UPDATES" != true ]]; then
        HARDENING_STEPS+=("update_system:Updating packages")
    fi
    HARDENING_STEPS+=("configure_firewall:Configuring firewall")
    if [[ "$MINIMAL_MODE" != true ]]; then
        HARDENING_STEPS+=("disable_unnecessary_services:Disabling services")
    fi
    HARDENING_STEPS+=("configure_password_policy:Configuring passwords")
    if [[ "$MINIMAL_MODE" != true ]]; then
        HARDENING_STEPS+=("configure_auditd:Configuring auditd")
    fi
    HARDENING_STEPS+=("configure_file_permissions:Securing files")
    HARDENING_STEPS+=("configure_ssh_security:Hardening SSH")
    HARDENING_STEPS+=("verify_hardening:Verification")
    HARDENING_STEPS+=("cleanup:Cleanup")

    TOTAL_STEPS=${#HARDENING_STEPS[@]}
    CURRENT_STEP=0

    # Pre-flight checks (not counted in steps)
    print_section "Pre-flight Checks"
    check_root_privileges

    # Execute hardening steps
    print_section "System Hardening"
    echo

    for step in "${HARDENING_STEPS[@]}"; do
        ((CURRENT_STEP++))
        local step_func="${step%%:*}"
        local step_name="${step##*:}"

        show_step $CURRENT_STEP $TOTAL_STEPS "$step_name ($(estimate_operation_time $step_func))"

        if $step_func; then
            log_success "$step_name completed"
        else
            log_error "$step_name failed"
            if ! should_auto_confirm; then
                show_recovery_menu "$step_name"
            else
                echo "Auto-confirm enabled, aborting..."
                exit 1
            fi
        fi

        echo
    done

    # Calculate duration
    local end_time=$(date +%s)
    local duration=$((end_time - START_TIME))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))
    local duration_str="${minutes}m ${seconds}s"
    if [[ $minutes -eq 0 ]]; then
        duration_str="${seconds}s"
    fi

    # Display completion dashboard
    local backup_path=""
    if [[ "$SKIP_BACKUP" != true ]]; then
        backup_path="$BACKUP_DIR"
    fi

    show_completion_dashboard "$duration_str" "$TOTAL_STEPS" "$backup_path"

    log_success "Fortress Linux hardening completed successfully!"
}

# Execute main function
main "$@"