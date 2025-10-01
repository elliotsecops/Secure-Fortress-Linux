#!/bin/bash

# Fortress Linux - Automated Backup Scheduling Script
# Provides automated backup scheduling with configurable retention policies

set -euo pipefail

# Configuration variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/var/log/fortress-backup-scheduler.log"
CONFIG_FILE="/etc/fortress-backup-scheduler.conf"
CRON_FILE="/etc/cron.d/fortress-backup-scheduler"
LOCK_FILE="/var/lock/fortress-backup-scheduler.lock"

# Default configuration
DEFAULT_SCHEDULE="0 2 * * *"  # Daily at 2 AM
DEFAULT_RETENTION_DAYS=30
DEFAULT_COMPRESSION=true
DEFAULT_CONFIG_ONLY=false
DEFAULT_EMAIL_NOTIFICATIONS=false
DEFAULT_MAX_BACKUP_SIZE="1G"

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
    local log_message="[$timestamp] [$level] $message"

    echo "$log_message"

    # Try to write to log file, but don't fail if we can't
    echo "$log_message" >> "$LOG_FILE" 2>/dev/null || true
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

# Display usage information
show_usage() {
    cat << EOF
Fortress Linux - Automated Backup Scheduling

USAGE:
    $0 [COMMAND] [OPTIONS]

COMMANDS:
    install         Install backup scheduler with default settings
    uninstall       Remove backup scheduler and all scheduled backups
    status          Show current scheduler status and configuration
    enable          Enable automated backups
    disable         Disable automated backups
    run             Run backup immediately (manual trigger)
    configure       Interactive configuration setup
    test            Test backup configuration without scheduling

OPTIONS:
    --schedule CRON        Set backup schedule (default: "$DEFAULT_SCHEDULE")
    --retention DAYS       Set retention period in days (default: $DEFAULT_RETENTION_DAYS)
    --compress             Enable compression (default: enabled)
    --config-only          Backup configuration only (default: full backup)
    --max-size SIZE        Maximum backup size (default: $DEFAULT_MAX_BACKUP_SIZE)
    --email EMAIL          Enable email notifications
    --dry-run              Show what would be done without executing
    --help                 Show this help message

SCHEDULE EXAMPLES:
    "0 2 * * *"      - Daily at 2 AM
    "0 2 * * 0"      - Weekly on Sunday at 2 AM
    "0 2 1 * *"      - Monthly on 1st at 2 AM
    "*/6 * * *"      - Every 6 hours
    "0 */4 * * *"    - Every 4 hours

CONFIGURATION EXAMPLES:
    # Install with weekly backups and 60-day retention
    $0 install --schedule "0 2 * * 0" --retention 60

    # Install with hourly backups, config only, and 100MB max size
    $0 install --schedule "0 * * * *" --config-only --max-size 100M

    # Install with daily backups and email notifications
    $0 install --email admin@example.com

    # Run backup immediately
    $0 run

EOF
}

# Load configuration from file
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
        log_info "Configuration loaded from: $CONFIG_FILE"
    else
        log_info "Using default configuration"
        SCHEDULE="$DEFAULT_SCHEDULE"
        RETENTION_DAYS="$DEFAULT_RETENTION_DAYS"
        COMPRESSION="$DEFAULT_COMPRESSION"
        CONFIG_ONLY="$DEFAULT_CONFIG_ONLY"
        EMAIL_NOTIFICATIONS="$DEFAULT_EMAIL_NOTIFICATIONS"
        MAX_BACKUP_SIZE="$DEFAULT_MAX_BACKUP_SIZE"
        EMAIL_ADDRESS=""
    fi
}

# Save configuration to file
save_config() {
    cat > "$CONFIG_FILE" << EOF
# Fortress Linux Backup Scheduler Configuration
# Generated on $(date)

# Backup schedule (cron format)
SCHEDULE="$SCHEDULE"

# Retention period in days
RETENTION_DAYS="$RETENTION_DAYS"

# Enable compression
COMPRESSION="$COMPRESSION"

# Backup configuration only
CONFIG_ONLY="$CONFIG_ONLY"

# Maximum backup size
MAX_BACKUP_SIZE="$MAX_BACKUP_SIZE"

# Email notifications
EMAIL_NOTIFICATIONS="$EMAIL_NOTIFICATIONS"
EMAIL_ADDRESS="$EMAIL_ADDRESS"

# Backup script location
BACKUP_SCRIPT="$SCRIPT_DIR/backup_restore.sh"

# Log file location
LOG_FILE="$LOG_FILE"

EOF
    chmod 600 "$CONFIG_FILE"
    log_success "Configuration saved to: $CONFIG_FILE"
}

