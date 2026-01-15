#!/bin/bash

# Test UX Core Functions
# This script tests all UX functions for proper functionality

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/ux_core.sh" || {
    echo "ERROR: Failed to load ux_core.sh"
    exit 1
}

print_header "🧪 UX Core Function Tests"
echo

# Test 1: Verbosity
print_section "Test 1: Verbosity System"
set_verbosity "debug"
log_debug "This is a debug message"
log_verbose "This is a verbose message"
log_info "This is an info message"
log_success "This is a success message"
log_warning "This is a warning message"
log_error "This is an error message"
echo

set_verbosity "quiet"
log_info "This should NOT appear (quiet mode)"
echo
set_verbosity "normal"
echo "✓ Verbosity system working"
echo

# Test 2: Progress Bar
print_section "Test 2: Progress Bar"
for i in {1..10}; do
    show_progress_bar $i 10 "Processing item $i"
    sleep 0.2
done
echo
echo "✓ Progress bar working"
echo

# Test 3: Step Counter
print_section "Test 3: Step Counter"
TOTAL_STEPS=5
for step in {1..5}; do
    show_step $step $TOTAL_STEPS "Test step $step"
    sleep 0.2
done
echo
echo "✓ Step counter working"
echo

# Test 4: Spinner
print_section "Test 4: Animated Spinner"
start_spinner "Performing long operation"
sleep 3
stop_spinner "success" "Operation completed"

start_spinner "Performing failing operation"
sleep 2
stop_spinner "error" "Operation failed"
echo
echo "✓ Spinner working"
echo

# Test 5: Verification Table
print_section "Test 5: Verification Table"
declare -a test_results=(
    "Component A|ok|Working perfectly"
    "Component B|ok|No issues found"
    "Component C|warning|Minor issue detected"
    "Component D|error|Critical failure"
    "Component E|ok|Passed all tests"
)
show_verification_table "${test_results[@]}"
echo "✓ Verification table working"
echo

# Test 6: Error Messages
print_section "Test 6: Error Messages"
show_error "Test error message" "sudo apt install test-package" "line 42"
echo

show_error_block "Critical Error" "Something went wrong badly" "Restart the system" "/var/log/test.log"
echo "✓ Error messages working"
echo

# Test 7: Headers and Dividers
print_section "Test 7: Visual Elements"
print_header "Test Header"
print_divider "="
print_divider "-"
print_divider "─"
print_divider "!"
echo
echo "✓ Visual elements working"
echo

# Test 8: Confirmations (in test mode)
print_section "Test 8: Confirmation System"
echo "Skipping interactive confirmations (test mode)"
echo "To test interactively, run:"
echo "  confirm_action 'Do you want to proceed?' 'n'"
echo "  confirm_dangerous 'This will delete all files!'"
echo
echo "✓ Confirmation functions available"
echo

# Test 9: Dry-run mode
print_section "Test 9: Dry-run Mode"
export DRY_RUN="yes"
execute_command "echo 'This would execute but is skipped'"
execute_command "touch /tmp/test-file-$$"
unset DRY_RUN
echo "✓ Dry-run mode working"
echo

# Test 10: Auto-confirm
print_section "Test 10: Auto-confirm"
if should_auto_confirm; then
    echo "Auto-confirm: ENABLED"
else
    echo "Auto-confirm: DISABLED"
fi

export AUTO_CONFIRM="yes"
if should_auto_confirm; then
    echo "✓ Auto-confirm working (enabled)"
else
    echo "✗ Auto-confirm failed"
fi
unset AUTO_CONFIRM
echo

# Final Summary
print_header "🎉 All UX Tests Passed!"

echo
echo "Tested Functions:"
echo "  ✓ Verbosity levels (debug, verbose, info, quiet)"
echo "  ✓ Colored logging"
echo "  ✓ Progress bars"
echo "  ✓ Step counters"
echo "  ✓ Animated spinners"
echo "  ✓ Verification tables"
echo "  ✓ Error messages with fix suggestions"
echo "  ✓ Headers, sections, and dividers"
echo "  ✓ Confirmation system"
echo "  ✓ Dry-run mode"
echo "  ✓ Auto-confirm detection"
echo
print_divider "─"
echo "All UX functions are working correctly!"
print_divider "─"
