#!/bin/bash

# Fortress Linux - Backup and Restore Utility
# Comprehensive system configuration backup and restoration

set -euo pipefail

# Configuration variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_ROOT_DIR="/etc/fortress-backups"
LOG_FILE="/var/log/fortress-backup-restore.log"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
CURRENT_BACKUP_DIR="$BACKUP_ROOT_DIR/$TIMESTAMP"

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
    exit 1
}

trap 'handle_error $LINENO' ERR

# Help function
show_help() {
    cat << EOF
Fortress Linux - Backup and Restore Utility

USAGE:
    $0 [COMMAND] [OPTIONS]

COMMANDS:
    backup               Create a full system backup
    restore <backup_id>  Restore from a specific backup
    list                 List available backups
    verify <backup_id>   Verify backup integrity
    clean <days>         Remove backups older than specified days

OPTIONS:
    -h, --help          Show this help message
    -v, --verbose       Enable verbose output
    -q, --quiet         Suppress non-error output
    --config-only       Backup/restore only configuration files
    --include-logs      Include log files in backup
    --compress          Compress backup with tar.gz

EXAMPLES:
    $0 backup                           # Create full backup
    $0 backup --config-only             # Backup configs only
    $0 restore 20241201_143022          # Restore from specific backup
    $0 list                             # List all backups
    $0 verify 20241201_143022           # Verify backup integrity
    $0 clean 30                         # Remove backups older than 30 days

EOF
}

# Check root privileges
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        exit 1
    fi
}

# Create backup directory structure
create_backup_dirs() {
    local backup_dir="$1"
    mkdir -p "$backup_dir"/{config,logs,scripts,system,users,packages,network}

    # Create metadata file
    cat > "$backup_dir/metadata.json" << EOF
{
    "backup_id": "$(basename "$backup_dir")",
    "created_at": "$(date -Iseconds)",
    "hostname": "$(hostname)",
    "os_release": "$(lsb_release -d 2>/dev/null || echo 'Unknown')",
    "kernel_version": "$(uname -r)",
    "script_version": "1.0.0",
    "backup_type": "full",
    "created_by": "fortress-backup-restore.sh"
}
EOF

    log_success "Backup directory structure created: $backup_dir"
}

# Backup system configuration files
backup_configs() {
    local backup_dir="$1"
    local config_dir="$backup_dir/config"

    log_info "Backing up system configuration files..."

    # Core system configurations
    local config_files=(
        "/etc/passwd"
        "/etc/group"
        "/etc/shadow"
        "/etc/gshadow"
        "/etc/fstab"
        "/etc/hosts"
        "/etc/hostname"
        "/etc/resolv.conf"
        "/etc/ssh/sshd_config"
        "/etc/ssh/ssh_config"
        "/etc/security/pwquality.conf"
        "/etc/security/limits.conf"
        "/etc/login.defs"
        "/etc/issue"
        "/etc/issue.net"
        "/etc/motd"
        "/etc/sysctl.conf"
        "/etc/audit/auditd.conf"
        "/etc/audit/rules.d"
        "/etc/ufw"
        "/etc/fail2ban"
        "/etc/logrotate.conf"
        "/etc/cron.allow"
        "/etc/cron.deny"
        "/etc/at.allow"
        "/etc/at.deny"
        "/etc/sudoers"
        "/etc/sudoers.d"
    )

    for file_path in "${config_files[@]}"; do
        if [[ -e "$file_path" ]]; then
            local dest_path="$config_dir${file_path}"
            local dest_dir=$(dirname "$dest_path")
            mkdir -p "$dest_dir"
            cp -r "$file_path" "$dest_path" 2>/dev/null || log_warning "Could not backup $file_path"
        fi
    done

    # Backup systemd services
    if [[ -d "/etc/systemd/system" ]]; then
        find /etc/systemd/system -name "*.service" -o -name "*.timer" | head -50 | while read service; do
            if [[ -f "$service" ]]; then
                local service_path="$config_dir/systemd$service"
                local service_dir=$(dirname "$service_path")
                mkdir -p "$service_dir"
                cp "$service" "$service_path" 2>/dev/null || true
            fi
        done
    fi

    log_success "Configuration files backed up"
}

