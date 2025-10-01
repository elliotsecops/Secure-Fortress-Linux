#!/bin/bash

# Quick System Compatibility Check for Fortress Linux
# Tests basic system requirements

set -euo pipefail

echo "=== Fortress Linux System Compatibility Check ==="
echo "System: $(lsb_release -d 2>/dev/null || echo 'Unknown')"
echo "Kernel: $(uname -r)"
echo "Architecture: $(uname -m)"
echo "Date: $(date)"
echo

# Check Ubuntu/Debian version
if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    echo "OS: $PRETTY_NAME"
    echo "Version: $VERSION_ID"

    case "$ID" in
        ubuntu)
            if [[ "${VERSION_ID%%.*}" -ge 22 ]]; then
                echo "✅ Ubuntu $VERSION_ID is supported"
            else
                echo "⚠️  Ubuntu $VERSION_ID - consider upgrading to 22.04+"
            fi
            ;;
        debian)
            if [[ "${VERSION_ID%%.*}" -ge 12 ]]; then
                echo "✅ Debian $VERSION_ID is supported"
            else
                echo "⚠️  Debian $VERSION_ID - consider upgrading to 12+"
            fi
            ;;
        *)
            echo "⚠️  Unsupported OS: $ID"
            ;;
    esac
    echo
fi

# Check Python
if command -v python3 >/dev/null 2>&1; then
    echo "✅ Python: $(python3 --version)"
else
    echo "❌ Python 3 not found"
fi

# Check systemd
if command -v systemctl >/dev/null 2>&1; then
    echo "✅ Systemd: $(systemctl --version | head -n1)"
else
    echo "❌ Systemd not found"
fi

# Check package manager
if command -v apt >/dev/null 2>&1; then
    echo "✅ APT package manager available"
else
    echo "❌ APT package manager not found"
fi

# Check disk space
available_gb=$(df -BG / | awk 'NR==2{print $4}' | tr -d 'G')
if [[ $available_gb -ge 1 ]]; then
    echo "✅ Disk space: ${available_gb}GB available"
else
    echo "❌ Insufficient disk space: ${available_gb}GB"
fi

# Check memory
total_mb=$(free -m | awk 'NR==2{print $2}')
if [[ $total_mb -ge 512 ]]; then
    echo "✅ Memory: ${total_mb}MB total"
else
    echo "⚠️  Low memory: ${total_mb}MB"
fi

# Check SSH
if command -v sshd >/dev/null 2>&1; then
    echo "✅ SSH daemon available"
else
    echo "❌ SSH daemon not found"
fi

# Check UFW (will be installed if missing)
if command -v ufw >/dev/null 2>&1; then
    echo "✅ UFW firewall available"
else
    echo "ℹ️  UFW will be installed during hardening"
fi

# Check auditd (will be installed if missing)
if command -v auditd >/dev/null 2>&1; then
    echo "✅ Audit daemon available"
else
    echo "ℹ️  Audit daemon will be installed during hardening"
fi

echo
echo "=== Summary ==="
echo "Your system appears to be compatible with Fortress Linux."
echo "You can proceed with the hardening process."
echo
echo "Next steps:"
echo "1. Create a backup: sudo ./scripts/backup_restore.sh backup"
echo "2. Run hardening: sudo ./scripts/linux_hardening.sh"