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
        GPU_VENDOR=$(lspci 2>/dev/null | grep -E 'VGA|3D|Display' 2>/dev/null | grep -i -o 'nvidia\|amd\|intel' 2>/dev/null | head -1 || echo "")
        
        if [ -z "$GPU_VENDOR" ]; then
            log_info "No GPU detected. Skipping GPU driver installation."
            log_info "System will run with CPU-only processing."
            log_success "GPU detection completed - CPU-only mode"
            return 0
        fi
        
        log_info "Detected GPU vendor: $GPU_VENDOR"
        
        case "$GPU_VENDOR" in
            nvidia)
                install_nvidia_drivers
                ;;
            amd)
                install_amd_drivers
                ;;
            intel)
                install_intel_drivers
                ;;
            *)
                log_warning "Unknown GPU vendor: $GPU_VENDOR. Skipping driver installation."
                ;;
        esac
    else
        log_warning "lspci not found. Cannot detect GPU. Skipping driver installation."
        log_info "System will run with CPU-only processing."
    fi
    
    log_success "GPU detection and driver installation completed"
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

# Step 3: Ensure Essential Tools Installed
ensure_essential_tools() {
    log_info "Ensuring essential tools are installed..."
    
    # Install curl
    if command_exists curl; then
        log_info "curl is already installed"
    else
        log_info "Installing curl..."
        sudo pacman -S --noconfirm curl
        log_success "curl installed successfully"
    fi
    
    # Install OpenSSH
    if command_exists ssh; then
        log_info "OpenSSH is already installed"
    else
        log_info "Installing OpenSSH..."
        sudo pacman -S --noconfirm openssh
        log_success "OpenSSH installed successfully"
    fi
    
    # Enable and start SSH service
    log_info "Configuring SSH service..."
    sudo systemctl enable sshd
    sudo systemctl start sshd
    
    # Verify SSH is running
    if systemctl is-active --quiet sshd; then
        log_success "SSH service is running"
    else
        log_warning "SSH service may not be running properly"
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

# Step 6: Install Nginx
install_nginx() {
    log_info "Installing Nginx web server..."
    
    if command_exists nginx; then
        log_info "Nginx is already installed. Version: $(nginx -v 2>&1)"
    else
        log_info "Installing Nginx and OpenSSL..."
        sudo pacman -S --noconfirm --needed nginx openssl
        
        # Wait a moment for installation to complete
        sleep 2
        
        # Verify installation
        if command_exists nginx; then
            log_success "Nginx installed successfully"
        else
            log_error "Failed to install Nginx"
            exit 1
        fi
    fi
}

# Step 7: Configure Nginx with self-signed certificates
configure_nginx() {
    log_info "Configuring Nginx with self-signed certificates..."
    
    # Create SSL directory
    sudo mkdir -p /etc/nginx/ssl
    
    # Generate self-signed certificate (10 years validity)
    log_info "Generating self-signed SSL certificate..."
    sudo openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/nginx.key \
        -out /etc/nginx/ssl/nginx.crt \
        -subj "/C=US/ST=State/L=City/O=AI-Premise/CN=localhost" \
        -addext "subjectAltName=DNS:openwebui.local,DNS:ollama.local,DNS:monitor.local,DNS:localhost,IP:127.0.0.1"
    
    # Set proper permissions
    sudo chmod 600 /etc/nginx/ssl/nginx.key
    sudo chmod 644 /etc/nginx/ssl/nginx.crt
    
    # Create Nginx configuration
    sudo tee /etc/nginx/nginx.conf > /dev/null << 'EOF'
user http;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';
    
    access_log /var/log/nginx/access.log main;
    
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    # SSL Configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # OpenWebUI HTTPS Proxy (port 8443)
    server {
        listen 8443 ssl http2;
        server_name _;
        
        ssl_certificate /etc/nginx/ssl/nginx.crt;
        ssl_certificate_key /etc/nginx/ssl/nginx.key;
        
        location / {
            proxy_pass http://127.0.0.1:8080;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Forwarded-Host $host;
            proxy_set_header X-Forwarded-Port $server_port;
        }
    }
    
    # Ollama API HTTPS Proxy (port 11435)
    server {
        listen 11435 ssl http2;
        server_name _;
        
        ssl_certificate /etc/nginx/ssl/nginx.crt;
        ssl_certificate_key /etc/nginx/ssl/nginx.key;
        
        location / {
            proxy_pass http://127.0.0.1:11434;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Forwarded-Host $host;
            proxy_set_header X-Forwarded-Port $server_port;
        }
    }
    
}
EOF

    # Test Nginx configuration
    log_info "Testing Nginx configuration..."
    sudo nginx -t
    
    if [ $? -eq 0 ]; then
        log_success "Nginx configuration is valid"
        
        # Enable and start Nginx
        sudo systemctl enable nginx
        sudo systemctl start nginx
        
        # Verify Nginx is running
        if systemctl is-active --quiet nginx; then
            log_success "Nginx configured and started successfully"
            log_info "HTTPS endpoints:"
            log_info "  - OpenWebUI: https://openwebui.local"
            log_info "  - Ollama API: https://ollama.local"
            log_info "  - System Monitor: https://monitor.local"
        else
            log_error "Failed to start Nginx"
            exit 1
        fi
    else
        log_error "Nginx configuration test failed"
        exit 1
    fi
}

