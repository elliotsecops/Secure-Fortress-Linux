# Secure Fortress Linux (ESP)

Secure Fortress Linux es una solución automatizada de fortalecimiento diseñada para asegurar entornos Linux utilizando las mejores prácticas. Al aprovechar Ansible para la gestión de configuraciones y Wazuh para la monitorización, asegura una robusta seguridad del sistema mientras permite la monitorización continua de cumplimiento y la detección de rootkits.

## Tabla de Contenidos
- [Introducción](#introducción)
- [Características](#características)
- [Prerrequisitos](#prerrequisitos)
- [Estructura del Proyecto](#estructura-del-proyecto)
- [Instalación](#instalación)
- [Uso](#uso)
- [Script Bash (`linux_hardening.sh`)](#script-bash-linux_hardeningsh)
- [Correlación entre Componentes](#correlación-entre-componentes)
- [Contribuir](#contribuir)
- [Licencia](#licencia)

## Introducción

En el panorama digital actual, asegurar entornos Linux es más crítico que nunca. Secure Fortress Linux tiene como objetivo simplificar y automatizar el proceso de fortalecimiento de sistemas Linux, facilitando a los administradores el mantenimiento de un entorno seguro.

## Características

- **Fortalecimiento Automatizado de Linux**: Utiliza scripts de shell para fortalecer sistemas Linux, cubriendo áreas como actualizaciones del sistema, configuración del firewall, deshabilitación de servicios y más.
- **Integración con Wazuh**: Monitoreo y alertas en tiempo real con Wazuh, incluyendo detección de rootkits, monitoreo de integridad de archivos y recolección de logs.
- **Configurable con Ansible**: Implementaciones escalables utilizando playbooks de Ansible, permitiendo una fácil personalización y gestión de múltiples sistemas.
- **Registro**: Registra cada paso para una auditoría y solución de problemas fácil, asegurando transparencia y responsabilidad.

## Prerrequisitos

Antes de comenzar, asegúrate de tener lo siguiente instalado:
- **Ansible** (versión 2.9 o superior): Asegúrate de que Ansible esté instalado en tu sistema.
- **Python 3.x**: Asegúrate de que Python 3.x esté instalado en tu sistema.
- **Wazuh Agent**

## Estructura del Proyecto

```plaintext
.
├── config
│   ├── ansible.cfg
│   └── hosts
├── install_dependencies.sh
├── logs
│   └── deployment.log
├── playbooks
│   └── playbook_hardening.yml
├── scripts
│   └── linux_hardening.sh
└── templates
    └── wazuh-agent-config.j2
```

- **config/**: Archivos de configuración y inventario de Ansible.
- **install_dependencies.sh**: Script para instalar dependencias.
- **logs/**: Archivos de registro del proceso de implementación.
- **playbooks/**: Playbooks de Ansible para automatizar el proceso de fortalecimiento.
- **scripts/**: El script principal de shell para fortalecer sistemas Linux.
- **templates/**: Plantilla para la configuración del agente Wazuh.

## Instalación

1. **Clonar el Repositorio:**
   ```sh
   git clone https://github.com/elliotsecops/Secure-Fortress-Linux.git
   cd Secure-Fortress-Linux
   ```

2. **Ejecutar el Script de Instalación de Dependencias:**
   ```sh
   sudo ./install_dependencies.sh
   ```

### Script de Instalación de Dependencias (`install_dependencies.sh`)

El script `install_dependencies.sh` automatiza la descarga e instalación de dependencias para Secure Fortress Linux, incluyendo Python 3.x, Ansible y el Agente Wazuh. También verifica las instalaciones y proporciona registros detallados.

#### Características

- **Instalación Automatizada**: Instala Python 3.x, Ansible y el Agente Wazuh.
- **Confirmación del Usuario**: Solicita la confirmación del usuario antes de instalar cada dependencia.
- **Modo Verboso**: Proporciona una salida detallada durante el proceso de instalación.
- **Modo de Prueba**: Muestra qué acciones se tomarían sin realizarlas.
- **Manejo de Errores**: Incluye un manejo de errores robusto y funciones de limpieza.
- **Copia de Seguridad de Configuración**: Realiza una copia de seguridad de los archivos de configuración importantes antes de realizar cambios.
- **Verificación de Versiones**: Verifica las versiones de los paquetes instalados.
- **Verificación del Estado del Servicio**: Verifica el estado del servicio del Agente Wazuh.

#### Prerrequisitos

- Privilegios de root o sudo.
- Conexión a Internet.

#### Uso

1. **Hacer el Script Ejecutable**:
   ```sh
   chmod +x install_dependencies.sh
   ```

2. **Ejecutar el Script**:
   ```sh
   sudo ./install_dependencies.sh
   ```

#### Opciones

- `-v, --verbose`: Habilitar salida detallada.
- `-d, --dry-run`: Mostrar qué acciones se tomarían sin realizarlas.
- `-h, --help`: Mostrar este mensaje de ayuda.

#### Comandos de Ejemplo

- **Instalar Dependencias con Salida Detallada**:
  ```sh
  sudo ./install_dependencies.sh --verbose
  ```

- **Prueba**:
  ```sh
  sudo ./install_dependencies.sh --dry-run
  ```

- **Mostrar Ayuda**:
  ```sh
  sudo ./install_dependencies.sh --help
  ```

#### Solución de Problemas

##### Problemas Comunes

1. **Agente Wazuh No Funcionando**:
   - Asegúrate de que el servicio del Agente Wazuh esté iniciado:
     ```sh
     sudo systemctl start wazuh-agent
     ```
   - Verifica el estado del servicio:
     ```sh
     sudo systemctl status wazuh-agent
     ```

2. **Advertencias de Múltiples Repositorios**:
   - Asegúrate de que el repositorio de Wazuh no se haya añadido múltiples veces. El script ahora verifica la línea exacta del repositorio antes de añadirla.

3. **Comando No Encontrado**:
   - Asegúrate de que todas las dependencias necesarias estén instaladas. El script solicitará la instalación si falta alguna.

##### Registros

- El script registra todas las acciones en `install_dependencies.log`. Revisa este archivo para obtener información detallada sobre el proceso de instalación.

## Uso

1. **Personalizar la Configuración:**
   - Modifica el archivo `templates/wazuh-agent-config.j2` para que coincida con la configuración de tu servidor Wazuh.
   - Ajusta el script `scripts/linux_hardening.sh` para que se adapte a tus requisitos específicos de fortalecimiento.

2. **Ejecutar el Playbook:**
   ```sh
   ansible-playbook playbooks/playbook_hardening.yml
   ```

3. **Revisar los Registros:**
   - Verifica el archivo `logs/deployment.log` para obtener registros detallados del proceso de fortalecimiento.

## Script Bash (`linux_hardening.sh`)

El script `linux_hardening.sh` realiza varias tareas de fortalecimiento de seguridad en el sistema. Aquí tienes un desglose de lo que hace:

1. **Actualización del Sistema:**
   - Actualiza la lista de paquetes y actualiza todos los paquetes instalados a sus últimas versiones.

2. **Configuración del Firewall:**
   - Configura UFW (Uncomplicated Firewall) para bloquear todo el tráfico entrante por defecto y permitir todo el tráfico saliente.
   - Permite el tráfico SSH.
   - Habilita el firewall UFW.

3. **Deshabilitación de Servicios:**
   - Deshabilita servicios innecesarios como `avahi-daemon`, `cups` y `nfs-server`.

4. **Seguridad de Contraseñas:**
   - Mejora la seguridad de las contraseñas estableciendo una longitud mínima de contraseña de 12 caracteres y requiriendo al menos cuatro clases de caracteres (por ejemplo, mayúsculas, minúsculas, dígitos, caracteres especiales).

5. **Configuración de Auditd:**
   - Configura `auditd` para monitorear cambios en archivos críticos como `/etc/passwd`, `/etc/shadow`, `/etc/gshadow` y `/etc/group`.

6. **Permisos de Archivos y Directorios:**
   - Establece permisos básicos en archivos y directorios sensibles.

7. **Configuración de SSH:**
   - Deshabilita el inicio de sesión root a través de SSH.
   - Deshabilita la autenticación por contraseña para SSH, forzando el uso de claves SSH.
   - Reinicia el servicio SSH para aplicar la nueva configuración.

## Correlación entre Componentes

Los componentes de Secure Fortress Linux trabajan juntos para asegurar un fortalecimiento y monitoreo completo del sistema:

1. **Configuración de Ansible (`ansible.cfg`):**
   - Configura el entorno y el comportamiento para Ansible, incluyendo la gestión de inventarios, configuraciones de usuario remoto, registro, escalado de privilegios y opciones de conexión SSH.

2. **Script Bash (`linux_hardening.sh`):**
   - Realiza las tareas iniciales de fortalecimiento en el sistema, como actualizar el sistema, configurar el firewall y asegurar SSH.

3. **Plantilla de Configuración del Agente Wazuh (`wazuh-agent-config.j2`):**
   - Configura el agente Wazuh para monitorear y alertar sobre eventos relacionados con la seguridad, como la detección de rootkits, el monitoreo de integridad de archivos y la recolección de logs.

4. **Playbook de Ansible (`playbook_hardening.yml`):**
   - Orquesta la ejecución del script Bash y la configuración del agente Wazuh. Utiliza la plantilla `wazuh-agent-config.j2` para generar el archivo de configuración del agente Wazuh y lo aplica a los hosts objetivo.
     
**El script Bash `linux_hardening.sh` realiza las tareas iniciales de fortalecimiento en el sistema, mientras que la plantilla `wazuh-agent-config.j2` configura el agente Wazuh para monitorear y alertar sobre eventos relacionados con la seguridad. El playbook de Ansible (`playbook_hardening.yml`) orquesta la ejecución de estas tareas, asegurando un proceso de fortalecimiento y monitoreo automatizado y fluido.**

## Contribuir

¡Las contribuciones son bienvenidas! Por favor, consulta nuestra [Guía de Contribución](CONTRIBUTING.md) para más detalles.

## Licencia

Este proyecto está licenciado bajo la Licencia MIT. Consulta el archivo [LICENSE](LICENSE) para más detalles.

---

# Secure Fortress Linux (ENG)

Secure Fortress Linux is an automated hardening solution designed to secure Linux environments using best practices. By leveraging Ansible for configuration management and Wazuh for monitoring, it ensures robust system security while allowing continuous compliance monitoring and rootkit detection.

## Table of Contents
- [Introduction](#introduction)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Installation](#installation)
- [Usage](#usage)
- [Bash Script (`linux_hardening.sh`)](#bash-script-linux_hardeningsh)
- [Correlation Between Components](#correlation-between-components)
- [Contributing](#contributing)
- [License](#license)

## Introduction

In today's digital landscape, securing Linux environments is more critical than ever. Secure Fortress Linux aims to simplify and automate the process of hardening Linux systems, making it easier for administrators to maintain a secure environment.

## Features

- **Automated Linux Hardening:** Utilizes shell scripts to harden Linux systems, covering areas such as system updates, firewall configuration, service disabling, and more.
- **Wazuh Integration:** Real-time monitoring and alerting with Wazuh, including rootkit detection, file integrity monitoring, and log collection.
- **Configurable with Ansible:** Scalable deployments using Ansible playbooks, allowing easy customization and management of multiple systems.
- **Logging:** Logs every step for easy auditing and troubleshooting, ensuring transparency and accountability.

## Prerequisites

Before you start, ensure you have the following installed:
- **Ansible** (version 2.9 or higher): Ensure Ansible is installed on your system.
- **Python 3.x**: Ensure Python 3.x is installed on your system.
- **Wazuh Agent**

## Project Structure

```plaintext
.
├── config
│   ├── ansible.cfg
│   └── hosts
├── install_dependencies.sh
├── logs
│   └── deployment.log
├── playbooks
│   └── playbook_hardening.yml
├── scripts
│   └── linux_hardening.sh
└── templates
    └── wazuh-agent-config.j2
```

- **config/**: Ansible configuration files and inventory.
- **install_dependencies.sh**: Script to install dependencies.
- **logs/**: Log files of the deployment process.
- **playbooks/**: Ansible playbooks for automating the hardening process.
- **scripts/**: The main shell script for hardening Linux systems.
- **templates/**: Template for Wazuh agent configuration.

## Installation

1. **Clone the Repository:**
   ```sh
   git clone https://github.com/elliotsecops/Secure-Fortress-Linux.git
   cd Secure-Fortress-Linux
   ```

2. **Run the Dependency Installation Script:**
   ```sh
   sudo ./install_dependencies.sh
   ```

### Installation Dependencies Script (`install_dependencies.sh`)

The `install_dependencies.sh` script automates the download and installation of dependencies for Secure Fortress Linux, including Python 3.x, Ansible, and the Wazuh Agent. It also verifies the installations and provides detailed logging.

#### Features

- **Automated Installation**: Installs Python 3.x, Ansible, and the Wazuh Agent.
- **User Confirmation**: Prompts the user before installing each dependency.
- **Verbose Mode**: Provides detailed output during the installation process.
- **Dry-Run Mode**: Shows what actions would be taken without performing them.
- **Error Handling**: Includes robust error handling and cleanup functions.
- **Configuration Backup**: Backs up important configuration files before making changes.
- **Version Checking**: Checks the versions of installed packages.
- **Service Status Check**: Verifies the status of the Wazuh Agent service.

#### Prerequisites

- Root or sudo privileges.
- Internet connectivity.

#### Usage

1. **Make the Script Executable**:
   ```sh
   chmod +x install_dependencies.sh
   ```

2. **Run the Script**:
   ```sh
   sudo ./install_dependencies.sh
   ```

#### Options

- `-v, --verbose`: Enable verbose output.
- `-d, --dry-run`: Show what actions would be taken without performing them.
- `-h, --help`: Display this help message.

#### Example Commands

- **Install Dependencies with Verbose Output**:
  ```sh
  sudo ./install_dependencies.sh --verbose
  ```

- **Dry Run**:
  ```sh
  sudo ./install_dependencies.sh --dry-run
  ```

- **Display Help**:
  ```sh
  sudo ./install_dependencies.sh --help
  ```

#### Troubleshooting

##### Common Issues

1. **Wazuh Agent Not Running**:
   - Ensure the Wazuh Agent service is started:
     ```sh
     sudo systemctl start wazuh-agent
     ```
   - Check the service status:
     ```sh
     sudo systemctl status wazuh-agent
     ```

2. **Multiple Repository Warnings**:
   - Ensure the Wazuh repository is not added multiple times. The script now checks for the exact repository line before adding it.

3. **Command Not Found**:
   - Ensure all necessary dependencies are installed. The script will prompt for installation if any are missing.

##### Logs

- The script logs all actions to `install_dependencies.log`. Review this file for detailed information on the installation process.

## Usage

1. **Customize Configuration:**
   - Modify the `templates/wazuh-agent-config.j2` file to match your Wazuh server configuration.
   - Adjust the `scripts/linux_hardening.sh` script to fit your specific hardening requirements.

2. **Execute the Playbook:**
   ```sh
   ansible-playbook playbooks/playbook_hardening.yml
   ```

3. **Review Logs:**
   - Check the `logs/deployment.log` file for detailed logs of the hardening process.

## Bash Script (`linux_hardening.sh`)

The `linux_hardening.sh` script performs various security hardening tasks on the system. Here's a breakdown of what it does:

1. **System Update:**
   - Updates the package list and upgrades all installed packages to their latest versions.

2. **Firewall Configuration:**
   - Configures the UFW (Uncomplicated Firewall) to block all incoming traffic by default and allow all outgoing traffic.
   - Allows SSH traffic.
   - Enables the UFW firewall.

3. **Service Disabling:**
   - Disables unnecessary services such as `avahi-daemon`, `cups`, and `nfs-server`.

4. **Password Security:**
   - Enhances password security by setting minimum password length to 12 characters and requiring at least four character classes (e.g., uppercase, lowercase, digits, special characters).

5. **Auditd Configuration:**
   - Configures `auditd` to monitor changes to critical files like `/etc/passwd`, `/etc/shadow`, `/etc/gshadow`, and `/etc/group`.

6. **File and Directory Permissions:**
   - Sets basic permissions on sensitive files and directories.

7. **SSH Configuration:**
   - Disables root login via SSH.
   - Disables password authentication for SSH, forcing the use of SSH keys.
   - Restarts the SSH service to apply the new configuration.

## Correlation Between Components

The components of Secure Fortress Linux work together to ensure comprehensive system hardening and monitoring:

1. **Ansible Configuration (`ansible.cfg`):**
   - Sets up the environment and behavior for Ansible, including inventory management, remote user settings, logging, privilege escalation, and SSH connection options.

2. **Bash Script (`linux_hardening.sh`):**
   - Performs the initial hardening tasks on the system, such as updating the system, configuring the firewall, and securing SSH.

3. **Wazuh Agent Configuration Template (`wazuh-agent-config.j2`):**
   - Configures the Wazuh agent to monitor and alert on security-related events, such as rootkit detection, file integrity monitoring, and log collection.

4. **Ansible Playbook (`playbook_hardening.yml`):**
   - Orchestrates the execution of the Bash script and the configuration of the Wazuh agent. It uses the `wazuh-agent-config.j2` template to generate the Wazuh agent configuration file and applies it to the target hosts.

### Highlights:
The `linux_hardening.sh` Bash script performs the initial hardening tasks on the system, while the `wazuh-agent-config.j2` template configures the Wazuh agent to monitor and alert on security-related events. The Ansible playbook (`playbook_hardening.yml`) orchestrates the execution of these tasks, ensuring a seamless and automated hardening and monitoring process.

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for more details.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.

