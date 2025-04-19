#!/bin/bash

# build_cpp_dev_env.sh
# Script to set up a C++ development environment using distrobox

# Set error handling
set -e

echo "Starting build_cpp_dev_env.sh at $(date)"

USER_NAME="$(whoami)"
export DOCKER_GID_HOST=$(getent group docker | cut -d: -f3)

# Default container name
CONTAINER_NAME="cpp_dev_env"

# Function to clean up if something goes wrong
cleanup() {
    echo "Cleaning up distrobox environment..."
    distrobox stop $CONTAINER_NAME 2>/dev/null || true
    distrobox rm $CONTAINER_NAME 2>/dev/null || true
    echo "Cleanup completed."
}

# Function to clean log files
clean_logs() {

    echo "Cleaning log files..."

    # Detect the current log file in uso, si es que está definido
    CURRENT_LOG="${LOG_FILE:-}"

    for file in build_cpp_dev_env-*.log; do
        if [[ "$file" != "$CURRENT_LOG" ]]; then
            rm -f "$file"
        else
            echo "Skipping current log file: $file"
        fi
    done

    echo "Log files cleaned."

    #echo "Cleaning log files..."
    #rm -f build_cpp_dev_env-*.log
    #echo "Log files cleaned."
}

clean_container_home() {
    local target_dir="$1"

    echo "Checking if target directory is safe to delete: $target_dir"

    if [ -z "$target_dir" ] ||
       [ "$target_dir" = "/" ] ||
       [ "$target_dir" = "/home" ] ||
       [ "$target_dir" = "$HOME" ] || 
       [[ "$target_dir" != *"/distrobox/"* ]] ||
       [ ! -d "$target_dir" ]; then
        echo "Unsafe or invalid directory: $target_dir"
        echo "Folder delete avoided"
        return 0
    fi

    echo "Deleting directory: $target_dir"
    rm -rf "$target_dir"
    echo "Directory deleted successfully."
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTION]..."
    echo "Options:"
    echo "  --cleanup                  Clean up distrobox environment"
    echo "  --clean-logs               Remove all log files"
    echo "  --clean-container-home     Remove all files from container shared with host"
    echo "  --container-name NAME      Set the container name (default: $CONTAINER_NAME)"
    echo "  --remove-old-container     Force remove the old container if exits lokking by the name $CONTAINER_NAME"
    echo "  (no option)                Set up C++ development environment with Docker support"
    echo ""
    echo "This script sets up a C++ development environment using distrobox with Docker"
    echo "support from the official Docker repository, allowing you to build and run"
    echo "Docker containers inside the distrobox container."
}

check_and_install_docker_in_host() {
    echo "Checking if Docker is installed on the host..."

    if command -v docker &> /dev/null; then
        echo "Docker is already installed."
        return
    fi

    echo "Docker not found. Attempting to install..."

    if command -v apt &> /dev/null; then
        echo "Detected apt-based system. Installing Docker..."

        sudo apt update
        sudo apt install -y ca-certificates curl gnupg lsb-release

        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        sudo chmod a+r /etc/apt/keyrings/docker.gpg

        # Detect base distro codename correctly (fix for Linux Mint)
        UBUNTU_CODENAME="$(. /etc/os-release && echo "$UBUNTU_CODENAME")"
        if [ -z "$UBUNTU_CODENAME" ]; then
            # fallback in case UBUNTU_CODENAME is not set
            UBUNTU_CODENAME="$(lsb_release -cs)"
            if [[ "$UBUNTU_CODENAME" == "xia" ]]; then
                UBUNTU_CODENAME="noble"
            fi
        fi

        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
          $UBUNTU_CODENAME stable" | \
          sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

        sudo apt update
        sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

        # Add current user to the docker group
        sudo usermod -aG docker "$USER"
        echo "Docker installed. You may need to log out and log back in or run: exec su - $USER"

    elif command -v dnf &> /dev/null; then
        echo "Detected dnf-based system. Installing Docker..."

        sudo dnf -y install dnf-plugins-core
        sudo dnf config-manager \
            --add-repo \
            https://download.docker.com/linux/fedora/docker-ce.repo

        sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

        # Add current user to the docker group
        sudo usermod -aG docker "$USER"
        echo "Docker installed. You may need to log out and log back in or run: exec su - $USER"

    else
        echo "Error: Could not determine package manager. Please install Docker manually."
        exit 1
    fi
}