# Backup network configuration
backup_network() {
    local backup_dir="$1"
    local network_dir="$backup_dir/network"

    log_info "Backing up network configuration..."

    # Network configuration files
    local network_files=(
        "/etc/netplan"
        "/etc/network/interfaces"
        "/etc/network/interfaces.d"
        "/etc/hostname"
        "/etc/hosts"
        "/etc/resolv.conf"
        "/etc/systemd/network"
    )

    for file_path in "${network_files[@]}"; do
        if [[ -e "$file_path" ]]; then
            local dest_path="$network_dir${file_path}"
            local dest_dir=$(dirname "$dest_path")
            mkdir -p "$dest_dir"
            cp -r "$file_path" "$dest_path" 2>/dev/null || log_warning "Could not backup $file_path"
        fi
    done

    # Network interfaces information
    ip addr show > "$network_dir/ip_addr.txt" 2>/dev/null || true
    ip route show > "$network_dir/ip_route.txt" 2>/dev/null || true
    ip -6 addr show > "$network_dir/ip6_addr.txt" 2>/dev/null || true

    log_success "Network configuration backed up"
}

# Backup user information
backup_users() {
    local backup_dir="$1"
    local users_dir="$backup_dir/users"

    log_info "Backing up user information..."

    # User home directories (config only, not data)
    getent passwd | grep -E ':[0-9]{4,}:' | cut -d: -f1 | while read user; do
        if [[ "$user" != "root" && "$user" != "nobody" ]]; then
            local home_dir=$(getent passwd "$user" | cut -d: -f6)
            if [[ -d "$home_dir" && "$home_dir" != "/nonexistent" ]]; then
                # Backup only config files, not user data
                local config_files=(
                    "$home_dir/.bashrc"
                    "$home_dir/.profile"
                    "$home_dir/.bash_profile"
                    "$home_dir/.ssh/authorized_keys"
                    "$home_dir/.ssh/config"
                    "$home_dir/.ssh/id_rsa.pub"
                    "$home_dir/.ssh/id_ed25519.pub"
                )

                for config_file in "${config_files[@]}"; do
                    if [[ -f "$config_file" ]]; then
                        local user_config_dir="$users_dir/$user$(dirname "$config_file")"
                        mkdir -p "$user_config_dir"
                        cp "$config_file" "$user_config_dir/" 2>/dev/null || true
                    fi
                done
            fi
        fi
    done

    # Group information
    getent group > "$users_dir/groups.txt" 2>/dev/null || true
    getent passwd > "$users_dir/passwd.txt" 2>/dev/null || true

    log_success "User information backed up"
}

# Backup installed packages
backup_packages() {
    local backup_dir="$1"
    local packages_dir="$backup_dir/packages"

    log_info "Backing up package information..."

    # Debian/Ubuntu package information
    if command -v dpkg >/dev/null 2>&1; then
        dpkg --get-selections > "$packages_dir/dpkg-selections.txt" 2>/dev/null || true
        apt-mark showmanual > "$packages_dir/manual-packages.txt" 2>/dev/null || true
        apt-mark showauto > "$packages_dir/auto-packages.txt" 2>/dev/null || true
        dpkg -l > "$packages_dir/installed-packages.txt" 2>/dev/null || true

        # Repository configuration
        cp -r /etc/apt/sources.list* "$packages_dir/" 2>/dev/null || true
        cp -r /etc/apt/sources.list.d "$packages_dir/" 2>/dev/null || true
        cp -r /etc/apt/trusted.gpg.d "$packages_dir/" 2>/dev/null || true
        apt-key exportall > "$packages_dir/apt-keys.txt" 2>/dev/null || true
    fi

    # Snap packages
    if command -v snap >/dev/null 2>&1; then
        snap list > "$packages_dir/snap-packages.txt" 2>/dev/null || true
    fi

    # Flatpak packages
    if command -v flatpak >/dev/null 2>&1; then
        flatpak list > "$packages_dir/flatpak-packages.txt" 2>/dev/null || true
    fi

    log_success "Package information backed up"
}

# Backup system state
backup_system_state() {
    local backup_dir="$1"
    local system_dir="$backup_dir/system"

    log_info "Backing up system state..."

    # System information
    uname -a > "$system_dir/uname.txt" 2>/dev/null || true
    lsb_release -a > "$system_dir/lsb-release.txt" 2>/dev/null || true
    cat /etc/os-release > "$system_dir/os-release.txt" 2>/dev/null || true

    # Disk information
    df -h > "$system_dir/disk-usage.txt" 2>/dev/null || true
    fdisk -l > "$system_dir/disk-partitions.txt" 2>/dev/null || true
    lsblk > "$system_dir/block-devices.txt" 2>/dev/null || true

    # Memory information
    free -h > "$system_dir/memory.txt" 2>/dev/null || true
    cat /proc/meminfo > "$system_dir/meminfo.txt" 2>/dev/null || true

    # Process information
    ps aux > "$system_dir/processes.txt" 2>/dev/null || true
    systemctl list-units --type=service --state=running > "$system_dir/running-services.txt" 2>/dev/null || true

    # System log (last 1000 lines)
    tail -1000 /var/log/syslog > "$system_dir/syslog.txt" 2>/dev/null || true
    tail -1000 /var/log/auth.log > "$system_dir/auth.log" 2>/dev/null || true

    log_success "System state backed up"
}

