#!/bin/bash

# Actualizar el sistema
echo "Actualizando el sistema..."
apt update && apt upgrade -y

# Habilitar y configurar UFW (Uncomplicated Firewall)
echo "Configurando firewall UFW..."
ufw default deny incoming
ufw default allow outgoing
ufw allow OpenSSH
ufw enable

# Deshabilitar servicios innecesarios
echo "Deshabilitando servicios innecesarios..."
systemctl disable avahi-daemon
systemctl disable cups
systemctl disable nfs-server

# Aumentar la seguridad de las contraseñas
echo "Reforzando políticas de contraseñas..."
if ! grep -q "^minlen" /etc/security/pwquality.conf; then
    echo "minlen = 12" >> /etc/security/pwquality.conf
fi
if ! grep -q "^minclass" /etc/security/pwquality.conf; then
    echo "minclass = 4" >> /etc/security/pwquality.conf
fi

# Configuración de auditd para monitorear cambios en archivos críticos
echo "Configurando auditoría con auditd..."
cat <<EOF > /etc/audit/rules.d/hardening.rules
-w /etc/passwd -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/gshadow -p wa -k identity
-w /etc/group -p wa -k identity
EOF
systemctl restart auditd

# Configurar permisos básicos de archivos y directorios
echo "Configurando permisos en archivos y directorios sensibles..."
chmod 640 /etc/shadow
chmod 600 /etc/gshadow
chmod 644 /etc/passwd
chmod 644 /etc/group

# Configuración de SSH para mayor seguridad
echo "Ajustando configuración de SSH..."
sed -i "s/^#PermitRootLogin.*/PermitRootLogin no/" /etc/ssh/sshd_config
sed -i "s/^#PasswordAuthentication.*/PasswordAuthentication no/" /etc/ssh/sshd_config
systemctl restart sshd

echo "Hardening completado. Sistema endurecido."