check_and_install_distrobox_in_host() {
    echo "Checking if Distrobox is installed on the host..."

    if command -v distrobox &>/dev/null; then
        echo "Distrobox is already installed."
    else 
        echo "Distrobox not found. Attempting to install..."
        
        # Check package manager
        if command -v apt &> /dev/null; then
            echo "Detected apt package manager. Installing distrobox..."
            sudo apt update
            sudo apt install -y distrobox
        elif command -v dnf &> /dev/null; then
            echo "Detected dnf package manager. Installing distrobox..."
            sudo dnf install -y distrobox
        elif command -v rpm &> /dev/null; then
            echo "Detected rpm-based system. Installing distrobox..."
            sudo rpm -i https://github.com/89luca89/distrobox/releases/latest/download/distrobox.rpm
        else
            echo "Error: Could not determine package manager. Please install distrobox manually."
            exit 1
        fi
    fi
}

# Process command line options
DO_CLEANUP=false
DO_CLEAN_LOGS=false
DO_REMOVE_OLD_CONTAINER=false
DO_CLEAN_CONTAINER_HOME=false
VALID_ARGS=false

# Process all arguments
while [ $# -gt 0 ]; do
    case "$1" in
        --cleanup)
            DO_CLEANUP=true
            VALID_ARGS=true
            shift
            ;;
        --clean-logs)
            DO_CLEAN_LOGS=true
            #VALID_ARGS=true
            shift
            ;;
        --remove-old-container)
            DO_REMOVE_OLD_CONTAINER=true
            shift
            ;;
        --clean-container-home)
            DO_CLEAN_CONTAINER_HOME=true
            shift
            ;;
        --container-name)
            if [ $# -gt 1 ]; then
                CONTAINER_NAME="$2"
                echo "Using container name: $CONTAINER_NAME"
                shift 2
            else
                echo "Error: --container-name requires a value"
                show_usage
                exit 1
            fi
            ;;
        *)
            echo "Error: Unknown parameter '$1'"
            show_usage
            exit 1
            ;;
    esac
done

# Execute requested actions
if [ "$DO_CLEANUP" = true ] || [ "$DO_REMOVE_OLD_CONTAINER" = true ]; then
    cleanup
fi

if [ "$DO_CLEAN_LOGS" = true ]; then
    clean_logs
fi

# Exit if any action was performed
if [ "$VALID_ARGS" = true ]; then
    exit 0
fi

echo "Setting up C++ development environment with distrobox..."

check_and_install_docker_in_host

check_and_install_distrobox_in_host

IMAGE_NAME="ubuntu:22.04"
CONTAINER_HOME="/home/${USER_NAME}/Desktop/distrobox/containers/home/${CONTAINER_NAME}"

# Execute requested actions
if [ "$DO_CLEAN_CONTAINER_HOME" = true ]; then

    clean_container_home "$CONTAINER_HOME"

fi

echo "Current user running this script: $USER_NAME"

HOST_FOLDERS=(
  "Desktop"
  "Downloads"
  "Documents"
  "Music"
  "Pictures"
  "Videos"
  ".ssh"
)

ADDITIONAL_FLAGS=()

for folder in "${HOST_FOLDERS[@]}"; do
  HOST_PATH="$HOME/$folder"
  #CONTAINER_PATH="/home/$USER_NAME/$folder"
  CONTAINER_PATH="$CONTAINER_HOME/$folder"

  if [ -e "$HOST_PATH" ]; then
    echo "Mounting $folder"
    ADDITIONAL_FLAGS+=( "--additional-flags" "--volume $HOST_PATH:$CONTAINER_PATH" )
  else
    echo "$folder does not exist, skipping"
  fi
done

echo "In the host enviroment DOCKER_GID_HOST: $DOCKER_GID_HOST"

