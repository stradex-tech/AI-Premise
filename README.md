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
   - OpenWebUI: http://localhost:8080
   - Ollama API: http://127.0.0.1:11434

### Script Features

- **Safe & Idempotent**: Can be run multiple times safely
- **Comprehensive Logging**: Color-coded status messages
- **Error Handling**: Graceful failure handling with `set -Eeuo pipefail`
- **Service Verification**: Checks if services are running properly
- **Clean Structure**: Modular functions for maintainability

### Requirements

- Arch Linux system
- Internet connection
- sudo privileges

### Testing on Bare Metal

This script is designed for bare metal installation to ensure full GPU access and optimal performance. To test on your hardware:

```bash
curl -O https://raw.githubusercontent.com/stradex-tech/AI-Premise/main/arch-openwebui-setup.sh
chmod +x arch-openwebui-setup.sh
./arch-openwebui-setup.sh
```

**Note**: Bare metal installation is recommended over VM testing to ensure:
- Direct GPU access without passthrough complications
- Full hardware performance
- Native driver compatibility
- Optimal AI model acceleration

## Roadmap

### Phase 1: Core Script Development ✅
- [x] Create comprehensive setup script
- [x] Implement GPU detection and driver installation
- [x] Add Ollama and OpenWebUI installation
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