# Backup logs (optional)
backup_logs() {
    local backup_dir="$1"
    local logs_dir="$backup_dir/logs"

    log_info "Backing up system logs..."

    # Important log files
    local log_files=(
        "/var/log/auth.log"
        "/var/log/syslog"
        "/var/log/kern.log"
        "/var/log/daemon.log"
        "/var/log/mail.log"
        "/var/log/user.log"
        "/var/log/dmesg"
        "/var/log/ufw.log"
        "/var/log/audit/audit.log"
        "/var/log/fail2ban.log"
    )

    for log_file in "${log_files[@]}"; do
        if [[ -f "$log_file" ]]; then
            # Copy only last 500 lines to save space
            tail -500 "$log_file" > "$logs_dir$(basename "$log_file").txt" 2>/dev/null || true
        fi
    done

    log_success "System logs backed up"
}

# Compress backup
compress_backup() {
    local backup_dir="$1"
    local archive_name="$(basename "$backup_dir").tar.gz"
    local archive_path="$BACKUP_ROOT_DIR/$archive_name"

    log_info "Compressing backup..."

    cd "$BACKUP_ROOT_DIR"
    tar -czf "$archive_path" -C "$BACKUP_ROOT_DIR" "$(basename "$backup_dir")"

    if [[ $? -eq 0 ]]; then
        log_success "Backup compressed: $archive_path"
        log_info "Original size: $(du -sh "$backup_dir" | cut -f1)"
        log_info "Compressed size: $(du -sh "$archive_path" | cut -f1)"

        # Remove uncompressed directory
        rm -rf "$backup_dir"
        log_info "Uncompressed backup directory removed"

        echo "$archive_path"
    else
        log_error "Failed to compress backup"
        return 1
    fi
}

# Create backup
create_backup() {
    local config_only=false
    local include_logs=false
    local compress=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --config-only)
                config_only=true
                shift
                ;;
            --include-logs)
                include_logs=true
                shift
                ;;
            --compress)
                compress=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                return 1
                ;;
        esac
    done

    log_info "Starting backup process..."
    log_info "Backup directory: $CURRENT_BACKUP_DIR"

    # Create backup directory structure
    create_backup_dirs "$CURRENT_BACKUP_DIR"

    # Perform backup operations
    backup_configs "$CURRENT_BACKUP_DIR"

    if [[ "$config_only" != "true" ]]; then
        backup_network "$CURRENT_BACKUP_DIR"
        backup_users "$CURRENT_BACKUP_DIR"
        backup_packages "$CURRENT_BACKUP_DIR"
        backup_system_state "$CURRENT_BACKUP_DIR"

        if [[ "$include_logs" == "true" ]]; then
            backup_logs "$CURRENT_BACKUP_DIR"
        fi
    fi

    # Create backup summary
    local backup_size=$(du -sh "$CURRENT_BACKUP_DIR" | cut -f1)
    local file_count=$(find "$CURRENT_BACKUP_DIR" -type f | wc -l)

    cat > "$CURRENT_BACKUP_DIR/backup_summary.txt" << EOF
Backup Summary
=============
Backup ID: $(basename "$CURRENT_BACKUP_DIR")
Created: $(date)
Hostname: $(hostname)
Total Size: $backup_size
Files Backed Up: $file_count
Backup Type: $([ "$config_only" == "true" ] && echo "Config Only" || echo "Full")
Logs Included: $([ "$include_logs" == "true" ] && echo "Yes" || echo "No")

Backup Contents:
$(find "$CURRENT_BACKUP_DIR" -type d -name ".*" -prune -o -type d -print | sed 's|.*/||' | sort)
EOF

    # Compress if requested
    if [[ "$compress" == "true" ]]; then
        local archive_path=$(compress_backup "$CURRENT_BACKUP_DIR")
        echo "$archive_path"
    else
        echo "$CURRENT_BACKUP_DIR"
    fi

    log_success "Backup completed successfully!"
    log_info "Backup location: $CURRENT_BACKUP_DIR"
}