# Step 8: Install and Configure OpenWebUI
install_openwebui() {
    log_info "Installing and configuring OpenWebUI..."
    
    # Ensure uv is in PATH
    export PATH="$HOME/.local/bin:$PATH"
    
    # Set data directory
    export DATA_DIR="$HOME/.open-webui"
    
    # Create data directory if it doesn't exist
    mkdir -p "$DATA_DIR"
    
    log_info "Creating OpenWebUI systemd service..."
    
    # Create systemd service for OpenWebUI
    sudo tee /etc/systemd/system/openwebui.service > /dev/null << EOF
[Unit]
Description=OpenWebUI Server
After=network.target ollama.service

[Service]
Type=simple
User=$USER
Group=$USER
WorkingDirectory=$HOME
Environment=HOME=$HOME
Environment=DATA_DIR=$HOME/.open-webui
Environment=PATH=$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin
ExecStart=$HOME/.local/bin/uvx --python 3.11 open-webui@latest serve
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd and enable service
    sudo systemctl daemon-reload
    sudo systemctl enable openwebui
    sudo systemctl start openwebui
    
    # Get server IP address for display
    SERVER_IP=$(ip route get 1.1.1.1 | awk '{print $7; exit}' 2>/dev/null || hostname -I | awk '{print $1}' 2>/dev/null || echo "127.0.0.1")
    
    log_success "OpenWebUI configured and started"
    log_info "OpenWebUI will be available at:"
    log_info "  - HTTPS: https://${SERVER_IP}:8443 (self-signed cert)"
}

# Step 9: Configure UFW Firewall
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
    
    # Allow HTTP and HTTPS traffic
    log_info "Allowing HTTP traffic on port 80..."
    sudo ufw allow 80/tcp
    log_info "Allowing HTTPS traffic on port 443..."
    sudo ufw allow 443/tcp
    log_info "Allowing HTTPS traffic on port 8443..."
    sudo ufw allow 8443/tcp
    log_info "Allowing HTTPS traffic on port 11435..."
    sudo ufw allow 11435/tcp
    
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


# Main execution
main() {
    log_info "Starting Arch Linux OpenWebUI + Ollama setup..."
    log_info "This script will install and configure OpenWebUI and Ollama on your system"
    
    # Execute steps in order
    system_update
    install_gpu_drivers
    ensure_essential_tools
    install_uv
    install_ollama
    install_nginx
    configure_nginx
    configure_firewall
    install_openwebui
    
    # Get server IP address
    SERVER_IP=$(ip route get 1.1.1.1 | awk '{print $7; exit}' 2>/dev/null || hostname -I | awk '{print $1}' 2>/dev/null || echo "127.0.0.1")
    
    # Get GPU information for display
    if command_exists lspci; then
        GPU_INFO=$(lspci 2>/dev/null | grep -E 'VGA|3D|Display' 2>/dev/null | head -1 || echo "")
        if [ -n "$GPU_INFO" ]; then
            GPU_DISPLAY="🎮 GPU: $GPU_INFO"
        else
            GPU_DISPLAY="💻 Processing: CPU-only (no GPU detected)"
        fi
    else
        GPU_DISPLAY="💻 Processing: CPU-only (GPU detection unavailable)"
    fi
    
    log_success "Setup completed successfully!"
    log_info ""
    log_info "🚀 AI-PREMISE SERVER IS READY! 🚀"
    log_info ""
    log_info "═══════════════════════════════════════════════════════════════"
    log_info "🌐 ACCESS YOUR AI SERVICES:"
    log_info "═══════════════════════════════════════════════════════════════"
    log_info ""
    log_info "🤖 OpenWebUI (AI Chat Interface):"
    log_info "   🔗 https://${SERVER_IP}:8443"
    log_info "   📝 Self-signed certificate - accept browser warning"
    log_info ""
    log_info "⚡ Ollama API (AI Model Server):"
    log_info "   🔗 https://${SERVER_IP}:11435"
    log_info "   🔧 API endpoint for AI model management"
    log_info ""
    log_info "═══════════════════════════════════════════════════════════════"
    log_info "🔒 SECURITY & NETWORK:"
    log_info "═══════════════════════════════════════════════════════════════"
    log_info "🛡️  UFW Firewall: ACTIVE"
    log_info "   ✅ SSH (port 22): ALLOWED"
    log_info "   ✅ HTTP (port 80): ALLOWED" 
    log_info "   ✅ HTTPS (ports 443, 8443, 11435): ALLOWED"
    log_info "   ❌ All other incoming traffic: BLOCKED"
    log_info ""
    log_info "🔐 SSL Certificates: 10-year self-signed certificates"
    log_info "🔄 Auto-start: All services start automatically on reboot"
    log_info ""
    log_info "═══════════════════════════════════════════════════════════════"
    log_info "📍 SERVER DETAILS:"
    log_info "═══════════════════════════════════════════════════════════════"
    log_info "🌍 Server IP Address: ${SERVER_IP}"
    log_info "${GPU_DISPLAY}"
    log_info "🐧 Arch Linux with Ollama + OpenWebUI"
    log_info ""
    log_info "🎉 Enjoy your AI-Premise server!"
    log_info "═══════════════════════════════════════════════════════════════"
}

# Run main function
main "$@"
