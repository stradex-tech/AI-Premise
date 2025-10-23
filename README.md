# AI-Premise

An appliance server OS that only runs Ollama and OpenWebUI and other common utilities.

## Project Vision

The ultimate goal of AI-Premise is to create a custom Arch Linux ISO that automatically runs this setup script post-install, creating a dedicated appliance server optimized for AI workloads. This will be a minimal, purpose-built operating system that boots directly into a configured Ollama + OpenWebUI environment.

**Current Phase**: Developing and testing the core setup script to ensure it works reliably on bare metal hardware before creating the custom ISO.

## Arch Linux Setup Script

This repository contains a comprehensive post-install script for Arch Linux that automatically sets up OpenWebUI and Ollama server. This script serves as the foundation for the future appliance OS.

### Features

- **Automatic System Update**: Full system update with pacman lock file handling
- **GPU Detection & Driver Installation**: Automatically detects and installs drivers for:
  - NVIDIA GPUs (`nvidia`, `nvidia-utils`, `cuda`)
  - AMD GPUs (`rocm-hip-runtime`, `rocm-opencl-runtime`)
  - Intel GPUs (`intel-compute-runtime`, `level-zero-loader`)
- **Dependency Management**: Ensures curl is installed
- **Astral uv Installation**: Modern Python package manager
- **Ollama Setup**: Official installation with systemd service
- **OpenWebUI Installation**: Using uvx with Python 3.11
- **Caddy HTTPS Proxy**: Automatic HTTPS with self-signed certificates
- **UFW Firewall**: Secure firewall configuration (HTTPS and SSH only)
- **Glances Monitoring**: Real-time system monitoring with temperature tracking

### Usage

1. Clone this repository:
   ```bash
   git clone https://github.com/stradex-tech/AI-Premise.git
   cd AI-Premise
   ```

2. Make the script executable and run it:
   ```bash
   chmod +x arch-openwebui-setup.sh
   ./arch-openwebui-setup.sh
   ```

3. Access the services:
   - **OpenWebUI**: https://openwebui.local (AI chat interface)
   - **Ollama API**: https://ollama.local (AI model API)
   - **System Monitor**: https://monitor.local (Real-time monitoring)
   - **Main Dashboard**: https://ai-premise.local (Redirects to OpenWebUI)

### Script Features

- **Safe & Idempotent**: Can be run multiple times safely
- **Comprehensive Logging**: Color-coded status messages
- **Error Handling**: Graceful failure handling with `set -Eeuo pipefail`
- **Service Verification**: Checks if services are running properly
- **Clean Structure**: Modular functions for maintainability
- **HTTPS Security**: Automatic SSL certificates and secure access
- **Firewall Protection**: UFW configured for maximum security
- **System Monitoring**: Real-time performance and temperature tracking

### Requirements

- Arch Linux system
- Internet connection
- sudo privileges

### Security Features

- **HTTPS Only**: All web services accessible only through secure HTTPS
- **Self-Signed Certificates**: Automatic SSL certificate generation
- **UFW Firewall**: Only ports 443 (HTTPS) and 22 (SSH) are open
- **Local Domains**: Clean `.local` domains instead of IP addresses
- **Backend Protection**: Direct access to backend services blocked

### System Monitoring

- **Real-Time Monitoring**: CPU, Memory, Disk, GPU usage and temperatures
- **Temperature Tracking**: CPU, GPU, and system sensor monitoring
- **Clean Interface**: Minimal, focused monitoring dashboard
- **HTTPS Access**: Secure monitoring via `https://monitor.local`

## Roadmap

### Phase 1: Core Script Development ✅
- [x] Create comprehensive setup script
- [x] Implement GPU detection and driver installation
- [x] Add Ollama and OpenWebUI installation
- [x] Add Caddy HTTPS proxy with self-signed certificates
- [x] Configure UFW firewall for security
- [x] Add Glances system monitoring
- [x] Test on bare metal hardware

### Phase 2: Custom Arch ISO (Future)
- [ ] Create custom Arch Linux ISO with minimal packages
- [ ] Integrate setup script into post-install automation
- [ ] Add boot-time configuration options
- [ ] Create automated installer for appliance deployment

### Phase 3: Appliance Features (Future)
- [ ] Web-based management interface
- [ ] Automated model management
- [ ] System monitoring and health checks
- [ ] Backup and recovery tools

## License

GPL-3.0 license
