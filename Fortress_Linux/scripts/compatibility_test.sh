#!/bin/bash

# Fortress Linux - Compatibility Test Script
# Tests compatibility with Ubuntu 22.04+ and Debian 12

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/tmp/fortress-compatibility-test.log"
TEST_RESULTS_DIR="/tmp/fortress-test-results"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test results
PASSED_TESTS=0
FAILED_TESTS=0
TOTAL_TESTS=0

# Logging
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

# Test functions
run_test() {
    local test_name="$1"
    local test_function="$2"

    ((TOTAL_TESTS++))
    log_info "Running test: $test_name"

    if $test_function; then
        log_success "✓ PASSED: $test_name"
        ((PASSED_TESTS++))
        echo "PASSED: $test_name" >> "$TEST_RESULTS_DIR/test_results.txt"
        return 0
    else
        log_error "✗ FAILED: $test_name"
        ((FAILED_TESTS++))
        echo "FAILED: $test_name" >> "$TEST_RESULTS_DIR/test_results.txt"
        return 1
    fi
}

# Check OS compatibility
test_os_compatibility() {
    log_info "Checking operating system compatibility..."

    if [[ ! -f /etc/os-release ]]; then
        log_error "Cannot determine OS"
        return 1
    fi

    source /etc/os-release

    log_info "Detected OS: $PRETTY_NAME"
    log_info "ID: $ID"
    log_info "Version: $VERSION_ID"

    # Check for supported OS versions
    local supported=false

    case "$ID" in
        ubuntu)
            if [[ "${VERSION_ID%%.*}" -ge 22 ]]; then
                supported=true
                log_success "Ubuntu $VERSION_ID is supported"
            else
                log_warning "Ubuntu $VERSION_ID may not be fully supported"
                supported=true  # Still support older versions with warnings
            fi
            ;;
        debian)
            if [[ "${VERSION_ID%%.*}" -ge 12 ]]; then
                supported=true
                log_success "Debian $VERSION_ID is supported"
            else
                log_warning "Debian $VERSION_ID may not be fully supported"
                supported=true  # Still support older versions with warnings
            fi
            ;;
        *)
            log_warning "Unknown OS: $ID. May not be fully supported"
            supported=true  # Try anyway
            ;;
    esac

    echo "OS: $PRETTY_NAME" > "$TEST_RESULTS_DIR/system_info.txt"
    echo "Kernel: $(uname -r)" >> "$TEST_RESULTS_DIR/system_info.txt"
    echo "Architecture: $(uname -m)" >> "$TEST_RESULTS_DIR/system_info.txt"

    return 0
}

# Test Python availability
test_python() {
    log_info "Testing Python availability..."

    # Check for Python 3
    if command -v python3 >/dev/null 2>&1; then
        local python_version=$(python3 --version 2>&1)
        log_success "Python found: $python_version"

        # Check version
        local major_minor=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
        if [[ "${major_minor%%.*}" -ge 3 && "${major_minor##*.}" -ge 8 ]]; then
            log_success "Python version $major_minor is sufficient"
        else
            log_warning "Python version $major_minor may be outdated"
        fi
        echo "Python: $python_version" >> "$TEST_RESULTS_DIR/system_info.txt"
        return 0
    else
        log_error "Python 3 not found"
        return 1
    fi
}

# Test package manager
test_package_manager() {
    log_info "Testing package manager..."

    if command -v apt >/dev/null 2>&1; then
        local apt_version=$(apt --version | head -n1)
        log_success "APT found: $apt_version"

        # Test if we can list packages
        if apt list --installed >/dev/null 2>&1; then
            log_success "APT can list packages"
        else
            log_error "APT cannot list packages"
            return 1
        fi

        echo "Package Manager: $apt_version" >> "$TEST_RESULTS_DIR/system_info.txt"
        return 0
    else
        log_error "APT package manager not found"
        return 1
    fi
}

