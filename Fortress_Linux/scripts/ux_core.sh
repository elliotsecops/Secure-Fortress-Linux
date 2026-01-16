#!/bin/bash

# Fortress Linux - Terminal UX Core Library
# Reusable functions for optimal terminal user experience

# Terminal detection
is_tty() {
    [[ -t 1 ]] && return 0 || return 1
}

# Terminal width detection
get_terminal_width() {
    if command -v tput &>/dev/null && [[ -t 1 ]]; then
        tput cols 2>/dev/null || echo 80
    else
        echo 80
    fi
}

# Color detection
use_color() {
    [[ "${NO_COLOR:-}" == "1" ]] && return 1
    is_tty && return 0
    return 1
}

# Color codes
if use_color; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    PURPLE='\033[0;35m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    PURPLE=''
    CYAN=''
    BOLD=''
    NC=''
fi

# Verbosity system
declare -g VERBOSITY_LEVEL="normal"
declare -g LOG_FILE="${LOG_FILE:-/var/log/fortress-hardening.log}"

set_verbosity() {
    case "$1" in
        quiet|q) VERBOSITY_LEVEL="quiet" ;;
        verbose|v) VERBOSITY_LEVEL="verbose" ;;
        debug|vv) VERBOSITY_LEVEL="debug" ;;
        *) VERBOSITY_LEVEL="normal" ;;
    esac
}

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Try to log to file, fail gracefully if no permission
    if [[ -w "$(dirname "$LOG_FILE")" ]] || [[ -w "$LOG_FILE" ]]; then
        echo "[$timestamp] [$level] $message" >> "$LOG_FILE" 2>/dev/null || true
    fi
}

log_debug() {
    [[ "$VERBOSITY_LEVEL" == "debug" ]] && echo -e "${BLUE}[DEBUG]${NC} $*"
    log "DEBUG" "$@"
}

log_verbose() {
    [[ "$VERBOSITY_LEVEL" =~ ^(verbose|debug)$ ]] && echo -e "${CYAN}[VERB]${NC} $*"
    log "VERBOSE" "$@"
}

log_info() {
    [[ "$VERBOSITY_LEVEL" != "quiet" ]] && echo -e "${BLUE}[INFO]${NC} $*"
    log "INFO" "$@"
}

log_success() {
    [[ "$VERBOSITY_LEVEL" != "quiet" ]] && echo -e "${GREEN}[✓]${NC} $*"
    log "SUCCESS" "$@"
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $*"
    log "WARNING" "$@"
}

log_error() {
    echo -e "${RED}[✗]${NC} $*"
    log "ERROR" "$@"
}

log_always() {
    echo "$*"
    log "ALWAYS" "$@"
}