export SOCKET_MOUNT_PATH="/run/host_docker.sock"

DOCKER_SOCK="/var/run/docker.sock"

if [ -S $DOCKER_SOCK ]; then

  CURRENT_PERMS=$(stat -c "%a" "$DOCKER_SOCK")
  if [ "$CURRENT_PERMS" != "666" ]; then
    echo "Setting host Docker socket to 0666..."
    sudo chmod 666 "$DOCKER_SOCK"
  else
    echo "Docker socket already has 0666 permissions, skipping chmod."
  fi

  echo "Mapping Docker socket from host to $SOCKET_MOUNT_PATH..."
  ADDITIONAL_FLAGS+=( "--additional-flags" "--volume /var/run/docker.sock:$SOCKET_MOUNT_PATH" )
  ADDITIONAL_FLAGS+=( "--additional-flags" "--env DOCKER_GID_HOST=$DOCKER_GID_HOST" )
  ADDITIONAL_FLAGS+=( "--additional-flags" "--env DOCKER_SOCKET=$SOCKET_MOUNT_PATH" )
else
  echo "Docker socket not found at $DOCKER_SOCK"
fi

# Create the container with each --additional-flags passed separately
echo "Creating Ubuntu 22.04 container named $CONTAINER_NAME..."
distrobox create \
  --name "$CONTAINER_NAME" \
  --image "$IMAGE_NAME" \
  --home "$CONTAINER_HOME" \
  "${ADDITIONAL_FLAGS[@]}" \
  --yes

#--home "/home/$USER_NAME" \

# Prepare to set up the development environment inside the container
echo "Preparing to set up development environment inside container..."

# Execute the setup commands directly inside the container
echo "Setting up development environment inside container..."
distrobox enter $CONTAINER_NAME -- bash << 'EOF'
# Set non-interactive frontend to avoid any UI prompts
export DEBIAN_FRONTEND=noninteractive

if [ -z "$DOCKER_GID_HOST" ]; then
    echo "Warning: DOCKER_GID_HOST is empty!"
else
    echo "In the container environment DOCKER_GID_HOST: $DOCKER_GID_HOST"
fi

echo "Inside container environment, DOCKER_GID_HOST: $DOCKER_GID_HOST"

# Ensure DOCKER_SOCKET has a default value in case --env didn't work
export DOCKER_SOCKET="${DOCKER_SOCKET:-/run/host_docker.sock}"

# Check if the docker group exists
if getent group docker >/dev/null; then
    DOCKER_GID_CONTAINER=$(getent group docker | cut -d: -f3)
    echo "Group 'docker' exists with GID $DOCKER_GID_CONTAINER"

    if [ "$DOCKER_GID_CONTAINER" != "$DOCKER_GID_HOST" ]; then
        echo "GID mismatch detected, deleting and recreating 'docker' group with GID $DOCKER_GID_HOST"
        sudo groupdel docker
        sudo groupadd -g "$DOCKER_GID_HOST" docker
    else
        echo "Group 'docker' already has the correct GID."
    fi
else
    echo "Group 'docker' does not exist, creating it with GID $DOCKER_GID_HOST"
    sudo groupadd -g "$DOCKER_GID_HOST" docker
fi

# Add current user to the docker group
sudo usermod -aG docker "$USER"

# Update package lists
echo "Updating package lists..."
sudo apt update

# Install basic development tools
echo "Installing build-essential, git, mc, htop..."
sudo apt install -y build-essential gdb git mc htop python3-pip curl gnupg lsb-release ca-certificates

# Install Docker from the official Docker repository
echo "Installing Docker from the official Docker repository..."
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add current user to the docker group
sudo usermod -aG docker $USER