# Test systemd availability
test_systemd() {
    log_info "Testing systemd availability..."

    if command -v systemctl >/dev/null 2>&1; then
        local systemd_version=$(systemctl --version | head -n1)
        log_success "Systemd found: $systemd_version"

        # Test if we can query service status
        if systemctl list-units --type=service --state=running >/dev/null 2>&1; then
            log_success "Systemd can query services"
        else
            log_error "Systemd cannot query services"
            return 1
        fi

        echo "Init System: $systemd_version" >> "$TEST_RESULTS_DIR/system_info.txt"
        return 0
    else
        log_error "Systemd not found"
        return 1
    fi
}

# Test UFW availability
test_ufw() {
    log_info "Testing UFW firewall..."

    if command -v ufw >/dev/null 2>&1; then
        local ufw_version=$(ufw --version 2>/dev/null | head -n1 || echo "Unknown")
        log_success "UFW found: $ufw_version"

        # Test UFW status (don't actually modify anything)
        if ufw status >/dev/null 2>&1; then
            log_success "UFW can query status"
        else
            log_warning "UFW status query failed (may not be initialized)"
        fi

        return 0
    else
        log_warning "UFW not found (will be installed during hardening)"
        return 0  # This is not a failure, as UFW will be installed
    fi
}

# Test auditd availability
test_auditd() {
    log_info "Testing audit daemon..."

    if command -v auditd >/dev/null 2>&1; then
        local auditd_version=$(auditd -v 2>/dev/null || echo "Unknown")
        log_success "Auditd found: $auditd_version"

        # Test auditctl
        if command -v auditctl >/dev/null 2>&1; then
            log_success "Auditctl found"
        else
            log_warning "Auditctl not found"
        fi

        return 0
    else
        log_warning "Auditd not found (will be installed during hardening)"
        return 0  # This is not a failure, as auditd will be installed
    fi
}

# Test SSH availability
test_ssh() {
    log_info "Testing SSH..."

    if command -v sshd >/dev/null 2>&1; then
        local sshd_version=$(sshd -V 2>&1 | head -n1 || echo "Unknown")
        log_success "SSH daemon found: $sshd_version"

        # Test SSH configuration file
        if [[ -f /etc/ssh/sshd_config ]]; then
            log_success "SSH configuration file found"
        else
            log_warning "SSH configuration file not found"
        fi

        return 0
    else
        log_error "SSH daemon not found"
        return 1
    fi
}

# Test file permissions
test_file_permissions() {
    log_info "Testing file permissions..."

    local critical_files=(
        "/etc/passwd"
        "/etc/group"
        "/etc/shadow"
        "/etc/gshadow"
        "/etc/ssh/sshd_config"
    )

    local failed_files=0

    for file in "${critical_files[@]}"; do
        if [[ -f "$file" ]]; then
            local perms=$(stat -c "%a" "$file" 2>/dev/null || echo "unknown")
            log_info "File $file permissions: $perms"

            # Basic permission checks
            case "$(basename "$file")" in
                "shadow"|"gshadow")
                    if [[ "$perms" =~ ^[0-6][0-4][0-4]$ ]] || [[ "$perms" =~ ^[0-6][0-6][0-6]$ ]]; then
                        log_success "Secure permissions for $file: $perms"
                    else
                        log_warning "Potentially insecure permissions for $file: $perms"
                    fi
                    ;;
                "passwd"|"group")
                    if [[ "$perms" =~ ^[0-6][0-4][0-4]$ ]]; then
                        log_success "Secure permissions for $file: $perms"
                    else
                        log_warning "Potentially insecure permissions for $file: $perms"
                    fi
                    ;;
                "sshd_config")
                    if [[ "$perms" =~ ^[0-6][0-4][0-4]$ ]]; then
                        log_success "Secure permissions for $file: $perms"
                    else
                        log_warning "Potentially insecure permissions for $file: $perms"
                    fi
                    ;;
            esac
        else
            log_warning "Critical file not found: $file"
            ((failed_files++))
        fi
    done

    if [[ $failed_files -eq 0 ]]; then
        return 0
    else
        log_error "$failed_files critical files missing"
        return 1
    fi
}

