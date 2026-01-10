FROM ubuntu:22.04

LABEL maintainer="elliotsecops"
LABEL description="Fortress Linux - System Security Hardening Framework"

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# Install base dependencies
RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    lsb-release \
    software-properties-common \
    git \
    vim \
    net-tools \
    iputils-ping \
    && rm -rf /var/lib/apt/lists/*

# Install Python 3 and pip
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# Install Ansible
RUN apt-get update && apt-get install -y \
    ansible \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
RUN pip3 install --upgrade pip && \
    pip3 install \
    pytest \
    pytest-cov \
    testinfra \
    molecule[docker] \
    ansible-lint \
    yamllint \
    flake8 \
    black \
    bandit \
    safety \
    trivy

# Create working directory
WORKDIR /fortress-linux

# Copy fortress-linux files
COPY . /fortress-linux/

# Make scripts executable
RUN chmod +x /fortress-linux/scripts/*.sh

# Set entrypoint
ENTRYPOINT ["/bin/bash"]
CMD ["--help"]