# List available backups
list_backups() {
    log_info "Available backups:"

    if [[ ! -d "$BACKUP_ROOT_DIR" ]]; then
        log_warning "No backup directory found"
        return 0
    fi

    # Find backup directories and archives
    find "$BACKUP_ROOT_DIR" -maxdepth 1 -type d -name "????????_??????" -o -name "????????_??????.tar.gz" | sort -r | while read backup; do
        local backup_name=$(basename "$backup")
        local backup_type="Directory"

        if [[ "$backup" == *.tar.gz ]]; then
            backup_type="Archive"
        fi

        if [[ -f "$backup/metadata.json" ]]; then
            local created_at=$(jq -r '.created_at' "$backup/metadata.json" 2>/dev/null || echo "Unknown")
            local hostname=$(jq -r '.hostname' "$backup/metadata.json" 2>/dev/null || echo "Unknown")
            local size=$(du -sh "$backup" | cut -f1)

            echo "  $backup_name ($backup_type) - $size"
            echo "    Created: $created_at"
            echo "    Hostname: $hostname"
            echo
        else
            local size=$(du -sh "$backup" | cut -f1)
            echo "  $backup_name ($backup_type) - $size"
            echo "    Created: Unknown"
            echo
        fi
    done
}

# Restore from backup
restore_backup() {
    local backup_id="$1"
    local backup_path="$BACKUP_ROOT_DIR/$backup_id"
    local temp_extract_dir="/tmp/fortress-restore-$$"

    if [[ -z "$backup_id" ]]; then
        log_error "Backup ID required"
        return 1
    fi

    # Check if backup exists
    if [[ ! -e "$backup_path" ]]; then
        log_error "Backup not found: $backup_id"
        return 1
    fi

    log_info "Starting restore from backup: $backup_id"

    # Extract if it's an archive
    if [[ "$backup_path" == *.tar.gz ]]; then
        log_info "Extracting backup archive..."
        mkdir -p "$temp_extract_dir"
        tar -xzf "$backup_path" -C "$temp_extract_dir"
        backup_path="$temp_extract_dir/$backup_id"
    fi

    if [[ ! -d "$backup_path" ]]; then
        log_error "Invalid backup directory"
        return 1
    fi

    # Verify backup
    if [[ ! -f "$backup_path/metadata.json" ]]; then
        log_warning "No metadata found, proceeding anyway"
    else
        local backup_hostname=$(jq -r '.hostname' "$backup_path/metadata.json" 2>/dev/null || echo "Unknown")
        local current_hostname=$(hostname)

        if [[ "$backup_hostname" != "$current_hostname" ]]; then
            log_warning "Backup hostname ($backup_hostname) differs from current hostname ($current_hostname)"
            read -p "Continue anyway? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log_info "Restore cancelled"
                return 0
            fi
        fi
    fi

    # Restore configuration files
    if [[ -d "$backup_path/config" ]]; then
        log_info "Restoring configuration files..."

        # Important configs to restore
        local important_configs=(
            "etc/ssh/sshd_config"
            "etc/security/pwquality.conf"
            "etc/audit/auditd.conf"
            "etc/audit/rules.d"
            "etc/ufw"
            "etc/fail2ban"
            "etc/sudoers"
            "etc/sudoers.d"
        )

        for config in "${important_configs[@]}"; do
            local source="$backup_path/config/$config"
            local target="/$config"

            if [[ -e "$source" ]]; then
                # Create backup of current config
                if [[ -e "$target" ]]; then
                    cp "$target" "$target.fortress-restore-$(date +%Y%m%d_%H%M%S).bak" || log_warning "Could not backup $target"
                fi

                # Restore config
                cp -r "$source" "$target" 2>/dev/null || log_warning "Could not restore $config"
            fi
        done
    fi

    # Restart critical services
    log_info "Restarting services..."
    systemctl restart sshd 2>/dev/null || log_warning "Could not restart SSH service"
    systemctl restart auditd 2>/dev/null || log_warning "Could not restart auditd service"
    systemctl restart ufw 2>/dev/null || log_warning "Could not restart UFW service"

    # Cleanup
    if [[ -d "$temp_extract_dir" ]]; then
        rm -rf "$temp_extract_dir"
    fi

    log_success "Restore completed successfully!"
    log_warning "Please review restored configurations and restart services as needed"
}

