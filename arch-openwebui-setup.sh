#!/bin/bash

# Arch Linux Post-Install Script for OpenWebUI + Ollama Server
# This script prepares an Arch Linux system to run OpenWebUI and Ollama

set -Eeuo pipefail

# Ensure uv is available in PATH if installed
if [ -d "$HOME/.local/bin" ]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

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
        export PATH="$HOME/.local/bin:$PATH"
        
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

# Step 6: Install Caddy
install_caddy() {
    log_info "Installing Caddy web server..."
    
    if command_exists caddy; then
        log_info "Caddy is already installed. Version: $(caddy version)"
    else
        log_info "Installing Caddy..."
        sudo pacman -S --noconfirm caddy
        
        # Enable and start Caddy service
        sudo systemctl enable --now caddy
        log_success "Caddy installed and started successfully"
    fi
}

# Step 7: Configure Caddy with self-signed certificates
configure_caddy() {
    log_info "Configuring Caddy with self-signed certificates..."
    
    # Create Caddy data directory
    sudo mkdir -p /var/lib/caddy
    
    # Create Caddyfile
    sudo tee /etc/caddy/Caddyfile > /dev/null << 'EOF'
# AI-Premise HTTPS Configuration
{
    # Enable automatic HTTPS with self-signed certificates
    auto_https off
    # Use internal CA for self-signed certs
    local_certs
}

# OpenWebUI HTTPS Proxy
openwebui.local {
    tls internal
    reverse_proxy 127.0.0.1:8080
    header_up Host {host}
    header_up X-Real-IP {remote}
    header_up X-Forwarded-For {remote}
    header_up X-Forwarded-Proto {scheme}
}

# Ollama API HTTPS Proxy
ollama.local {
    tls internal
    reverse_proxy 127.0.0.1:11434
    header_up Host {host}
    header_up X-Real-IP {remote}
    header_up X-Forwarded-For {remote}
    header_up X-Forwarded-Proto {scheme}
}

# Glances System Monitor HTTPS Proxy
monitor.local {
    tls internal
    reverse_proxy 127.0.0.1:61208
    header_up Host {host}
    header_up X-Real-IP {remote}
    header_up X-Forwarded-For {remote}
    header_up X-Forwarded-Proto {scheme}
}

# Main dashboard (redirects to OpenWebUI)
ai-premise.local {
    tls internal
    redir / https://openwebui.local{uri} permanent
}
EOF

    # Set proper permissions
    sudo chown caddy:caddy /etc/caddy/Caddyfile
    sudo chmod 644 /etc/caddy/Caddyfile
    
    # Restart Caddy to apply configuration
    sudo systemctl restart caddy
    
    log_success "Caddy configured with self-signed certificates"
    log_info "HTTPS endpoints:"
    log_info "  - OpenWebUI: https://openwebui.local"
    log_info "  - Ollama API: https://ollama.local"
    log_info "  - System Monitor: https://monitor.local"
    log_info "  - Dashboard: https://ai-premise.local"
}

# Step 8: Install and Launch OpenWebUI
install_openwebui() {
    log_info "Installing and launching OpenWebUI..."
    
    # Ensure uv is in PATH
    export PATH="$HOME/.local/bin:$PATH"
    
    # Set data directory
    export DATA_DIR="$HOME/.open-webui"
    
    # Create data directory if it doesn't exist
    mkdir -p "$DATA_DIR"
    
    log_info "Starting OpenWebUI server..."
    log_info "Data directory: $DATA_DIR"
    log_info "OpenWebUI will be available at:"
    log_info "  - HTTP: http://localhost:8080"
    log_info "  - HTTPS: https://openwebui.local"
    
    # Launch OpenWebUI
    uvx --python 3.11 open-webui@latest serve
    
    # Note: This will run in foreground. For production, consider creating a systemd service
    # TODO: Add systemd service integration for production deployment
}

# Step 9: Configure hosts file
configure_hosts() {
    log_info "Configuring /etc/hosts for local domains..."
    
    # Check if entries already exist
    if grep -q "openwebui.local" /etc/hosts; then
        log_info "Host entries already exist in /etc/hosts"
    else
        log_info "Adding local domain entries to /etc/hosts..."
        echo "127.0.0.1 openwebui.local ollama.local ai-premise.local monitor.local" | sudo tee -a /etc/hosts > /dev/null
        log_success "Local domains added to /etc/hosts"
    fi
}