echo "Checking Docker socket at: $DOCKER_SOCKET"
# Check Docker socket permissions inside the container
if [ -n "$DOCKER_SOCKET" ] && [ -S "$DOCKER_SOCKET" ]; then
    echo "Docker socket is mounted at: $DOCKER_SOCKET"
    echo "Socket info:"
    ls -l "$DOCKER_SOCKET"

    echo "Testing Docker access..."
    if docker ps &>/dev/null; then
        echo "Docker is accessible from inside the container."
    else
        echo "Docker is NOT accessible from inside the container. You may have permission issues."
        echo "Suggestion: Ensure the socket has permissions (666) and your user is in the 'docker' group."

        echo "Attempting to set permissions on Docker socket: $DOCKER_SOCKET"
        sudo chmod 666 "$DOCKER_SOCKET" || echo "Warning: Could not chmod Docker socket"
    fi
else
    echo "Docker socket not found at $DOCKER_SOCKET"
fi

# Install Conan from pip3
echo "Installing Conan package manager..."
sudo pip3 install conan 

# Generate Conan profile
echo "Generating Conan profile..."
conan profile detect

# Install latest CMake
echo "Installing latest CMake..."
CMAKE_VERSION="3.28.3"
wget https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-x86_64.sh -O /tmp/cmake-install.sh
chmod +x /tmp/cmake-install.sh
sudo /tmp/cmake-install.sh --skip-license --prefix=/usr/local

# Add /usr/local/bin to PATH
echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc
echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.profile
source ~/.bashrc
echo "Added /usr/local/bin to PATH"

# Install VSCode
echo "Installing Visual Studio Code..."
sudo apt install -y software-properties-common apt-transport-https wget
wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | sudo apt-key add -
# Add -y flag to add-apt-repository to avoid interactive prompt
sudo add-apt-repository -y "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main"
echo "code code/add-microsoft-repo boolean true" | sudo debconf-set-selections
sudo apt update
sudo apt install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" code

# Export VSCode to the host system
echo "Exporting VSCode to the host system..."
#distrobox-export --app code

#Force to use the code app inside of container
echo 'alias code="/usr/bin/code"' >> ~/.bashrc
source ~/.bashrc

# Limpieza opcional del directorio anterior si existe
TARGET_DIR=~/Desktop/projects/cpp/cpp_demo
if [ -d "$TARGET_DIR" ]; then
    echo "Cleaning previous project directory: $TARGET_DIR"
    rm -rf "$TARGET_DIR"
fi

# Create C++ demo project
echo "Creating C++ demo project..."
mkdir -p ~/Desktop/projects/cpp/cpp_demo
EOF

# Create project files directly inside the container
echo "Creating project files inside container..."
distrobox enter $CONTAINER_NAME -- bash << 'EOF'
cd ~/Desktop/projects/cpp/cpp_demo

# Create main.cpp
echo "Creating main.cpp..."
cat > main.cpp << 'EOF_CPP'
#include <iostream>
#include <string>
#include <vector>

int main(int argc, char* argv[]) {
    std::cout << "Hello from C++ Demo!" << std::endl;
    
    std::vector<std::string> args(argv, argv + argc);
    
    if (args.size() > 1) {
        std::cout << "Arguments:" << std::endl;
        for (size_t i = 1; i < args.size(); ++i) {
            std::cout << "  " << i << ": " << args[i] << std::endl;
        }
    }
    
    return 0;
}
EOF_CPP

