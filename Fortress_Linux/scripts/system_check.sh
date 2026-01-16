#!/bin/bash

# Quick System Compatibility Check for Fortress Linux
# Tests basic system requirements with enhanced UX

set -euo pipefail

# Source UX core library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/ux_core.sh" || {
    echo "ERROR: Failed to load ux_core.sh"
    exit 1
}

# Parse UX arguments
parse_ux_arguments "$@"

print_header "🔍 Fortress Linux - System Compatibility Check"

echo
echo "System Information:"
echo "  └─ $(lsb_release -d 2>/dev/null | cut -f2- || echo 'Unknown')"
echo "  └─ Kernel: $(uname -r)"
echo "  └─ Architecture: $(uname -m)"
echo "  └─ Date: $(date)"
echo

# Store verification results
declare -a verification_results=()

# Initialize counters for final summary (global scope - not local!)
ok_count=0
warning_count=0
error_count=0


# Check Ubuntu/Debian version
if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    echo "OS Version: $PRETTY_NAME ($VERSION_ID)"
    echo

    case "$ID" in
        ubuntu)
            if [[ "${VERSION_ID%%.*}" -ge 22 ]]; then
                verification_results+=("Ubuntu Version|ok|${VERSION_ID} supported")
            else
                verification_results+=("Ubuntu Version|warning|${VERSION_ID} - upgrade to 22.04+ recommended")
            fi
            ;;
        debian)
            if [[ "${VERSION_ID%%.*}" -ge 12 ]]; then
                verification_results+=("Debian Version|ok|${VERSION_ID} supported")
            else
                verification_results+=("Debian Version|warning|${VERSION_ID} - upgrade to 12+ recommended")
            fi
            ;;
        *)
            verification_results+=("Operating System|error|${ID} - Ubuntu/Debian required")
            ;;
    esac
fi

# Check Python
if command -v python3 >/dev/null 2>&1; then
    verification_results+=("Python|ok|$(python3 --version)")
else
    verification_results+=("Python|error|Not found - install with: apt install python3")
fi

# Check systemd
if command -v systemctl >/dev/null 2>&1; then
    verification_results+=("Systemd|ok|Available")
else
    verification_results+=("Systemd|error|Not found - required for service management")
fi

# Check package manager
if command -v apt >/dev/null 2>&1; then
    verification_results+=("APT Package Manager|ok|Available")
else
    verification_results+=("APT Package Manager|error|Not found - Ubuntu/Debian required")
fi

# Check disk space
available_gb=$(df -BG / | awk 'NR==2{print $4}' | tr -d 'G')
if [[ $available_gb -ge 1 ]]; then
    verification_results+=("Disk Space|ok|${available_gb}GB available")
else
    verification_results+=("Disk Space|error|${available_gb}GB - minimum 1GB required")
fi

# Check memory
total_mb=$(free -m | awk 'NR==2{print $2}')
if [[ $total_mb -ge 512 ]]; then
    verification_results+=("Memory|ok|${total_mb}MB total")
else
    verification_results+=("Memory|warning|${total_mb}MB - low, performance may be affected")
fi

# Check SSH
if command -v sshd >/dev/null 2>&1; then
    verification_results+=("SSH Daemon|ok|Available")
else
    verification_results+=("SSH Daemon|warning|Will be installed during hardening")
fi

# Check UFW (will be installed if missing)
if command -v ufw >/dev/null 2>&1; then
    verification_results+=("UFW Firewall|ok|Available")
else
    verification_results+=("UFW Firewall|info|Will be installed during hardening")
fi

# Check auditd (will be installed if missing)
if command -v auditd >/dev/null 2>&1; then
    verification_results+=("Audit Daemon|ok|Available")
else
    verification_results+=("Audit Daemon|info|Will be installed during hardening")
fi

# Show results
print_section "Verification Results"
show_verification_table "${verification_results[@]}"

# Count status
for result in "${verification_results[@]}"; do
    _rest="${result#*|}"
    _status="${_rest%%|*}"

    if [[ "$_status" == "ok" ]]; then
        ok_count=$((ok_count + 1))
    elif [[ "$_status" == "warning" ]]; then
        warning_count=$((warning_count + 1))
    elif [[ "$_status" == "error" ]]; then
        error_count=$((error_count + 1))
    fi
done

# Clear temporary variables
unset _rest _status

# Summary
echo
print_divider "─"
if [[ $error_count -eq 0 ]]; then
    log_success "Your system is compatible with Fortress Linux!"
    echo
    echo "✓ ${ok_count} checks passed"
    if [[ $warning_count -gt 0 ]]; then
        echo "⚠ ${warning_count} warnings (non-critical)"
    fi
    echo
    echo "Next steps:"
    echo "  1. Create a backup: sudo ./scripts/backup_restore.sh backup"
    echo "  2. Run hardening: sudo ./scripts/linux_hardening.sh"
    echo "  3. For automation: sudo ./scripts/linux_hardening.sh --yes --verbose"
else
    log_error "Your system has ${error_count} compatibility issues"
    echo
    echo "Please resolve the errors above before proceeding with hardening."
fi
print_divider "─"
echo
print_divider "─"
if [[ $error_count -eq 0 ]]; then
    log_success "Your system is compatible with Fortress Linux!"
    echo
    echo "✓ ${ok_count} checks passed"
    if [[ $warning_count -gt 0 ]]; then
        echo "⚠ ${warning_count} warnings (non-critical)"
    fi
    echo
    echo "Next steps:"
    echo "  1. Create a backup: sudo ./scripts/backup_restore.sh backup"
    echo "  2. Run hardening: sudo ./scripts/linux_hardening.sh"
    echo "  3. For automation: sudo ./scripts/linux_hardening.sh --yes --verbose"
else
    log_error "Your system has ${error_count} compatibility issues"
    echo
    echo "Please resolve the errors above before proceeding with hardening."
fi
print_divider "─"
echo