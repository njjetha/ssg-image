# Copyright (c) Qualcomm Technologies, Inc. and/or its subsidiaries.
# SPDX-License-Identifier: BSD-3-Clause-Clear

#!/bin/bash

###############################################################################
# setup.sh - Environment setup script for Qualcomm Linux kernel development
#
# Usage:
#   ./setup.sh [--kernel <kernel_repo_url>] [--branch <branch_name>] [--ramdisk]
#
# Options:
#   --kernel   URL of the kernel repository to clone (default: https://github.com/qualcomm-linux/kernel.git)
#   --branch   Branch name to checkout from the kernel repository (default: qcom-next)
#   --ramdisk  If specified, downloads a default ramdisk image
#
# Description:
#   This script sets up a development environment for building the Qualcomm
#   Linux kernel using Docker. It installs Docker if not present, builds a
#   Docker image, sets up useful aliases for kernel compilation, clones the
#   kernel repository, and downloads systemd boot binaries and optionally a
#   ramdisk image.
#
# Notes:
#   - Run this script from your workspace directory.
#   - After running, restart your terminal or run `source ~/.bashrc` to activate aliases.
###############################################################################
#!/usr/bin/env bash
set -euo pipefail
set -e

echo "Installing prerequisites..."
if ! command -v sudo >/dev/null 2>&1; then
  echo "Error: sudo is required."
  exit 1
fi
sudo -v
sudo apt-get update -y
sudo apt-get install -y ca-certificates curl gnupg lsb-release git

echo "Installing Docker (if not already installed)..."
if ! command -v docker >/dev/null 2>&1; then
  # Prefer Docker CE repo; fallback to Ubuntu docker.io if needed
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release; echo $VERSION_CODENAME) stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  sudo apt-get update -y || true
  if ! sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
    echo "Falling back to Ubuntu's docker.io..."
    sudo apt-get install -y docker.io
  fi
else
  echo "Docker already installed: $(docker --version)"
fi

echo "Starting Docker service..."
if command -v systemctl >/dev/null 2>&1; then
  sudo systemctl enable --now docker || sudo systemctl start docker || true
else
  sudo service docker start || true
fi

USER=${USER:-$(whoami)}
echo "Configuring group for sudo-less docker..."
sudo groupadd docker 2>/dev/null || true
ADDED_TO_DOCKER_GROUP=0
if ! id -nG "$USER" | grep -qw docker; then
  sudo usermod -aG docker "$USER"
  ADDED_TO_DOCKER_GROUP=1
fi

# Use sudo for docker in this session if group change isn't active yet
DOCKER_CMD="docker"
if [[ "$ADDED_TO_DOCKER_GROUP" -eq 1 ]]; then
  DOCKER_CMD="sudo docker"
fi

# Optionally build the image if a Dockerfile is present
if [[ -f Dockerfile ]]; then
  echo "Building Docker image 'ssg-image'..."
  $DOCKER_CMD build \
    --build-arg USER_ID="$(id -u)" \
    --build-arg GROUP_ID="$(id -g)" \
    --build-arg USER_NAME="$(whoami)" \
    -t ssg-image .
else
  echo "Note: No Dockerfile in $(pwd). Skipping image build. Aliases will expect an image named 'ssg-image'."
fi

echo "Setting up aliases..."
BASHRC="$HOME/.bashrc"
touch "$BASHRC"
add_alias() { local line="$1"; grep -qxF "$line" "$BASHRC" 2>/dev/null || echo "$line" >> "$BASHRC"; }
echo "" >> "$BASHRC"
add_alias "# ssg-image Docker aliases"
add_alias "alias ssg-image-run='docker run -it --rm --user \$(id -u):\$(id -g) --workdir=\"\$PWD\" -v \"\$(pwd)\":\"\$(pwd)\" -v \"\$(dirname \"\$PWD\")\":\"\$(dirname \"\$PWD\")\" ssg-image'"
#add_alias "alias ssg_docker='ssg-image-run make'"

echo ""
echo "Done."
if [[ "$ADDED_TO_DOCKER_GROUP" -eq 1 ]]; then
  echo "NOTE: Open a new terminal or run: newgrp docker to use docker without sudo."
fi
echo "Run: source ~/.bashrc to activate aliases."
