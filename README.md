# AI-Premise

An appliance server OS that only runs Ollama and OpenWebUI and other common utilities.

## Arch Linux Setup Script

This repository contains a comprehensive post-install script for Arch Linux that automatically sets up OpenWebUI and Ollama server.

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

### Testing on VM

To test this script on a separate VM, you can download it directly:

```bash
curl -O https://raw.githubusercontent.com/stradex-tech/AI-Premise/main/arch-openwebui-setup.sh
chmod +x arch-openwebui-setup.sh
./arch-openwebui-setup.sh
```

## License

GPL-3.0 license