print_header() {
    local text="$1"
    local width=$(get_terminal_width)
    local padding=$(( (width - ${#text} - 4) / 2 ))
    
    echo
    printf '%*s' "$width" '' | tr ' ' '═'
    echo
    printf "%*s  ${BOLD}$text${NC}  %*s\n" $padding "" $padding ""
    printf '%*s' "$width" '' | tr ' ' '═'
    echo
}

print_section() {
    local text="$1"
    echo
    echo "${BLUE}┌─${NC} ${BOLD}$text${NC}"
    echo "${BLUE}│${NC}"
}

print_divider() {
    local char="${1:-=}"
    local width=$(get_terminal_width)
    printf '%*s' "$width" '' | tr ' ' "$char"
    echo
}

# Progress bar
show_progress_bar() {
    local current=$1
    local total=$2
    local message="$3"
    local width=${4:-50}
    local term_width=$(get_terminal_width)
    
    local percent=$((current * 100 / total))
    local filled=$((width * current / total))
    local empty=$((width - filled))
    
    # Use ASCII characters for better compatibility
    local bar=""
    bar+=$(printf '%*s' "$filled" '' | tr ' ' '=')
    bar+=$(printf '%*s' "$empty" '' | tr ' ' '-')
    
    printf "\r  ${message} %3d%% [${bar}]" "$percent"
    
    if [[ $current -eq $total ]]; then
        echo
    fi
}

# Step counter
declare -g CURRENT_STEP=0
declare -g TOTAL_STEPS=0

show_step() {
    local step_num=$1
    local total_steps=$2
    local message="$3"
    
    local step_width=${#total_steps}
    printf "\r${CYAN}[%${step_width}d/%${step_width}d]${NC} %s\n" "$step_num" "$total_steps" "$message"
}

# Time estimation
declare -g OPERATION_START_TIME=""

start_timer() {
    OPERATION_START_TIME=$(date +%s)
}

show_timer() {
    local duration_seconds=$1
    local message="$2"
    
    if [[ $duration_seconds -ge 60 ]]; then
        local minutes=$((duration_seconds / 60))
        local seconds=$((duration_seconds % 60))
        printf "$message (~%d min %02d sec)" "$minutes" "$seconds"
    else
        printf "$message (~%d sec)" "$duration_seconds"
    fi
}

estimate_operation_time() {
    local operation="$1"
    case "$operation" in
        check_root_privileges) echo "2 sec" ;;
        check_system_requirements) echo "3 sec" ;;
        check_connectivity) echo "2 sec" ;;
        create_backup) echo "10 sec" ;;
        update_system) echo "120 sec" ;;
        configure_firewall) echo "5 sec" ;;
        disable_unnecessary_services) echo "15 sec" ;;
        configure_password_policy) echo "5 sec" ;;
        configure_auditd) echo "15 sec" ;;
        configure_file_permissions) echo "5 sec" ;;
        configure_ssh_security) echo "5 sec" ;;
        verify_hardening) echo "10 sec" ;;
        cleanup) echo "3 sec" ;;
        *) echo "30 sec" ;;
    esac
}

# Spinner for async operations
declare -g SPINNER_PID=""
declare -g SPINNER_CHARS="\\|/-"
declare -g SPINNER_DELAY=0.1

# Use Unicode spinner if supported
if use_color && command -v locale &>/dev/null; then
    local current_locale=$(locale charmap 2>/dev/null || echo "unknown")
    if [[ "$current_locale" =~ ^(UTF-8|utf8) ]]; then
        SPINNER_CHARS="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    fi
fi