# Validate cron schedule format
validate_cron_schedule() {
    local schedule="$1"

    # Basic validation - check for 5 fields
    if [[ $(echo "$schedule" | wc -w) -ne 5 ]]; then
        log_error "Invalid cron schedule format: $schedule"
        log_error "Expected format: \"minute hour day month weekday\""
        log_error "Example: \"0 2 * * *\" (daily at 2 AM)"
        return 1
    fi

    # Check for valid characters
    if [[ ! "$schedule" =~ ^[0-9*\/,\-]+$ ]]; then
        log_error "Invalid characters in cron schedule: $schedule"
        return 1
    fi

    return 0
}

# Validate retention period
validate_retention() {
    local days="$1"

    if ! [[ "$days" =~ ^[0-9]+$ ]] || [[ "$days" -lt 1 ]] || [[ "$days" -gt 365 ]]; then
        log_error "Invalid retention period: $days"
        log_error "Must be a number between 1 and 365 days"
        return 1
    fi

    return 0
}

# Validate backup size
validate_backup_size() {
    local size="$1"

    # Check for valid format (number + optional unit)
    if [[ ! "$size" =~ ^[0-9]+[KMGT]?$ ]]; then
        log_error "Invalid backup size format: $size"
        log_error "Expected format: number with optional unit (K, M, G, T)"
        log_error "Examples: 100M, 1G, 500K"
        return 1
    fi

    return 0
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        return 1
    fi

    # Check if backup script exists
    if [[ ! -f "$SCRIPT_DIR/backup_restore.sh" ]]; then
        log_error "Backup script not found: $SCRIPT_DIR/backup_restore.sh"
        return 1
    fi

    # Check if cron is available
    if ! command -v cron >/dev/null 2>&1 && ! command -v crond >/dev/null 2>&1; then
        log_error "Cron daemon not found. Please install cron."
        return 1
    fi

    # Check if log directory exists
    local log_dir=$(dirname "$LOG_FILE")
    if [[ ! -d "$log_dir" ]]; then
        mkdir -p "$log_dir"
        log_info "Created log directory: $log_dir"
    fi

    # Check if backup directory exists
    if [[ ! -d "/etc/fortress-backups" ]]; then
        mkdir -p "/etc/fortress-backups"
        log_info "Created backup directory: /etc/fortress-backups"
    fi

    log_success "Prerequisites check passed"
    return 0
}

# Create cron job
create_cron_job() {
    log_info "Creating cron job..."

    # Build backup command with options
    local backup_cmd="$SCRIPT_DIR/backup_restore.sh backup"

    if [[ "$COMPRESSION" == true ]]; then
        backup_cmd="$backup_cmd --compress"
    fi

    if [[ "$CONFIG_ONLY" == true ]]; then
        backup_cmd="$backup_cmd --config-only"
    fi

    # Add size limit if specified
    if [[ -n "$MAX_BACKUP_SIZE" && "$MAX_BACKUP_SIZE" != "0" ]]; then
        backup_cmd="$backup_cmd --max-size $MAX_BACKUP_SIZE"
    fi

    # Add cleanup command
    local cleanup_cmd="$SCRIPT_DIR/backup_restore.sh clean $RETENTION_DAYS"

    # Create cron file
    cat > "$CRON_FILE" << EOF
# Fortress Linux Automated Backup Scheduler
# Generated on $(date)
# Schedule: $SCHEDULE
# Retention: $RETENTION_DAYS days

# Backup command
$SCHEDULE root $backup_cmd >> $LOG_FILE 2>&1

# Cleanup command (runs 30 minutes after backup)
$(echo "$SCHEDULE" | awk '{print $1" "$2+1" "$3" "$4" "$5}') root $cleanup_cmd >> $LOG_FILE 2>&1

EOF

    # Set proper permissions
    chmod 644 "$CRON_FILE"

    log_success "Cron job created: $CRON_FILE"

    # Reload cron
    if command -v systemctl >/dev/null 2>&1; then
        systemctl reload cron 2>/dev/null || systemctl reload crond 2>/dev/null || true
    else
        kill -HUP $(cat /var/run/crond.pid 2>/dev/null) 2>/dev/null || true
    fi

    log_success "Cron daemon reloaded"
}

