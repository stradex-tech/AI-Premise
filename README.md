# AI-Premise

An appliance server OS that only runs Ollama and OpenWebUI and other common utilities.

## Project Vision

The ultimate goal of AI-Premise is to create a custom Arch Linux ISO that automatically runs this setup script post-install, creating a dedicated appliance server optimized for AI workloads. This will be a minimal, purpose-built operating system that boots directly into a configured Ollama + OpenWebUI environment.

**Current Phase**: Developing and testing the core setup script to ensure it works reliably on bare metal hardware before creating the custom ISO.

## Arch Linux Setup Script

This repository contains a comprehensive post-install script for Arch Linux that automatically sets up OpenWebUI and Ollama server. This script serves as the foundation for the future appliance OS.

### Features

* **Automatic System Update**: Full system update with pacman lock file handling
* **GPU Detection & Driver Installation**: Automatically detects and installs drivers for:  
   * NVIDIA GPUs (`nvidia`, `nvidia-utils`, `cuda`)  
   * AMD GPUs (`rocm-hip-runtime`, `rocm-opencl-runtime`)  
   * Intel GPUs (`intel-compute-runtime`, `level-zero-loader`)  
   * **CPU-Only Mode**: Gracefully handles systems without GPUs
* **Dependency Management**: Ensures curl and OpenSSH are installed
* **Astral uv Installation**: Modern Python package manager
* **Ollama Setup**: Official installation with systemd service
* **OpenWebUI Installation**: Using uvx with Python 3.11 and systemd service
* **Nginx HTTPS Proxy**: Automatic HTTPS with 10-year self-signed certificates
* **UFW Firewall**: Secure firewall configuration (HTTP, HTTPS, and SSH)
* **Enhanced Success Display**: Beautiful, informative completion message with GPU detection

### Usage

**Option 1: Download and run directly (Recommended)**

```bash
curl -O https://raw.githubusercontent.com/stradex-tech/AI-Premise/main/ai-premise-setup.sh
chmod +x ai-premise-setup.sh
./ai-premise-setup.sh
```

**Option 2: One-liner (download and run)**

```bash
curl -sSL https://raw.githubusercontent.com/stradex-tech/AI-Premise/main/ai-premise-setup.sh | bash
```

**Option 3: Clone repository**

```bash
git clone https://github.com/stradex-tech/AI-Premise.git
cd AI-Premise
chmod +x ai-premise-setup.sh
./ai-premise-setup.sh
```

1. Access the services using your server's IP address:  
   * **OpenWebUI**: `https://YOUR_SERVER_IP:8443` (AI chat interface)  
   * **Ollama API**: `https://YOUR_SERVER_IP:11435` (AI model API)  
The script will display the exact URLs and your server's IP address upon completion.

### Script Features

* **Safe & Idempotent**: Can be run multiple times safely
* **Comprehensive Logging**: Color-coded status messages with progress indicators
* **Error Handling**: Graceful failure handling with `set -Eeuo pipefail`
* **Service Verification**: Checks if services are running properly
* **Clean Structure**: Modular functions for maintainability
* **HTTPS Security**: Automatic SSL certificates and secure access
* **Firewall Protection**: UFW configured for maximum security
* **GPU Detection**: Shows actual GPU model or CPU-only status in completion message
* **Beautiful Completion Display**: Large, informative success message with all details

### Requirements

* Arch Linux system
* Internet connection
* sudo privileges

### Security Features

* **HTTPS Only**: All web services accessible only through secure HTTPS
* **10-Year Self-Signed Certificates**: Long-lasting SSL certificates for convenience
* **UFW Firewall**: Only ports 80 (HTTP), 443 (HTTPS), 8443 (OpenWebUI), 11435 (Ollama), and 22 (SSH) are open
* **IP-Based Access**: Direct IP access instead of DNS dependencies
* **Backend Protection**: Direct access to backend services blocked
* **SSH Access**: Secure remote administration enabled

## Roadmap

### Phase 1: Core Script Development ✅

* Create comprehensive setup script
* Implement GPU detection and driver installation
* Add Ollama and OpenWebUI installation
* Add Nginx HTTPS proxy with 10-year self-signed certificates
* Configure UFW firewall for security
* Add OpenSSH for remote administration
* Test on bare metal hardware
* Enhanced success message with GPU detection
* CPU-only mode support for systems without GPUs

### Phase 2: Custom Arch ISO (Future)

* Create custom Arch Linux ISO with minimal packages
* Integrate setup script into post-install automation
* Add boot-time configuration options
* Create automated installer for appliance deployment

### Phase 3: Appliance Features (Future)

* Web-based management interface
* Automated model management
* System monitoring and health checks
* Backup and recovery tools

## Resources & Acknowledgments

### Core Technologies
- **[Arch Linux](https://archlinux.org/)** - The base Linux distribution
- **[Ollama](https://ollama.ai/)** - Local AI model runner and API
- **[OpenWebUI](https://github.com/open-webui/open-webui)** - Web interface for AI models
- **[Astral uv](https://github.com/astral-sh/uv)** - Modern Python package manager

### Web & Networking
- **[Nginx](https://nginx.org/)** - Web server and reverse proxy
- **[UFW](https://launchpad.net/ufw)** - Uncomplicated Firewall
- **[OpenSSH](https://www.openssh.com/)** - Secure Shell implementation

### Hardware Support
- **[NVIDIA CUDA](https://developer.nvidia.com/cuda-toolkit)** - GPU computing platform
- **[ROCm](https://rocm.docs.amd.com/)** - AMD GPU computing platform
- **[Intel Compute Runtime](https://github.com/intel/compute-runtime)** - Intel GPU support

### Community & Inspiration
- **[Arch Wiki](https://wiki.archlinux.org/)** - Comprehensive Arch Linux documentation
- **[Arch Linux Forums](https://bbs.archlinux.org/)** - Community support and discussions
- **[Open Source Community](https://opensource.org/)** - All contributors to the projects above

### License Acknowledgments
This project is licensed under **GPL-3.0** and builds upon the work of many open source projects. We are grateful to all the developers and maintainers who have contributed to the tools and technologies that make this project possible.

## License

GPL-3.0 license

---

**Thank you to the entire open source community for making this project possible!** 🙏