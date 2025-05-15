# Technical Context: C++ Development Environment Setup

## Technologies Used

### Core Technologies

1. **Distrobox**
   - Version: 1.8.0+ recommended
   - Purpose: Creates and manages containerized development environments
   - Key features: Integration with host system, graphical application support, Docker compatibility

2. **Docker**
   - Purpose: Containerization platform for building and running applications
   - Used for: Creating deployment containers for C++ applications, running Docker-in-Docker
   - Integration: Host Docker socket mounted into Distrobox container

3. **Ubuntu 22.04**
   - Purpose: Base operating system for the development container
   - Provides: Stable environment with good tool support
   - Compatibility: Works well with modern C++ development tools

### Development Tools

1. **GCC/G++**
   - Version: Latest available in Ubuntu 22.04 repositories
   - Purpose: C++ compiler toolchain
   - Features: C++23 support, modern language features

2. **CMake**
   - Version: 3.28.3 (installed from GitHub release)
   - Purpose: Build system generator
   - Features: Modern configuration, cross-platform support, Conan integration

3. **Conan**
   - Version: Latest (installed via pip3)
   - Purpose: C++ package manager
   - Features: Dependency resolution, version management, CMake integration

4. **Visual Studio Code**
   - Purpose: Integrated development environment
   - Extensions: C/C++, CMake Tools, Docker, Conan
   - Configuration: Pre-configured for C++ development with debugging support

### Shell Scripting

1. **Bash**
   - Purpose: Scripting language for automation
   - Used for: All automation scripts in the project
   - Features: Process management, error handling, environment configuration

## Development Setup

### Host System Requirements

1. **Operating System**:
   - Linux-based system (Ubuntu, Fedora, etc.)
   - Kernel with container support
   - X11 or Wayland display server for GUI applications

2. **Prerequisites**:
   - Docker (installed by the script if missing)
   - Distrobox (installed by the script if missing)
   - Bash shell

### Container Configuration

1. **Resource Allocation**:
   - Uses host system resources
   - No specific resource limits imposed

2. **Filesystem Mounts**:
   - Host home directories mounted into container
   - Docker socket mounted for Docker-in-Docker support
   - Project directories accessible from both host and container

3. **Network Configuration**:
   - Uses host network namespace
   - No network isolation

### Development Workflow

1. **Environment Setup**:
   ```
   ./build_cpp_dev_env.sh [options]
   ```

2. **Container Access**:
   ```
   distrobox enter cpp_dev_env
   ```

3. **Project Building**:
   ```
   cd ~/Desktop/projects/cpp/cpp_demo
   ./build.sh
   ```

4. **Containerization**:
   ```
   ./build.dist.sh
   ```

5. **Project Creation**:
   ```
   ./create_cpp_project_from_template.sh --template TEMPLATE_FOLDER --name NEW_PROJECT_NAME
   ```

## Technical Constraints

1. **Host System Compatibility**:
   - Requires a Linux-based host system
   - Requires Docker support in the kernel
   - Requires sufficient disk space for container images

2. **Container Limitations**:
   - Distrobox containers share the host kernel
   - Limited isolation compared to full virtual machines
   - Some system-level operations may require host access

3. **Docker-in-Docker Considerations**:
   - Uses the host's Docker daemon
   - Container images are stored on the host system
   - Requires proper permissions for the Docker socket

4. **VSCode Integration**:
   - VSCode runs inside the container
   - Extensions are installed within the container
   - Some extensions may have specific requirements

## Dependencies

### External Dependencies

1. **Host System Dependencies**:
   - Docker Engine
   - Distrobox
   - Bash shell

2. **Container Dependencies**:
   - Ubuntu 22.04 packages
   - Development tools (build-essential, git, etc.)
   - Docker CLI tools

### Internal Dependencies

1. **Script Dependencies**:
   - build.sh depends on CMake and Conan
   - build.dist.sh depends on build.sh and Docker
   - helper.sh provides utilities used by other scripts

2. **Configuration Dependencies**:
   - .dist_build defines container configuration
   - .env_dist defines environment variables
   - CMakeLists.txt defines build configuration
   - conanfile.txt defines package dependencies

## Tool Usage Patterns

### Distrobox Usage

```bash
# Create container
distrobox create --name NAME --image IMAGE

# Enter container
distrobox enter NAME

# Stop container
distrobox stop NAME

# Remove container
distrobox rm NAME
```

### Docker Usage

```bash
# Build image
docker build -t NAME -f DOCKERFILE .

# Tag image
docker tag NAME NAME:TAG

# Run container
docker run --rm NAME

# View container info
docker inspect NAME
```

### CMake Usage

```bash
# Configure project
cmake .. -DCMAKE_TOOLCHAIN_FILE=conan_toolchain.cmake -DCMAKE_BUILD_TYPE=Debug

# Build project
cmake --build .

# Install project
cmake --install .
```

### Conan Usage

```bash
# Install dependencies
conan install .. --output-folder=. --build=missing

# Create profile
conan profile detect
```

### VSCode Integration

The environment includes pre-configured VSCode settings:

1. **tasks.json**: Defines build tasks
2. **launch.json**: Configures debugging
3. **settings.json**: Sets editor preferences
4. **extensions.json**: Recommends extensions
5. **argv.json**: Configures VSCode behavior, including password-store settings

These configurations ensure a consistent development experience across different installations.

#### VSCode Password Store Configuration

The environment configures VSCode to use the "basic" password-store:

```json
{
  "password-store": "basic"
}
```

This configuration is added to `~/.vscode/argv.json` during container setup to prevent credential prompts and ensure a smoother experience when working with extensions that might require authentication.

#### VSCode Git Configuration

The environment disables Git integration in VSCode to prevent credential issues and unwanted Git operations:

```json
{
  "git.enabled": false,
  "git.useCredentialStore": false,
  "git.autofetch": false,
  "git.confirmSync": false
}
```

This configuration is added to `~/.config/Code/User/settings.json` during container setup to:
- Disable Git integration in VSCode
- Prevent the use of credential store for Git
- Disable automatic fetching of Git repositories
- Disable confirmation prompts for Git sync operations