# Remove cron job
remove_cron_job() {
    log_info "Removing cron job..."

    if [[ -f "$CRON_FILE" ]]; then
        rm -f "$CRON_FILE"
        log_success "Cron job removed: $CRON_FILE"

        # Reload cron
        if command -v systemctl >/dev/null 2>&1; then
            systemctl reload cron 2>/dev/null || systemctl reload crond 2>/dev/null || true
        else
            kill -HUP $(cat /var/run/crond.pid 2>/dev/null) 2>/dev/null || true
        fi

        log_success "Cron daemon reloaded"
    else
        log_warning "Cron file not found: $CRON_FILE"
    fi
}

# Run backup immediately
run_backup() {
    log_info "Running backup immediately..."

    # Create lock file to prevent concurrent backups
    if [[ -f "$LOCK_FILE" ]]; then
        log_warning "Backup already in progress (lock file exists)"
        return 1
    fi

    # Create lock file
    touch "$LOCK_FILE"

    # Build backup command
    local backup_cmd="$SCRIPT_DIR/backup_restore.sh backup"

    if [[ "$COMPRESSION" == true ]]; then
        backup_cmd="$backup_cmd --compress"
    fi

    if [[ "$CONFIG_ONLY" == true ]]; then
        backup_cmd="$backup_cmd --config-only"
    fi

    # Add size limit if specified
    if [[ -n "$MAX_BACKUP_SIZE" && "$MAX_BACKUP_SIZE" != "0" ]]; then
        backup_cmd="$backup_cmd --max-size $MAX_BACKUP_SIZE"
    fi

    # Run backup
    log_info "Executing: $backup_cmd"
    if $backup_cmd; then
        log_success "Manual backup completed successfully"

        # Send notification if configured
        if [[ "$EMAIL_NOTIFICATIONS" == true && -n "$EMAIL_ADDRESS" ]]; then
            echo "Fortress Linux backup completed successfully at $(date)" | \
                mail -s "Fortress Linux Backup Success" "$EMAIL_ADDRESS" 2>/dev/null || \
                log_warning "Failed to send email notification"
        fi
    else
        log_error "Manual backup failed"

        # Send notification if configured
        if [[ "$EMAIL_NOTIFICATIONS" == true && -n "$EMAIL_ADDRESS" ]]; then
            echo "Fortress Linux backup failed at $(date). Check logs: $LOG_FILE" | \
                mail -s "Fortress Linux Backup FAILED" "$EMAIL_ADDRESS" 2>/dev/null || \
                log_warning "Failed to send email notification"
        fi
        return 1
    fi

    # Remove lock file
    rm -f "$LOCK_FILE"

    return 0
}