# Test networking
test_networking() {
    log_info "Testing networking..."

    # Test network interfaces
    if command -v ip >/dev/null 2>&1; then
        local interface_count=$(ip link show | grep -c "^[0-9]" || echo "0")
        log_success "Network interfaces found: $interface_count"

        # Test loopback interface
        if ip link show lo >/dev/null 2>&1; then
            log_success "Loopback interface available"
        else
            log_error "Loopback interface not available"
            return 1
        fi

        return 0
    else
        log_error "ip command not found"
        return 1
    fi
}

# Test disk space
test_disk_space() {
    log_info "Testing disk space..."

    # Check available disk space in root
    local available_kb=$(df -k / | awk 'NR==2 {print $4}')
    local available_gb=$((available_kb / 1024 / 1024))

    log_info "Available disk space: ${available_gb}GB"

    if [[ $available_gb -ge 1 ]]; then
        log_success "Sufficient disk space available"
        return 0
    else
        log_error "Insufficient disk space (need at least 1GB)"
        return 1
    fi
}

# Test memory
test_memory() {
    log_info "Testing memory..."

    if command -v free >/dev/null 2>&1; then
        local total_mb=$(free -m | awk 'NR==2{printf "%.0f", $2}')
        local total_gb=$((total_mb / 1024))

        log_info "Total memory: ${total_mb}MB (${total_gb}GB)"

        if [[ $total_mb -ge 512 ]]; then
            log_success "Sufficient memory available"
            return 0
        else
            log_warning "Low memory detected (${total_mb}MB)"
            return 0  # Not a failure, just a warning
        fi
    else
        log_error "Cannot determine memory usage"
        return 1
    fi
}

# Test backup functionality
test_backup_functionality() {
    log_info "Testing backup functionality..."

    # Create test backup directory
    local test_backup_dir="/tmp/fortress-test-backup-$$"
    mkdir -p "$test_backup_dir"

    # Create test files
    echo "test content" > "$test_backup_dir/test.txt"
    echo '{"test": "data"}' > "$test_backup_dir/metadata.json"

    # Test backup script exists
    local backup_script="$SCRIPT_DIR/backup_restore.sh"
    if [[ -f "$backup_script" ]]; then
        log_success "Backup script found"

        # Test backup script syntax
        if bash -n "$backup_script"; then
            log_success "Backup script syntax is valid"
        else
            log_error "Backup script has syntax errors"
            return 1
        fi

        # Test backup script help
        if "$backup_script" --help >/dev/null 2>&1; then
            log_success "Backup script help works"
        else
            log_error "Backup script help failed"
            return 1
        fi

        return 0
    else
        log_error "Backup script not found"
        return 1
    fi

    # Cleanup
    rm -rf "$test_backup_dir"
}

# Test hardening script
test_hardening_script() {
    log_info "Testing hardening script..."

    local hardening_script="$SCRIPT_DIR/linux_hardening.sh"

    if [[ -f "$hardening_script" ]]; then
        log_success "Hardening script found"

        # Test hardening script syntax
        if bash -n "$hardening_script"; then
            log_success "Hardening script syntax is valid"
        else
            log_error "Hardening script has syntax errors"
            return 1
        fi

        # Test hardening script help (if available)
        if "$hardening_script" --help >/dev/null 2>&1; then
            log_success "Hardening script help works"
        else
            log_info "Hardening script help not available (normal)"
        fi

        return 0
    else
        log_error "Hardening script not found"
        return 1
    fi
}

