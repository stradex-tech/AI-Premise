#!/bin/bash

# Arch Linux Post-Install Script for OpenWebUI + Ollama Server
# This script prepares an Arch Linux system to run OpenWebUI and Ollama

set -Eeuo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if a package is installed
package_installed() {
    pacman -Q "$1" >/dev/null 2>&1
}

# Function to handle pacman lock files
handle_pacman_lock() {
    if [ -f /var/lib/pacman/db.lck ]; then
        log_warning "Pacman lock file detected. Removing..."
        sudo rm -f /var/lib/pacman/db.lck
    fi
}

# Step 1: System Update
system_update() {
    log_info "Starting system update and upgrade..."
    
    handle_pacman_lock
    
    # Update package database
    log_info "Updating package database..."
    sudo pacman -Sy --noconfirm
    
    # Upgrade all packages
    log_info "Upgrading all packages..."
    sudo pacman -Su --noconfirm
    
    log_success "System update completed successfully"
}

# Step 2: GPU Detection and Driver Install
install_gpu_drivers() {
    log_info "Detecting GPU and installing appropriate drivers..."
    
    # Detect GPU vendor
    if command_exists lspci; then
        GPU_VENDOR=$(lspci | grep -i vga | head -1 | tr '[:upper:]' '[:lower:]')
        log_info "Detected GPU: $GPU_VENDOR"
        
        if echo "$GPU_VENDOR" | grep -q nvidia; then
            install_nvidia_drivers
        elif echo "$GPU_VENDOR" | grep -q amd; then
            install_amd_drivers
        elif echo "$GPU_VENDOR" | grep -q intel; then
            install_intel_drivers
        else
            log_warning "Unknown GPU vendor detected. Skipping driver installation."
        fi
    else
        log_warning "lspci not found. Cannot detect GPU. Skipping driver installation."
    fi
}

install_nvidia_drivers() {
    log_info "Installing NVIDIA drivers..."
    
    # Check if NVIDIA drivers are already installed
    if package_installed nvidia && package_installed nvidia-utils && package_installed cuda; then
        log_info "NVIDIA drivers already installed. Skipping..."
        return
    fi
    
    # Install NVIDIA packages
    sudo pacman -S --noconfirm nvidia nvidia-utils cuda
    
    # Enable nvidia-persistenced
    sudo systemctl enable nvidia-persistenced
    
    log_success "NVIDIA drivers installed successfully"
}

install_amd_drivers() {
    log_info "Installing AMD ROCm drivers..."
    
    # Check if AMD drivers are already installed
    if package_installed rocm-hip-runtime && package_installed rocm-opencl-runtime; then
        log_info "AMD ROCm drivers already installed. Skipping..."
        return
    fi
    
    # Install AMD packages
    sudo pacman -S --noconfirm rocm-hip-runtime rocm-opencl-runtime
    
    log_success "AMD ROCm drivers installed successfully"
}

install_intel_drivers() {
    log_info "Installing Intel compute runtime drivers..."
    
    # Check if Intel drivers are already installed
    if package_installed intel-compute-runtime && package_installed level-zero-loader; then
        log_info "Intel compute runtime drivers already installed. Skipping..."
        return
    fi
    
    # Install Intel packages
    sudo pacman -S --noconfirm intel-compute-runtime level-zero-loader
    
    log_success "Intel compute runtime drivers installed successfully"
}

# Step 3: Ensure Curl Installed
ensure_curl() {
    log_info "Ensuring curl is installed..."
    
    if command_exists curl; then
        log_info "curl is already installed"
    else
        log_info "Installing curl..."
        sudo pacman -S --noconfirm curl
        log_success "curl installed successfully"
    fi
}

# Step 4: Install Astral uv
install_uv() {
    log_info "Installing Astral uv..."
    
    if command_exists uv; then
        log_info "uv is already installed. Version: $(uv --version)"
    else
        log_info "Downloading and installing uv..."
        curl -LsSf https://astral.sh/uv/install.sh | sh
        
        # Add uv to PATH for current session
        export PATH="$HOME/.cargo/bin:$PATH"
        
        # Verify installation
        if command_exists uv; then
            log_success "uv installed successfully. Version: $(uv --version)"
        else
            log_error "Failed to install uv"
            exit 1
        fi
    fi
}

# Step 5: Install Ollama
install_ollama() {
    log_info "Installing Ollama..."
    
    if command_exists ollama; then
        log_info "Ollama is already installed. Version: $(ollama --version)"
    else
        log_info "Downloading and installing Ollama..."
        curl -fsSL https://ollama.com/install.sh | sh
        log_success "Ollama installed successfully"
    fi
    
    # Enable and start Ollama service
    log_info "Enabling and starting Ollama service..."
    sudo systemctl enable --now ollama
    
    # Wait a moment for service to start
    sleep 3
    
    # Verify Ollama is running
    if systemctl is-active --quiet ollama; then
        log_success "Ollama service is running"
    else
        log_warning "Ollama service may not be running properly"
    fi
    
    # Test Ollama API
    log_info "Testing Ollama API..."
    if curl -s http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
        log_success "Ollama API is responding"
    else
        log_warning "Ollama API is not responding. Service may still be starting up."
    fi
}

# Step 6: Install and Launch OpenWebUI
install_openwebui() {
    log_info "Installing and launching OpenWebUI..."
    
    # Ensure uv is in PATH
    export PATH="$HOME/.cargo/bin:$PATH"
    
    # Set data directory
    export DATA_DIR="$HOME/.open-webui"
    
    # Create data directory if it doesn't exist
    mkdir -p "$DATA_DIR"
    
    log_info "Starting OpenWebUI server..."
    log_info "Data directory: $DATA_DIR"
    log_info "OpenWebUI will be available at: http://localhost:8080"
    
    # Launch OpenWebUI
    uvx --python 3.11 open-webui@latest serve
    
    # Note: This will run in foreground. For production, consider creating a systemd service
    # TODO: Add systemd service integration for production deployment
}

# Main execution
main() {
    log_info "Starting Arch Linux OpenWebUI + Ollama setup..."
    log_info "This script will install and configure OpenWebUI and Ollama on your system"
    
    # Execute steps in order
    system_update
    install_gpu_drivers
    ensure_curl
    install_uv
    install_ollama
    install_openwebui
    
    log_success "Setup completed successfully!"
    log_info "OpenWebUI should now be running at http://localhost:8080"
    log_info "Ollama API is available at http://127.0.0.1:11434"
}

# Run main function
main "$@"