# Show current status
show_status() {
    log_info "Backup Scheduler Status"
    echo "=========================="

    if [[ -f "$CONFIG_FILE" ]]; then
        echo "Configuration file: $CONFIG_FILE"
        echo "Schedule: $SCHEDULE"
        echo "Retention: $RETENTION_DAYS days"
        echo "Compression: $COMPRESSION"
        echo "Config-only backup: $CONFIG_ONLY"
        echo "Max backup size: $MAX_BACKUP_SIZE"
        echo "Email notifications: $EMAIL_NOTIFICATIONS"
        if [[ -n "$EMAIL_ADDRESS" ]]; then
            echo "Email address: $EMAIL_ADDRESS"
        fi
    else
        echo "Status: Not installed"
        return 0
    fi

    if [[ -f "$CRON_FILE" ]]; then
        echo "Cron job: Installed"
        echo "Cron file: $CRON_FILE"

        # Show next scheduled run time
        if command -v python3 >/dev/null 2>&1; then
            local next_run=$(python3 -c "
import croniter
import datetime
c = croniter.croniter('$SCHEDULE', datetime.datetime.now())
print(c.get_next(datetime.datetime).strftime('%Y-%m-%d %H:%M:%S'))
" 2>/dev/null || echo "Unable to calculate")
            echo "Next scheduled run: $next_run"
        fi
    else
        echo "Cron job: Not installed"
    fi

    # Show backup statistics
    if [[ -d "/etc/fortress-backups" ]]; then
        local backup_count=$(find /etc/fortress-backups -maxdepth 1 -type d ! -name "fortress-backups" | wc -l)
        local total_size=$(du -sh /etc/fortress-backups 2>/dev/null | cut -f1 || echo "Unknown")
        echo "Total backups: $backup_count"
        echo "Total size: $total_size"

        # Show latest backup
        local latest_backup=$(ls -1t /etc/fortress-backups/ 2>/dev/null | head -1)
        if [[ -n "$latest_backup" ]]; then
            echo "Latest backup: $latest_backup"
        fi
    fi

    # Check if currently running
    if [[ -f "$LOCK_FILE" ]]; then
        echo "Status: Backup currently running"
    else
        echo "Status: Idle"
    fi
}

# Interactive configuration setup
interactive_configure() {
    echo "Fortress Linux Backup Scheduler Configuration"
    echo "============================================"
    echo

    # Schedule
    echo "Current schedule: $SCHEDULE"
    echo "Common schedules:"
    echo "1. Daily at 2 AM        : 0 2 * * *"
    echo "2. Weekly on Sunday     : 0 2 * * 0"
    echo "3. Monthly on 1st       : 0 2 1 * *"
    echo "4. Every 6 hours        : */6 * * * *"
    echo "5. Every 4 hours        : 0 */4 * * *"
    echo "6. Custom schedule"
    echo
    read -p "Select schedule (1-6) or press Enter to keep current: " choice

    case "$choice" in
        1) SCHEDULE="0 2 * * *" ;;
        2) SCHEDULE="0 2 * * 0" ;;
        3) SCHEDULE="0 2 1 * *" ;;
        4) SCHEDULE="*/6 * * * *" ;;
        5) SCHEDULE="0 */4 * * *" ;;
        6)
            read -p "Enter custom cron schedule (minute hour day month weekday): " custom_schedule
            if validate_cron_schedule "$custom_schedule"; then
                SCHEDULE="$custom_schedule"
            else
                log_error "Invalid schedule. Keeping current: $SCHEDULE"
            fi
            ;;
        *)
            echo "Keeping current schedule: $SCHEDULE"
            ;;
    esac

    echo

    # Retention period
    echo "Current retention period: $RETENTION_DAYS days"
    read -p "Enter retention period (1-365 days) or press Enter to keep current: " retention_input

    if [[ -n "$retention_input" ]]; then
        if validate_retention "$retention_input"; then
            RETENTION_DAYS="$retention_input"
        else
            log_error "Invalid retention. Keeping current: $RETENTION_DAYS days"
        fi
    fi

    echo

    # Backup type
    echo "Backup type:"
    echo "1. Full backup (recommended)"
    echo "2. Configuration only"
    echo
    read -p "Select backup type (1-2) or press Enter to keep current: " backup_choice

    case "$backup_choice" in
        2) CONFIG_ONLY=true ;;
        *) CONFIG_ONLY=false ;;
    esac

    echo

    # Compression
    echo "Compression: $COMPRESSION"
    read -p "Enable compression? (y/n) or press Enter to keep current: " compression_choice

    case "$compression_choice" in
        n|N|no|NO) COMPRESSION=false ;;
        y|Y|yes|YES) COMPRESSION=true ;;
        *) echo "Keeping current setting: $COMPRESSION" ;;
    esac

    echo

    # Email notifications
    echo "Email notifications: $EMAIL_NOTIFICATIONS"
    read -p "Enable email notifications? (y/n) or press Enter to keep current: " email_choice

    case "$email_choice" in
        y|Y|yes|YES)
            EMAIL_NOTIFICATIONS=true
            read -p "Enter email address: " email_input
            if [[ -n "$email_input" ]]; then
                EMAIL_ADDRESS="$email_input"
            fi
            ;;
        n|N|no|NO) EMAIL_NOTIFICATIONS=false; EMAIL_ADDRESS="" ;;
        *) echo "Keeping current setting: $EMAIL_NOTIFICATIONS" ;;
    esac

    echo
    echo "Configuration Summary:"
    echo "Schedule: $SCHEDULE"
    echo "Retention: $RETENTION_DAYS days"
    echo "Backup type: $([[ "$CONFIG_ONLY" == true ]] && echo "Configuration only" || echo "Full backup")"
    echo "Compression: $COMPRESSION"
    echo "Email notifications: $EMAIL_NOTIFICATIONS"
    if [[ "$EMAIL_NOTIFICATIONS" == true && -n "$EMAIL_ADDRESS" ]]; then
        echo "Email address: $EMAIL_ADDRESS"
    fi
    echo

    read -p "Save this configuration? (y/n): " save_choice
    case "$save_choice" in
        y|Y|yes|YES)
            save_config
            log_success "Configuration saved"
            ;;
        *)
            echo "Configuration not saved"
            ;;
    esac
}