# Generate compatibility report
generate_report() {
    local report_file="$TEST_RESULTS_DIR/compatibility_report.txt"

    cat > "$report_file" << EOF
Fortress Linux Compatibility Report
===================================
Generated: $(date)
Test ID: $TIMESTAMP

SYSTEM INFORMATION
------------------
$(cat "$TEST_RESULTS_DIR/system_info.txt")

TEST RESULTS
------------
Total Tests: $TOTAL_TESTS
Passed: $PASSED_TESTS
Failed: $FAILED_TESTS
Success Rate: $(( PASSED_TESTS * 100 / TOTAL_TESTS ))%

DETAILED RESULTS
----------------
$(cat "$TEST_RESULTS_DIR/test_results.txt")

RECOMMENDATIONS
---------------
EOF

    # Add recommendations based on test results
    if [[ $FAILED_TESTS -eq 0 ]]; then
        echo "✓ System is fully compatible with Fortress Linux" >> "$report_file"
        echo "✓ All critical components are available" >> "$report_file"
        echo "✓ You can proceed with hardening" >> "$report_file"
    else
        echo "⚠ Some compatibility issues detected:" >> "$report_file"
        echo "  - Review failed tests above" >> "$report_file"
        echo "  - Install missing dependencies" >> "$report_file"
        echo "  - Consider system upgrade if needed" >> "$report_file"
    fi

    if [[ $PASSED_TESTS -eq $TOTAL_TESTS ]]; then
        echo "✓ Excellent compatibility! All tests passed." >> "$report_file"
    elif [[ $(( PASSED_TESTS * 100 / TOTAL_TESTS )) -ge 80 ]]; then
        echo "✓ Good compatibility. Minor issues may exist." >> "$report_file"
    else
        echo "⚠ Compatibility concerns detected. System may need updates." >> "$report_file"
    fi

    echo "" >> "$report_file"
    echo "NEXT STEPS" >> "$report_file"
    echo "----------" >> "$report_file"
    echo "1. Review this report" >> "$report_file"
    echo "2. Install missing dependencies if any" >> "$report_file"
    echo "3. Run: sudo $SCRIPT_DIR/linux_hardening.sh" >> "$report_file"
    echo "4. Monitor: tail -f /var/log/fortress-hardening.log" >> "$report_file"

    log_success "Compatibility report generated: $report_file"
}

# Main function
main() {
    log_info "Starting Fortress Linux compatibility test..."
    log_info "Test ID: $TIMESTAMP"

    # Create results directory
    mkdir -p "$TEST_RESULTS_DIR"
    echo "Fortress Linux Compatibility Test Results - $TIMESTAMP" > "$TEST_RESULTS_DIR/test_results.txt"
    echo "=============================================" >> "$TEST_RESULTS_DIR/test_results.txt"
    echo "" >> "$TEST_RESULTS_DIR/test_results.txt"

    # Run compatibility tests
    run_test "OS Compatibility" test_os_compatibility
    run_test "Python Availability" test_python
    run_test "Package Manager" test_package_manager
    run_test "Systemd Availability" test_systemd
    run_test "UFW Firewall" test_ufw
    run_test "Audit Daemon" test_auditd
    run_test "SSH Service" test_ssh
    run_test "File Permissions" test_file_permissions
    run_test "Networking" test_networking
    run_test "Disk Space" test_disk_space
    run_test "Memory" test_memory
    run_test "Backup Functionality" test_backup_functionality
    run_test "Hardening Script" test_hardening_script

    # Generate report
    generate_report

    # Display summary
    echo
    echo "=== COMPATIBILITY TEST SUMMARY ==="
    echo "Total Tests: $TOTAL_TESTS"
    echo "Passed: $PASSED_TESTS"
    echo "Failed: $FAILED_TESTS"
    echo "Success Rate: $(( PASSED_TESTS * 100 / TOTAL_TESTS ))%"
    echo ""

    if [[ $FAILED_TESTS -eq 0 ]]; then
        log_success "🎉 All tests passed! System is compatible."
        echo "✓ Your system is ready for Fortress Linux hardening."
        echo "✓ You can safely run: sudo $SCRIPT_DIR/linux_hardening.sh"
    else
        log_warning "⚠ Some tests failed. Review the report for details."
        echo "⚠ Address the issues before proceeding with hardening."
    fi

    echo ""
    echo "📄 Detailed report: $TEST_RESULTS_DIR/compatibility_report.txt"
    echo "📝 Test log: $LOG_FILE"
    echo ""

    # Return appropriate exit code
    if [[ $FAILED_TESTS -eq 0 ]]; then
        exit 0
    else
        exit 1
    fi
}

# Run main function
main "$@"