start_spinner() {
    local message="$1"
    local i=0

    while true; do
        local char=${SPINNER_CHARS:$((i % ${#SPINNER_CHARS})):1}
        echo -ne "\r${CYAN}[...]${NC} $message... ${CYAN}$char${NC}"
        sleep $SPINNER_DELAY
        ((i++))
    done &
    SPINNER_PID=$!
}

stop_spinner() {
    local result="${1:-success}"
    local message="${2:-Done}"
    
    if [[ -n "$SPINNER_PID" ]]; then
        kill $SPINNER_PID 2>/dev/null || true
        wait $SPINNER_PID 2>/dev/null || true
        SPINNER_PID=""
    fi
    
    if [[ "$result" == "success" ]]; then
        echo -ne "\r${GREEN}✓${NC} $message\n"
    elif [[ "$result" == "warning" ]]; then
        echo -ne "\r${YELLOW}⚠${NC} $message\n"
    else
        echo -ne "\r${RED}✗${NC} $message\n"
    fi
}

# Interactive confirmations
confirm_action() {
    local message="$1"
    local default="${2:-n}"
    local prompt
    
    if [[ "$default" == "y" ]]; then
        prompt="$message ${CYAN}[Y/n]${NC}: "
    else
        prompt="$message ${CYAN}[y/N]${NC}: "
    fi
    
    local response
    read -p "$prompt" response
    
    case $response in
        [Yy]|[Yy][Ee][Ss]) return 0 ;;
        [Nn]|[Nn][Oo]|"")
            [[ "$default" == "y" ]] && return 0 || return 1
            ;;
    esac
}

confirm_dangerous() {
    local message="$1"
    
    echo
    print_divider "!"
    echo -e "${YELLOW}⚠️  WARNING: This operation cannot be undone!${NC}"
    echo "$message"
    print_divider "!"
    
    confirm_action "Do you want to proceed?" "n"
}

# Enhanced error messages
declare -A ERROR_FIXES=(
    ["ufw_failed"]="sudo ufw --force reset && sudo ufw enable"
    ["ssh_failed"]="sshd -t && systemctl restart sshd"
    ["ssh_config_failed"]="Review SSH configuration: cat /etc/ssh/sshd_config"
    ["auditd_failed"]="systemctl restart auditd; auditctl -R /etc/audit/rules.d/hardening.rules"
    ["package_failed"]="apt update && apt upgrade -y"
    ["permission"]="Run with sudo privileges"
    ["connectivity"]="Check internet connection: ping -c 1 8.8.8.8"
    ["disk_space"]="Free up disk space: df -h"
    ["service_not_found"]="Install missing package: apt install <package>"
    ["backup_failed"]="Check disk space and permissions in /etc/fortress-backups"
)

show_error() {
    local message="$1"
    local fix_suggestion="${2:-}"
    local log_line="${3:-}"
    
    echo
    print_divider "!"
    echo -e "${RED}❌ $message${NC}"
    echo
    
    if [[ -n "$fix_suggestion" ]]; then
        echo -e "${CYAN}💡 Possible fix:${NC}"
        echo "   $fix_suggestion"
        echo
    fi
    
    if [[ -n "$log_line" ]]; then
        echo -e "${CYAN}📄 Log:${NC} $LOG_FILE:$log_line"
        echo
    fi
    
    print_divider "!"
}

show_error_block() {
    local title="$1"
    local message="$2"
    local fix="${3:-Manual review required}"
    local log_path="${4:-$LOG_FILE}"
    
    echo
    print_divider "!"
    echo -e "${RED}❌ $title${NC}"
    echo
    echo "$message"
    echo
    echo -e "${CYAN}💡 Suggested fix:${NC}"
    echo "   $fix"
    echo
    echo -e "${CYAN}📄 Log:${NC} $log_path"
    print_divider "!"
}

# Compact verification table
show_verification_table() {
    local results=("$@")
    
    local term_width=$(get_terminal_width)
    local table_max_name_len=20
    local max_msg_len=$((term_width - table_max_name_len - 20))
    
    for _result in "${results[@]}"; do
        local _name="${_result%%|*}"
        [[ ${#_name} -gt $table_max_name_len ]] && table_max_name_len=${#_name}
    done
    
    local divider=$(printf '%*s' "$term_width" '' | tr ' ' '─')
    
    echo
    echo "$divider"
    printf "%-${table_max_name_len}s  %-12s  %s\n" "Component" "Status" "Details"
    echo "$divider"
    
    for _result in "${results[@]}"; do
        local _name="${_result%%|*}"
        local _rest="${_result#*|}"
        local _status="${_rest%%|*}"
        local _msg="${_rest##*|}"
        
        local _status_color="$GREEN"
        local _status_icon="✓"
        
        if [[ "$_status" != "ok" ]]; then
            _status_color="$RED"
            _status_icon="✗"
        elif [[ "$_status" == "warning" ]]; then
            _status_color="$YELLOW"
            _status_icon="⚠"
        fi
        
        printf "%-${table_max_name_len}s  ${_status_color}[%s]${NC}  %s\n" "$_name" "$_status_icon" "$_msg"
    done
    
    echo "$divider"
    echo
}

# Error recovery menu
show_recovery_menu() {
    local failed_operation="$1"
    
    echo
    print_divider "!"
    echo -e "${RED}❌ $failed_operation failed${NC}"
    echo
    echo "Recovery options:"
    echo "  ${CYAN}1)${NC} Retry operation"
    echo "  ${CYAN}2)${NC} Skip and continue"
    echo "  ${CYAN}3)${NC} Show error details"
    echo "  ${CYAN}4)${NC} Abort and exit"
    print_divider "!"
    
    local choice
    read -p "Choose option [1-4]: " choice
    
    case $choice in
        1) return 1 ;;
        2) return 0 ;;
        3) 
            echo
            echo "Recent errors from log:"
            echo
            tail -n 30 "$LOG_FILE" 2>/dev/null | grep -i '\[error\]' || echo "No recent errors found in log"
            echo
            show_recovery_menu "$failed_operation"
            ;;
        4) exit 1 ;;
        *) 
            echo "Invalid choice"
            show_recovery_menu "$failed_operation"
            ;;
    esac
}