# Create CMakeLists.txt
echo "Creating CMakeLists.txt..."
cat > CMakeLists.txt << 'EOF_CMAKE'
cmake_minimum_required(VERSION 3.15)
project(cpp_demo VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Load binary name from .dist_build
file(STRINGS ".dist_build" DIST_BUILD_CONTENT)
foreach(LINE ${DIST_BUILD_CONTENT})
    if(LINE MATCHES "^Container_Bin_Name=\"([^\"]+)\"$")
        set(APP_BIN_NAME ${CMAKE_MATCH_1})
    endif()
endforeach()

if(NOT DEFINED APP_BIN_NAME)
    set(APP_BIN_NAME "cpp_demo")
    message(WARNING "Container_Bin_Name not found in .dist_build, using default: ${APP_BIN_NAME}")
endif()

message(STATUS "Building executable: ${APP_BIN_NAME}")

# Find dependencies with Conan
if(EXISTS "${CMAKE_BINARY_DIR}/conan_toolchain.cmake")
    include("${CMAKE_BINARY_DIR}/conan_toolchain.cmake")
endif()

add_executable(${APP_BIN_NAME} main.cpp)

install(TARGETS ${APP_BIN_NAME}
        DESTINATION bin)
EOF_CMAKE

# Create conanfile.txt
echo "Creating conanfile.txt..."
cat > conanfile.txt << 'EOF_CONAN'
[requires]
fmt/9.1.0

[generators]
CMakeDeps
CMakeToolchain
EOF_CONAN

# Create .env_dist file
echo "Creating .env_dist file..."
cat > .env_dist << EOF_ENV
APP_NAME=cpp_demo
APP_VERSION=\${YYYY-MM-DD-HH-MM-SS_Z}
DEBUG_MODE=true
LOG_LEVEL=info
BUILD_TYPE=Debug
CONTAINER_NAME=\${Container_Bin_Name}
BUILD_TIMESTAMP=\${YYYY-MM-DD-HH-MM-SS_Z}
INSTALL_PATH=\${Container_Bin_Path}
EOF_ENV

# Create .dist_build file
echo "Creating .dist_build file..."
cat > .dist_build << 'EOF_DIST'
Container_Name="cpp_demo"
Container_Bin_Name="cpp_demo"
Container_Bin_Path="/usr/local/bin/${Container_Bin_Name}"
Container_Description="my demo app for distro box"
Container_Mantainer="dev1 <dev001@domain.com>;dev2 <dev2@domain.com>"
Container_Tags="tag1,tag2,\${YYYY-MM-DD-HH-MM-SS_Z}"
EOF_DIST

BIN_NAME="cpp_demo"
if [ -f .dist_build ]; then
    BIN_NAME=$(awk -F'"' '/^Container_Bin_Name=/{print $2}' .dist_build)
fi

# Create VSCode configuration
echo "Creating VSCode configuration..."
mkdir -p .vscode

# Create tasks.json
echo "Creating tasks.json..."
cat > .vscode/tasks.json << 'EOF_TASKS'
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "CMake: build",
            "type": "shell",
            "command": "cd ${workspaceFolder}/build && cmake --build .",
            "group": {
                "kind": "build",
                "isDefault": true
            }
        }
    ]
}
EOF_TASKS

cat > .vscode/settings.json << 'EOF_SETTINGS'
{
    "C_Cpp.default.configurationProvider": "ms-vscode.cmake-tools",
    "cmake.configureOnOpen": true,
    "cmake.buildDirectory": "${workspaceFolder}/build",
    "cmake.generator": "Ninja",
    "editor.formatOnSave": true,
    "files.associations": {
        "*.h": "cpp",
        "*.hpp": "cpp",
        "*.cpp": "cpp"
    }
}
EOF_SETTINGS

cat > .vscode/extensions.json << 'EOF_EXTENSIONS'
{
    "recommendations": [
        "ms-vscode.cpptools",
        "ms-vscode.cmake-tools",
        "josetr.cmake-language-support-vscode",
        "disroop.conan",
        "ms-vscode.cpptools-extension-pack",
        "ms-azuretools.vscode-docker",
        "saoudrizwan.claude-dev"
    ]
}
EOF_EXTENSIONS

cat > .vscode/launch.json << EOF_LAUNCH
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Debug C++ Project",
            "type": "cppdbg",
            "request": "launch",
            "program": "\${workspaceFolder}/build/${BIN_NAME}",
            "args": [],
            "stopAtEntry": false,
            "cwd": "\${workspaceFolder}/build",
            "environment": [],
            "externalConsole": false,
            "MIMode": "gdb",
            "setupCommands": [
                {
                    "description": "Enable pretty-printing for gdb",
                    "text": "-enable-pretty-printing",
                    "ignoreFailures": true
                }
            ],
            "preLaunchTask": "CMake: build",
            "miDebuggerPath": "/usr/bin/gdb"
        }
    ]
}
EOF_LAUNCH

# Create build.dist.sh script
echo "Creating build.dist.sh script..."
cat > build.dist.sh << 'EOF_DIST_SH'
#!/bin/bash