# Test backup configuration
test_configuration() {
    log_info "Testing backup configuration..."

    echo "Testing configuration with the following settings:"
    echo "Schedule: $SCHEDULE"
    echo "Retention: $RETENTION_DAYS days"
    echo "Compression: $COMPRESSION"
    echo "Config-only: $CONFIG_ONLY"
    echo "Max size: $MAX_BACKUP_SIZE"
    echo

    # Test backup script availability
    if [[ -f "$SCRIPT_DIR/backup_restore.sh" ]]; then
        log_success "Backup script found: $SCRIPT_DIR/backup_restore.sh"
    else
        log_error "Backup script not found"
        return 1
    fi

    # Test backup script syntax
    if bash -n "$SCRIPT_DIR/backup_restore.sh"; then
        log_success "Backup script syntax is valid"
    else
        log_error "Backup script has syntax errors"
        return 1
    fi

    # Test backup script help
    if "$SCRIPT_DIR/backup_restore.sh" --help >/dev/null 2>&1; then
        log_success "Backup script help works"
    else
        log_error "Backup script help failed"
        return 1
    fi

    # Test directory permissions
    if [[ -w "/etc/fortress-backups" ]]; then
        log_success "Backup directory is writable"
    else
        log_warning "Backup directory may not be writable"
    fi

    # Test log directory permissions
    if [[ -w "$(dirname "$LOG_FILE")" ]]; then
        log_success "Log directory is writable"
    else
        log_warning "Log directory may not be writable"
    fi

    # Test disk space
    local available_kb=$(df -k / | awk 'NR==2 {print $4}')
    local available_gb=$((available_kb / 1024 / 1024))
    if [[ $available_gb -ge 1 ]]; then
        log_success "Sufficient disk space available: ${available_gb}GB"
    else
        log_warning "Low disk space: ${available_gb}GB"
    fi

    log_success "Configuration test completed"
    return 0
}

# Install scheduler
install_scheduler() {
    log_info "Installing backup scheduler..."

    # Check prerequisites
    if ! check_prerequisites; then
        log_error "Prerequisites check failed"
        return 1
    fi

    # Save configuration
    save_config

    # Create cron job
    create_cron_job

    # Test configuration
    if ! test_configuration; then
        log_error "Configuration test failed"
        return 1
    fi

    log_success "Backup scheduler installed successfully"
    log_info "Configuration saved to: $CONFIG_FILE"
    log_info "Cron job created: $CRON_FILE"
    log_info "Log file: $LOG_FILE"
    log_info "Use '$0 status' to check the status"
}

# Uninstall scheduler
uninstall_scheduler() {
    log_info "Uninstalling backup scheduler..."

    # Remove cron job
    remove_cron_job

    # Remove configuration file
    if [[ -f "$CONFIG_FILE" ]]; then
        rm -f "$CONFIG_FILE"
        log_info "Configuration file removed: $CONFIG_FILE"
    fi

    # Remove lock file
    if [[ -f "$LOCK_FILE" ]]; then
        rm -f "$LOCK_FILE"
        log_info "Lock file removed: $LOCK_FILE"
    fi

    log_success "Backup scheduler uninstalled successfully"
    log_warning "Existing backups in /etc/fortress-backups are preserved"
}

# Main execution
main() {
    # Load existing configuration
    load_config

    # Parse command line arguments
    case "${1:-}" in
        install)
            shift
            while [[ $# -gt 0 ]]; do
                case $1 in
                    --schedule)
                        SCHEDULE="$2"
                        validate_cron_schedule "$SCHEDULE" || exit 1
                        shift 2
                        ;;
                    --retention)
                        RETENTION_DAYS="$2"
                        validate_retention "$RETENTION_DAYS" || exit 1
                        shift 2
                        ;;
                    --compress)
                        COMPRESSION=true
                        shift
                        ;;
                    --config-only)
                        CONFIG_ONLY=true
                        shift
                        ;;
                    --max-size)
                        MAX_BACKUP_SIZE="$2"
                        validate_backup_size "$MAX_BACKUP_SIZE" || exit 1
                        shift 2
                        ;;
                    --email)
                        EMAIL_NOTIFICATIONS=true
                        EMAIL_ADDRESS="$2"
                        shift 2
                        ;;
                    --dry-run)
                        log_info "Dry run mode - would install with current configuration"
                        show_status
                        exit 0
                        ;;
                    *)
                        log_error "Unknown option: $1"
                        show_usage
                        exit 1
                        ;;
                esac
            done
            install_scheduler
            ;;
        uninstall)
            uninstall_scheduler
            ;;
        status)
            show_status
            ;;
        enable)
            if [[ -f "$CRON_FILE" ]]; then
                log_success "Scheduler is already enabled"
            else
                create_cron_job
                log_success "Scheduler enabled"
            fi
            ;;
        disable)
            remove_cron_job
            log_success "Scheduler disabled"
            ;;
        run)
            run_backup
            ;;
        configure)
            interactive_configure
            ;;
        test)
            test_configuration
            ;;
        --help)
            show_usage
            ;;
        *)
            log_error "Unknown command: ${1:-}"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"