# Retry operation
retry_operation() {
    local operation_name="$1"
    local max_attempts=3
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        log_verbose "Attempt $attempt/$max_attempts: $operation_name"
        
        if $operation_name; then
            log_success "$operation_name succeeded"
            return 0
        fi
        
        if [[ $attempt -lt $max_attempts ]]; then
            log_warning "Retrying in 2 seconds..."
            sleep 2
        fi
        
        ((attempt++))
    done
    
    show_error "$operation_name failed after $max_attempts attempts" \
               "${ERROR_FIXES[$operation_name]:-}" \
               ""
    return 1
}

# Summary dashboard
declare -a VERIFICATION_RESULTS=()

add_verification_result() {
    local name="$1"
    local status="$2"
    local message="$3"
    VERIFICATION_RESULTS+=("$name|$status|$message")
}

show_completion_dashboard() {
    local duration="${1:-Unknown}"
    local total_steps="${2:-0}"
    local backup_dir="${3:-}"
    
    print_header "🛡️ Fortress Linux - Hardening Complete"
    
    echo
    echo "📊 Summary:"
    echo "   └─ $total_steps steps completed"
    echo "   └─ Duration: $duration"
    echo "   └─ Log: $LOG_FILE"
    echo
    
    if [[ -n "$backup_dir" ]]; then
        echo "💾 Backup: $backup_dir"
        echo "   └─ Restore: sudo $0 restore $backup_dir"
        echo
    fi
    
    if [[ ${#VERIFICATION_RESULTS[@]} -gt 0 ]]; then
        echo "🔍 Verification:"
        show_verification_table "${VERIFICATION_RESULTS[@]}"
    fi
    
    echo "⚙️  System Status:"
    local fw_status=$(ufw status 2>/dev/null | grep Status | cut -d: -f2 | xargs || echo "Unknown")
    local auditd_status=$(systemctl is-active auditd 2>/dev/null || echo "Unknown")
    local ssh_status=$(systemctl is-active sshd 2>/dev/null || echo "Unknown")
    
    echo "   Firewall: $fw_status"
    echo "   Auditd:   $auditd_status"
    echo "   SSH:      $ssh_status"
    echo
    
    print_divider "─"
    echo "📖 Documentation: docs/"
    echo "🐛 Issues: https://github.com/elliotsecops/Secure-Fortress-Linux/issues"
    print_divider "─"
}

# Parse common UX CLI arguments
parse_ux_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --quiet|-q)
                set_verbosity "quiet"
                shift
                ;;
            --verbose|-v)
                set_verbosity "verbose"
                shift
                ;;
            --debug|-vv)
                set_verbosity "debug"
                shift
                ;;
            --yes|-y)
                export AUTO_CONFIRM="yes"
                shift
                ;;
            --dry-run)
                export DRY_RUN="yes"
                log_warning "Dry-run mode enabled - no changes will be made"
                shift
                ;;
            *)
                shift
                ;;
        esac
    done
}

# Auto-confirm check
should_auto_confirm() {
    [[ "${AUTO_CONFIRM:-}" == "yes" ]]
}

# Dry-run check
is_dry_run() {
    [[ "${DRY_RUN:-}" == "yes" ]]
}

# Execute command (or skip if dry-run)
execute_command() {
    local cmd="$*"
    
    if is_dry_run; then
        log_verbose "[DRY-RUN] Would execute: $cmd"
        return 0
    else
        log_debug "Executing: $cmd"
        eval "$cmd"
    fi
}

# Export functions for use in other scripts
export -f is_tty get_terminal_width use_color set_verbosity
export -f log log_debug log_verbose log_info log_success log_warning log_error log_always
export -f print_header print_section print_divider show_progress_bar show_step
export -f start_timer show_timer estimate_operation_time
export -f start_spinner stop_spinner confirm_action confirm_dangerous
export -f show_error show_error_block show_recovery_menu retry_operation
export -f add_verification_result show_verification_table show_completion_dashboard
export -f parse_ux_arguments should_auto_confirm is_dry_run execute_command
export VERBOSITY_LEVEL LOG_FILE SPINNER_PID VERIFICATION_RESULTS