# Verify backup integrity
verify_backup() {
    local backup_id="$1"
    local backup_path="$BACKUP_ROOT_DIR/$backup_id"
    local temp_extract_dir="/tmp/fortress-verify-$$"

    if [[ -z "$backup_id" ]]; then
        log_error "Backup ID required"
        return 1
    fi

    log_info "Verifying backup: $backup_id"

    # Check if backup exists
    if [[ ! -e "$backup_path" ]]; then
        log_error "Backup not found: $backup_id"
        return 1
    fi

    # Extract if it's an archive
    if [[ "$backup_path" == *.tar.gz ]]; then
        log_info "Extracting backup for verification..."
        mkdir -p "$temp_extract_dir"
        tar -xzf "$backup_path" -C "$temp_extract_dir" 2>/dev/null || {
            log_error "Failed to extract backup archive"
            return 1
        }
        backup_path="$temp_extract_dir/$backup_id"
    fi

    local verification_failed=false

    # Check essential files
    local essential_files=(
        "metadata.json"
        "config/etc/passwd"
        "config/etc/group"
        "config/etc/ssh/sshd_config"
    )

    for file in "${essential_files[@]}"; do
        if [[ ! -f "$backup_path/$file" ]]; then
            log_error "Missing essential file: $file"
            verification_failed=true
        fi
    done

    # Verify metadata
    if [[ -f "$backup_path/metadata.json" ]]; then
        if ! python3 -m json.tool "$backup_path/metadata.json" >/dev/null 2>&1; then
            log_error "Invalid JSON in metadata.json"
            verification_failed=true
        fi
    fi

    # Check file integrity (basic)
    find "$backup_path" -type f | head -10 | while read file; do
        if [[ ! -s "$file" ]]; then
            log_warning "Empty file found: $file"
        fi
    done

    # Cleanup
    if [[ -d "$temp_extract_dir" ]]; then
        rm -rf "$temp_extract_dir"
    fi

    if [[ "$verification_failed" == "true" ]]; then
        log_error "Backup verification failed"
        return 1
    else
        log_success "Backup verification passed"
        return 0
    fi
}

# Clean old backups
clean_backups() {
    local days="$1"

    if [[ -z "$days" || ! "$days" =~ ^[0-9]+$ ]]; then
        log_error "Valid number of days required"
        return 1
    fi

    log_info "Cleaning backups older than $days days..."

    local cutoff_date=$(date -d "$days days ago" +%Y%m%d)
    local cleaned_count=0

    # Find and remove old backup directories
    find "$BACKUP_ROOT_DIR" -maxdepth 1 -type d -name "????????_??????" | while read backup_dir; do
        local backup_name=$(basename "$backup_dir")
        local backup_date=${backup_name:0:8}

        if [[ "$backup_date" < "$cutoff_date" ]]; then
            log_info "Removing old backup: $backup_name"
            rm -rf "$backup_dir" || log_warning "Could not remove $backup_dir"
            ((cleaned_count++))
        fi
    done

    # Find and remove old backup archives
    find "$BACKUP_ROOT_DIR" -maxdepth 1 -type f -name "????????_??????.tar.gz" | while read backup_file; do
        local backup_name=$(basename "$backup_file" .tar.gz)
        local backup_date=${backup_name:0:8}

        if [[ "$backup_date" < "$cutoff_date" ]]; then
            log_info "Removing old backup archive: $backup_name.tar.gz"
            rm -f "$backup_file" || log_warning "Could not remove $backup_file"
            ((cleaned_count++))
        fi
    done

    log_success "Cleaned $cleaned_count old backups"
}

# Main function
main() {
    local command=""
    local verbose=false
    local quiet=false

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            -q|--quiet)
                quiet=true
                shift
                ;;
            backup|restore|list|verify|clean)
                command="$1"
                shift
                break
                ;;
            *)
                log_error "Unknown command: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # Check root privileges for most operations
    case "$command" in
        backup|restore|clean)
            check_root
            ;;
    esac

    # Create backup directory if it doesn't exist
    if [[ "$command" == "backup" ]]; then
        mkdir -p "$BACKUP_ROOT_DIR"
    fi

    # Execute command
    case "$command" in
        backup)
            create_backup "$@"
            ;;
        restore)
            restore_backup "$1"
            ;;
        list)
            list_backups
            ;;
        verify)
            verify_backup "$1"
            ;;
        clean)
            clean_backups "$1"
            ;;
        *)
            log_error "No command specified"
            show_help
            exit 1
            ;;
    esac
}

# Execute main function
main "$@"