# build.dist.sh
# Script to generate a Dockerfile for the C++ demo application

set -e

echo "Generating Dockerfile for C++ demo application..."

# Load variables from .dist_build
if [ -f .dist_build ]; then
    source .dist_build
else
    echo "Error: .dist_build file not found."
    exit 1
fi

# Process variables
TIMESTAMP=$(date "+%Y-%m-%d-%H-%M-%S_%z")
PROCESSED_CONTAINER_BIN_PATH="$Container_Bin_Path"
PROCESSED_CONTAINER_TAGS=$(echo "$Container_Tags" | sed "s|\${YYYY-MM-DD-HH-MM-SS_Z}|$TIMESTAMP|g")

echo "Container Name: $Container_Name"
echo "Binary Name: $Container_Bin_Name"
echo "Binary Path: $PROCESSED_CONTAINER_BIN_PATH"
echo "Tags: $PROCESSED_CONTAINER_TAGS"

# Process .env_dist file
if [ -f .env_dist ]; then
    echo "Processing .env_dist file..."
    ENV_VARS=""
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" || "$line" =~ ^# ]] && continue

        key=$(echo "$line" | cut -d= -f1)
        raw_value=$(echo "$line" | cut -d= -f2-)

        # Expand variables manually
        value=${raw_value//\$\{Container_Bin_Name\}/$Container_Bin_Name}
        value=${value//\$\{Container_Bin_Path\}/$PROCESSED_CONTAINER_BIN_PATH}
        value=${value//\$\{YYYY-MM-DD-HH-MM-SS_Z\}/$TIMESTAMP}

        ENV_VARS+="ENV $key=$value"$'\n'
    done < .env_dist
else
    echo "Warning: .env_dist file not found."
    ENV_VARS=""
fi

# Build the project to detect dependencies
echo "Building project to detect dependencies..."
PROJECT_ROOT="$(pwd)"
mkdir -p "$PROJECT_ROOT/build"
cd "$PROJECT_ROOT/build"
conan install "$PROJECT_ROOT" --output-folder=. --build=missing -s build_type=Debug
cmake "$PROJECT_ROOT" -DCMAKE_TOOLCHAIN_FILE=conan_toolchain.cmake -DCMAKE_BUILD_TYPE=Debug
cmake --build .

# Detect dependencies (basic: libc6 + libgcc-s1 always included)
echo "Detecting dependencies..."
PACKAGES="ca-certificates libc6 libgcc-s1"
CONTAINER_DEPS="libc6:$(dpkg-query -W -f='${Version}' libc6)"
CONTAINER_DEPS+=";libgcc-s1:$(dpkg-query -W -f='${Version}' libgcc-s1)"

# Show summary
echo -e "\nRequired base packages:"
echo "$CONTAINER_DEPS"
echo ""

# Generate Dockerfile
echo "Generating dockerfile.dist..."
cd ..

cat > dockerfile.dist << EOF_DOCKERFILE
# This file is generated by build.dist.sh script. Do not edit directly.
# Generated on: $(date)
FROM ubuntu:22.04

LABEL description="$Container_Description"
LABEL maintainer="$Container_Mantainer"
LABEL tags="$PROCESSED_CONTAINER_TAGS"
LABEL path="$PROCESSED_CONTAINER_BIN_PATH"

RUN apt-get update && \
    apt-get install -y --no-install-recommends $PACKAGES && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

$ENV_VARS
ENV Container_App_Dependencies="$CONTAINER_DEPS"

RUN mkdir -p \$(dirname $PROCESSED_CONTAINER_BIN_PATH)
COPY build/$Container_Bin_Name $PROCESSED_CONTAINER_BIN_PATH
ENTRYPOINT ["$PROCESSED_CONTAINER_BIN_PATH"]
EOF_DOCKERFILE

echo "Dockerfile generated successfully: dockerfile.dist"
echo "Building Docker image with: docker build -t $Container_Name -f dockerfile.dist ."
docker build -t "$Container_Name" -f dockerfile.dist .

# Parse and apply tags from Container_Tags
IFS=',' read -ra TAG_ARRAY <<< "$PROCESSED_CONTAINER_TAGS"

for tag in "${TAG_ARRAY[@]}"; do
    clean_tag=$(echo "$tag" | sed 's|.*/||')  # solo deja la parte final después de la última "/"
    echo "Tagging image: $Container_Name:$clean_tag"
    docker tag "$Container_Name" "$Container_Name:$clean_tag"
done

if [ $? -eq 0 ]; then
    echo "Docker image '$Container_Name' built successfully!"
    echo "You can run the container with: docker run $Container_Name"
else
    echo "Error: Failed to build Docker image."
fi
EOF_DIST_SH

# Create build.sh script
echo "Creating build.sh script..."
cat > build.sh << 'EOF_BUILD'
#!/bin/bash

# build.sh
# Script to automate the build process for the C++ demo application

set -e

echo "Building C++ demo application..."

# Create build directory if it doesn't exist
mkdir -p build
cd build

# Generate Conan files
echo "Generating Conan files..."
conan install .. --output-folder=. --build=missing

# Configure with CMake
echo "Configuring with CMake..."
cmake .. -DCMAKE_TOOLCHAIN_FILE=conan_toolchain.cmake -DCMAKE_BUILD_TYPE=Debug

# Build the project
echo "Building the project..."
cmake --build .

echo "Build completed successfully!"

# Get the binary name from .dist_build using a more precise method
if [ -f "../.dist_build" ]; then
    BIN_NAME=$(awk -F'"' '/^Container_Bin_Name=/{print $2}' ../.dist_build)
else
    BIN_NAME="cpp_demo"
fi
echo "You can run the application with: ./build/${BIN_NAME}"
EOF_BUILD

# Make scripts executable
chmod +x build.dist.sh build.sh
EOF

# Create README.md for the project
echo "Creating README.md inside container..."
distrobox enter $CONTAINER_NAME -- bash << 'EOF'
cd ~/Desktop/projects/cpp/cpp_demo

cat > README.md << 'EOF_README'
# C++ Development Environment with Distrobox

This project provides scripts to set up a C++ development environment using Distrobox and create a containerized C++ application.

## Features

- **Complete C++ Development Environment**: This project is set up with everything you need for modern C++ development:
  - **C++23 Support**: Latest C++ standard features are enabled
  - **Modern Build System**: CMake 3.28.3 with proper project structure
  - **Package Management**: Conan integration for dependency management
  - **IDE Integration**: Full VSCode setup with debugging capabilities
  - **Containerization**: Tools to package your application in a minimal Docker container
  - **Docker Support**: Docker Engine installed from the official Docker repository

- **Development Tools Available**:
  - **Build Tools**: build-essential, CMake 3.28.3
  - **Package Manager**: Conan for C++ dependencies
  - **Version Control**: git for source control
  - **Utilities**: mc (Midnight Commander), htop for system monitoring
  - **IDE**: Visual Studio Code with C++ extensions
  - **Containerization**: Docker Engine and Docker Compose for building and running containers

- **Project Structure**:
  - Modern CMake project layout
  - Proper separation of build configuration
  - Environment variable management
  - Containerization support

## Scripts

### build.sh

This script automates the build process for the C++ application:

1. Creates the build directory if it doesn't exist
2. Generates Conan files
3. Configures the project with CMake
4. Builds the project

### build.dist.sh

This script generates a Dockerfile for the C++ application and builds the Docker image:

1. Processes variables from `.dist_build` and `.env_dist` files
2. Builds the project to detect dependencies
3. Analyzes dependencies to determine required packages and their versions
4. Creates a special environment variable `Container_App_Dependencies` with the format `package:version;package:version`
5. Generates a Dockerfile (`dockerfile.dist`) that:
   - Installs only the necessary dependencies
   - Sets environment variables including `Container_App_Dependencies`
   - Copies the application to the specified path
   - Sets the entrypoint
6. Automatically builds the Docker image using the generated Dockerfile

## Configuration Files

### .dist_build

Contains configuration for the container build:

```
Container_Name="cpp_demo"
Container_Bin_Name="cpp_demo"
Container_Bin_Path=/usr/local/bin/${Container_Bin_Name}
Container_Description="my demo app for distro box"
Container_Mantainer="dev1 <dev001@domain.com>;dev2 <dev2@domain.com>"
Container_Tags="tag1,tag2,${YYYY-MM-DD-HH-MM-SS_Z}"
```

### .env_dist

Contains environment variables to be set in the container:

```
APP_NAME=cpp_demo
APP_VERSION=${YYYY-MM-DD-HH-MM-SS_Z}
DEBUG_MODE=true
LOG_LEVEL=info
BUILD_TYPE=Debug
CONTAINER_NAME=${Container_Bin_Name}
BUILD_TIMESTAMP=${YYYY-MM-DD-HH-MM-SS_Z}
INSTALL_PATH=${Container_Bin_Path}
```

## VSCode Configuration

The project includes VSCode configuration for C++ development:

- Debug configuration
- CMake integration
- Recommended extensions:
  - C/C++ tools
  - CMake tools
  - Conan extension
  - Cline extension

## Usage

1. Enter the Distrobox container:
   ```
   distrobox enter cpp_dev_env
   ```

2. Navigate to the project and build it:
   ```
   cd ~/Desktop/projects/cpp/cpp_demo
   ./build.sh
   ```
   
   Or manually:
   ```
   cd ~/Desktop/projects/cpp/cpp_demo
   mkdir -p build && cd build
   conan install .. --output-folder=. --build=missing
   cmake .. -DCMAKE_TOOLCHAIN_FILE=conan_toolchain.cmake
   cmake --build .
   ```

3. To create a container image for the application and build it automatically:
   ```
   ./build.dist.sh
   ```

4. Run the containerized application:
   ```
   docker run cpp_demo
   ```

## Docker Support

This environment comes with Docker Engine installed from the official Docker repository, allowing you to build and run Docker containers directly inside the Distrobox container. This setup provides several advantages:

- Build Docker images for your C++ applications
- Test containerized applications in isolation
- Use Docker Compose for multi-container applications
- Access Docker commands without needing to install Docker on your host system

### Using Docker Inside the Container

After entering the Distrobox container, you can use Docker commands as you normally would:

```bash
# Check Docker version
docker --version

# List Docker images
docker images

# Build an image (using the generated dockerfile.dist)
docker build -t my_cpp_app -f dockerfile.dist .

# Run a container
docker run my_cpp_app

# Use Docker Compose
docker compose up
```

### Docker Compose Example

You can create a `docker-compose.yml` file for more complex setups:

```yaml
version: '3'
services:
  cpp_app:
    build:
      context: .
      dockerfile: dockerfile.dist
    ports:
      - "8080:8080"
  database:
    image: postgres:latest
    environment:
      POSTGRES_PASSWORD: example
```

Then run it with:
```bash
docker compose up
```

This setup allows you to develop C++ applications and containerize them all within the same development environment.
EOF_README

echo "README.md created successfully!"
EOF


echo "All files created successfully!"

# No temporary files to clean up

cd ..

# Display helpful commands for the user
echo ""
echo "====================================================="
echo "Setup completed successfully!"
echo "====================================================="
echo ""
echo "Next steps:"
echo ""
echo "1. Enter the container:"
echo "   distrobox enter $CONTAINER_NAME"
echo ""
echo "2. Navigate to the project directory:"
echo "   cd Desktop/projects/cpp/cpp_demo"
echo ""
echo "3. Open the project in VSCode:"
echo "   code ."
echo ""
echo "4. Build the demo project:"
echo "   cd cpp_demo"
echo "   ./build.sh"
echo ""
echo "5. Run the demo application:"
echo "   ./build/cpp_demo"
echo ""
echo "6. Generate Dockerfile and build Docker image:"
echo "   ./build.dist.sh"
echo ""
echo "7. Use Docker inside the container:"
echo "   docker --version"
echo "   docker images"
echo "   docker run cpp_demo"
echo ""
echo "====================================================="
echo ""