# Step 10: Configure UFW Firewall
configure_firewall() {
    log_info "Configuring UFW firewall..."
    
    if command_exists ufw; then
        log_info "UFW is already installed"
    else
        log_info "Installing UFW firewall..."
        sudo pacman -S --noconfirm ufw
        log_success "UFW installed successfully"
    fi
    
    # Reset UFW to default state
    log_info "Resetting UFW to default state..."
    sudo ufw --force reset
    
    # Set default policies
    log_info "Setting default firewall policies..."
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    
    # Allow SSH (in case user needs remote access)
    log_info "Allowing SSH access..."
    sudo ufw allow ssh
    
    # Allow HTTPS traffic on port 443
    log_info "Allowing HTTPS traffic on port 443..."
    sudo ufw allow 443/tcp
    
    # Enable UFW
    log_info "Enabling UFW firewall..."
    sudo ufw --force enable
    
    # Show firewall status
    log_success "UFW firewall configured successfully"
    log_info "Firewall status:"
    sudo ufw status numbered
    
    log_info "Firewall rules:"
    log_info "  - SSH (port 22): ALLOWED"
    log_info "  - HTTPS (port 443): ALLOWED"
    log_info "  - All other incoming traffic: DENIED"
    log_info "  - All outgoing traffic: ALLOWED"
}

# Step 11: Install and Configure Glances
install_glances() {
    log_info "Installing Glances system monitor..."
    
    if command_exists glances; then
        log_info "Glances is already installed. Version: $(glances --version)"
    else
        log_info "Installing Glances..."
        sudo pacman -S --noconfirm glances
        log_success "Glances installed successfully"
    fi
    
    # Create glances config directory
    log_info "Creating Glances configuration..."
    mkdir -p ~/.config/glances
    
    # Create custom glances configuration
    cat > ~/.config/glances/glances.conf << 'EOF'
# ~/.config/glances/glances.conf
# 🌡️ Minimal Glances config for system monitoring (with temperatures)
# Author: Stradex

[global]
theme = white
check_update = False
disable = true   # disable all plugins by default

# 🧩 Enable only desired plugins
[plugins]
enable = cpu, mem, fs, gpu, sensors

# 🧠 CPU Section
[cpu]
enable = true
percpu = true
show_cpu_temp = true
alias = 🧠 CPU Usage 🌡️

# 💾 Memory Section
[mem]
enable = true
show_swap = True
alias = 💾 Memory

# 📀 Disk Section (Filesystem)
[fs]
enable = true
hide_fs_type = tmpfs,devtmpfs
hide_mount_point = /boot,/run
alias = 📀 Disk Usage 🌡️

# 🎮 GPU Section
[gpu]
enable = true
show_name = true
show_memory = true
show_temp = true
show_power = false
show_clock = false
alias = 🎮 GPU 🌡️

# 🌡️ Sensors (for CPU, motherboard, or SSD temps)
[sensors]
enable = true
alias = 🔥 System Temps
hide_temp_under = 35  # optional: hide sensors under 35°C

# 🔌 Disable everything else
[network]
enable = false

[docker]
enable = false

[processlist]
enable = false

[quicklook]
enable = false
EOF

    log_success "Glances configuration created"
}

# Step 12: Configure Glances Web Server
configure_glances_web() {
    log_info "Configuring Glances web server..."
    
    # Create systemd service for Glances web server
    sudo tee /etc/systemd/system/glances-web.service > /dev/null << 'EOF'
[Unit]
Description=Glances Web Server
After=network.target

[Service]
Type=simple
User=stradex
Group=stradex
ExecStart=/usr/bin/glances -w -B 127.0.0.1 -p 61208
Restart=always
RestartSec=10
Environment=HOME=/home/stradex

[Install]
WantedBy=multi-user.target
EOF

    # Replace 'stradex' with actual username
    sudo sed -i "s/stradex/$USER/g" /etc/systemd/system/glances-web.service
    
    # Reload systemd and enable service
    sudo systemctl daemon-reload
    sudo systemctl enable glances-web
    sudo systemctl start glances-web
    
    log_success "Glances web server configured and started"
    log_info "Glances web interface available at: http://127.0.0.1:61208"
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
    install_caddy
    configure_caddy
    configure_hosts
    configure_firewall
    install_glances
    configure_glances_web
    install_openwebui
    
    log_success "Setup completed successfully!"
    log_info "Services are now running:"
    log_info "  - OpenWebUI HTTP: http://localhost:8080 (local only)"
    log_info "  - OpenWebUI HTTPS: https://openwebui.local"
    log_info "  - Ollama API HTTP: http://127.0.0.1:11434 (local only)"
    log_info "  - Ollama API HTTPS: https://ollama.local"
    log_info "  - System Monitor HTTP: http://127.0.0.1:61208 (local only)"
    log_info "  - System Monitor HTTPS: https://monitor.local"
    log_info "  - Main Dashboard: https://ai-premise.local"
    log_info "Local domains have been automatically configured in /etc/hosts"
    log_info "UFW firewall is active - only HTTPS (port 443) and SSH (port 22) are accessible externally"
}

# Run main function
main "$@"
