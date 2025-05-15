#!/bin/bash

# build_cpp_dev_env.sh
# Script to set up a C++ development environment using distrobox

# Set error handling
set -e

# Detect if running inside Distrobox container
if [ -n "$DISTROBOX_ENTER_PATH" ]; then
    echo "You are currently inside a Distrobox container."
    echo "This script is designed to run only on the host operating system."
    echo "Please type 'exit' an hit enter key to leave the container."
    echo "Locate this script on the host filesystem, and try run again."
    exit 1
fi

echo "Starting build_cpp_dev_env.sh at $(date)"

HOST_USER_NAME="$(whoami)"
export HOST_DOCKER_GID=$(getent group docker | cut -d: -f3)

HOST_DOCKER_SOCKET_PATH="/var/run/docker.sock"

CONTAINER_NAME="cpp_dev_env"
CONTAINER_PROJECT_FOLDER="~/Desktop/projects/cpp/cpp_demo"
CONTAINER_IMAGE_NAME="ubuntu:22.04"
CONTAINER_HOME="/home/${HOST_USER_NAME}/Desktop/distrobox/containers/home/${CONTAINER_NAME}"
export CONTAINER_DOCKER_SOCKET_PATH="/run/host_docker.sock"

# Function to clean up if something goes wrong
cleanup() {
  if [ ! -d "$CONTAINER_HOME" ]; then
    mkdir -p "$CONTAINER_HOME"
  fi    
  echo "Cleaning up distrobox environment..."
  distrobox stop -Y $CONTAINER_NAME > /dev/null 2>&1 || true
  distrobox rm -f $CONTAINER_NAME > /dev/null 2>&1 || true
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
        # Check installed version
        INSTALLED_VERSION=$(distrobox --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        if [ -n "$INSTALLED_VERSION" ]; then
            MAJOR_VERSION=$(echo "$INSTALLED_VERSION" | cut -d. -f1)
            MINOR_VERSION=$(echo "$INSTALLED_VERSION" | cut -d. -f2)
            
            echo "Distrobox version $INSTALLED_VERSION is installed."
            
            # Check if version is less than 1.8.0
            if [ "$MAJOR_VERSION" -lt 1 ] || ([ "$MAJOR_VERSION" -eq 1 ] && [ "$MINOR_VERSION" -lt 8 ]); then
                echo "WARNING: Distrobox versions below 1.8.0 have issues with the 'distrobox rm -f' command."
                echo "This may cause the script to hang. Consider upgrading to version 1.8.0 or higher."
            fi
        else
            echo "Distrobox is installed, but couldn't determine version."
        fi
        return
    fi

    echo "Distrobox not found. Attempting to install..."
    
    # Check package manager
    if command -v apt &> /dev/null; then
        echo "Detected apt package manager."
        
        # Check if distrobox is available in the repository and its version
        sudo apt update
        AVAILABLE_VERSION=$(apt-cache policy distrobox 2>/dev/null | grep Candidate | awk '{print $2}')
        
        if [ -n "$AVAILABLE_VERSION" ]; then
            # Extract version number for comparison
            MAJOR_VERSION=$(echo "$AVAILABLE_VERSION" | cut -d. -f1)
            MINOR_VERSION=$(echo "$AVAILABLE_VERSION" | cut -d. -f2)
            
            echo "Found distrobox version $AVAILABLE_VERSION in repository."
            
            # Check if version is greater than or equal to 1.8.0
            if [ "$MAJOR_VERSION" -gt 1 ] || ([ "$MAJOR_VERSION" -eq 1 ] && [ "$MINOR_VERSION" -ge 8 ]); then
                echo "Installing distrobox from official repository..."
                sudo apt install -y distrobox
            else
                echo "Repository version is older than 1.8.0. Installing from Debian package..."
                wget -q https://ftp.debian.org/debian/pool/main/d/distrobox/distrobox_1.8.1.2-1_all.deb -O /tmp/distrobox.deb
                sudo dpkg -i /tmp/distrobox.deb
                # Install dependencies if needed
                sudo apt install -f -y
                rm -f /tmp/distrobox.deb
            fi
        else
            echo "Distrobox not found in repository. Installing from Debian package..."
            wget -q https://ftp.debian.org/debian/pool/main/d/distrobox/distrobox_1.8.1.2-1_all.deb -O /tmp/distrobox.deb
            sudo dpkg -i /tmp/distrobox.deb
            # Install dependencies if needed
            sudo apt install -f -y
            rm -f /tmp/distrobox.deb
        fi
    elif command -v dnf &> /dev/null; then
        echo "Detected dnf package manager."
        
        # Check if distrobox is available in the repository and its version
        AVAILABLE_VERSION=$(dnf info distrobox 2>/dev/null | grep Version | awk '{print $3}')
        
        if [ -n "$AVAILABLE_VERSION" ]; then
            # Extract version number for comparison
            MAJOR_VERSION=$(echo "$AVAILABLE_VERSION" | cut -d. -f1)
            MINOR_VERSION=$(echo "$AVAILABLE_VERSION" | cut -d. -f2)
            
            echo "Found distrobox version $AVAILABLE_VERSION in repository."
            
            # Check if version is greater than or equal to 1.8.0
            if [ "$MAJOR_VERSION" -gt 1 ] || ([ "$MAJOR_VERSION" -eq 1 ] && [ "$MINOR_VERSION" -ge 8 ]); then
                echo "Installing distrobox from official repository..."
                sudo dnf install -y distrobox
            else
                echo "WARNING: Repository version is older than 1.8.0."
                echo "Versions below 1.8.0 have issues with the 'distrobox rm -f' command, which may cause the script to hang."
                echo "Installing anyway, but consider upgrading later..."
                sudo dnf install -y distrobox
            fi
        #else
        #    echo "Distrobox not found in repository. Installing from GitHub release..."
        #    wget -q https://github.com/89luca89/distrobox/releases/download/1.8.1/distrobox-1.8.1-1.noarch.rpm -O /tmp/distrobox.rpm
        #    sudo rpm -i /tmp/distrobox.rpm
        #    rm -f /tmp/distrobox.rpm
        fi
    #elif command -v rpm &> /dev/null; then
    #    echo "Detected rpm-based system."
    #    echo "Installing distrobox 1.8.1 from GitHub release..."
    #    wget -q https://github.com/89luca89/distrobox/releases/download/1.8.1/distrobox-1.8.1-1.noarch.rpm -O /tmp/distrobox.rpm
    #    sudo rpm -i /tmp/distrobox.rpm
    #    rm -f /tmp/distrobox.rpm
    else
        echo "Error: Could not determine package manager. Please install distrobox manually."
        exit 1
    fi
    
    # Verify installation
    if command -v distrobox &>/dev/null; then
        INSTALLED_VERSION=$(distrobox --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        if [ -n "$INSTALLED_VERSION" ]; then
            echo "Distrobox version $INSTALLED_VERSION installed successfully."
            
            # Check if version is less than 1.8.0
            MAJOR_VERSION=$(echo "$INSTALLED_VERSION" | cut -d. -f1)
            MINOR_VERSION=$(echo "$INSTALLED_VERSION" | cut -d. -f2)
            
            if [ "$MAJOR_VERSION" -lt 1 ] || ([ "$MAJOR_VERSION" -eq 1 ] && [ "$MINOR_VERSION" -lt 8 ]); then
                echo "WARNING: Distrobox versions below 1.8.0 have issues with the 'distrobox rm -f' command."
                echo "This may cause the script to hang. Consider upgrading to version 1.8.0 or higher."
            fi
        else
            echo "Distrobox installed successfully, but couldn't determine version."
        fi
    else
        echo "Error: Failed to install distrobox."
        exit 1
    fi
}

# Process command line options
DO_CLEANUP=false
DO_CLEAN_LOGS=false
DO_REMOVE_OLD_CONTAINER=false
DO_CLEAN_CONTAINER_HOME=false
DO_SETUP=true #By default try to setup
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
        --no-setup)
            DO_SETUP=false
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

# Execute requested actions
if [ "$DO_CLEAN_CONTAINER_HOME" = true ]; then
    clean_container_home "$CONTAINER_HOME"
fi

# Exit if any action was performed
if [ "$VALID_ARGS" = true ]; then
    exit 0
fi

echo "Setting up C++ development environment with distrobox..."

check_and_install_docker_in_host

check_and_install_distrobox_in_host

if [ "$DO_SETUP" = true ]; then

  echo "Current user running this script: $HOST_USER_NAME"

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
    #CONTAINER_PATH="/home/$HOST_USER_NAME/$folder"
    CONTAINER_PATH="$CONTAINER_HOME/$folder"

    if [ -e "$HOST_PATH" ]; then
        echo "Mounting $folder"
        ADDITIONAL_FLAGS+=( "--additional-flags" "--volume $HOST_PATH:$CONTAINER_PATH" )
    else
        echo "$folder does not exist, skipping"
    fi
  done

  echo "In the host enviroment HOST_DOCKER_GID: $HOST_DOCKER_GID"

  if [ -S $HOST_DOCKER_SOCKET_PATH ]; then

    #if docker inspect "$CONTAINER_NAME" >/dev/null 2>&1; then
    #   docker rm -f -v $CONTAINER_NAME 2>/dev/null || true
    #fi

    CURRENT_PERMS=$(stat -c "%a" "$HOST_DOCKER_SOCKET_PATH")
    if [ "$CURRENT_PERMS" != "666" ]; then
        echo "Setting host Docker socket to 0666..."
        sudo chmod 666 "$HOST_DOCKER_SOCKET_PATH"
    else
        echo "Docker socket already has 0666 permissions, skipping chmod."
    fi

    echo "Mapping Docker socket from host to container in $CONTAINER_DOCKER_SOCKET_PATH..."
    ADDITIONAL_FLAGS+=( "--additional-flags" "--volume /var/run/docker.sock:$CONTAINER_DOCKER_SOCKET_PATH" )
    ADDITIONAL_FLAGS+=( "--additional-flags" "--env HOST_DOCKER_GID=$HOST_DOCKER_GID" )
    ADDITIONAL_FLAGS+=( "--additional-flags" "--env DOCKER_SOCKET=$CONTAINER_DOCKER_SOCKET_PATH" )
    ADDITIONAL_FLAGS+=( "--additional-flags" "--env CONTAINER_PROJECT_FOLDER=$CONTAINER_PROJECT_FOLDER" )
  else
    echo "Docker socket not found at $HOST_DOCKER_SOCKET_PATH"
  fi

  # Create the container with each --additional-flags passed separately
  echo "Creating Ubuntu 22.04 container named $CONTAINER_NAME..."
  distrobox create \
    --name "$CONTAINER_NAME" \
    --image "$CONTAINER_IMAGE_NAME" \
    --home "$CONTAINER_HOME" \
    "${ADDITIONAL_FLAGS[@]}" \
    --yes

  # Prepare to set up the development environment inside the container
  echo "Set up development environment inside container..."

  # Execute the setup commands directly inside the container
  echo "Setting up development environment inside container..."
  distrobox enter $CONTAINER_NAME -- bash << 'EOF'
    # Set non-interactive frontend to avoid any UI prompts
    export DEBIAN_FRONTEND=noninteractive

    if [ -z "$HOST_DOCKER_GID" ]; then
        echo "Warning: HOST_DOCKER_GID is empty!"
    else
        echo "In the container environment HOST_DOCKER_GID: $HOST_DOCKER_GID"
    fi

    # Ensure DOCKER_SOCKET has a default value in case --env didn't work
    # Note: We use the hardcoded path here because this is inside a single-quoted heredoc
    # which doesn't allow variable expansion. The value matches CONTAINER_DOCKER_SOCKET_PATH.
    export DOCKER_SOCKET="${DOCKER_SOCKET:-/run/host_docker.sock}"

    # Check if the docker group exists
    if getent group docker >/dev/null; then
        CONTAINER_DOCKER_GID=$(getent group docker | cut -d: -f3)
        echo "Group 'docker' exists with GID $CONTAINER_DOCKER_GID"

        if [ "$CONTAINER_DOCKER_GID" != "$HOST_DOCKER_GID" ]; then
            echo "GID mismatch detected, deleting and recreating 'docker' group with GID $HOST_DOCKER_GID"
            sudo groupdel docker
            sudo groupadd -g "$HOST_DOCKER_GID" docker
        else
            echo "Group 'docker' already has the correct GID."
        fi
    else
        echo "Group 'docker' does not exist, creating it with GID $HOST_DOCKER_GID"
        sudo groupadd -g "$HOST_DOCKER_GID" docker
    fi

    # Add current user to the docker group
    sudo usermod -aG docker "$USER"

    # Update package lists
    echo "Updating package lists..."
    sudo apt update

    # Install basic development tools
    echo "Installing build-essential, git, mc, htop..."
    sudo apt install -y build-essential gdb git mc htop python3-pip curl gnupg lsb-release ca-certificates gettext nano

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
    #echo "Exporting VSCode to the host system..."
    #distrobox-export --app code

    #Force to use the code app inside of container
    echo 'alias code="/usr/bin/code"' >> ~/.bashrc
    source ~/.bashrc

    # Clean project folder
    if [ -n "$CONTAINER_PROJECT_FOLDER" ] &&
       [ "$CONTAINER_PROJECT_FOLDER" != "/" ] &&
       [ "$CONTAINER_PROJECT_FOLDER" != "/home" ] &&
       [ "$CONTAINER_PROJECT_FOLDER" != "$HOME" ] &&
       [ -d "$CONTAINER_PROJECT_FOLDER" ]; then
        echo "Cleaning previous project directory: $CONTAINER_PROJECT_FOLDER"
        rm -rf "$CONTAINER_PROJECT_FOLDER"
    fi
EOF

fi

# Execute the setup commands directly inside the container
echo "Setting up development environment inside container..."


distrobox enter $CONTAINER_NAME -- bash << 'EOF'

#*************************************
# VSCode token store turn to basic
#*************************************
# Set up VSCode argv.json to use basic password-store
VSCODE_ARGV_DIR="$HOME/.vscode"
mkdir -p "$VSCODE_ARGV_DIR"
cat > "$VSCODE_ARGV_DIR/argv.json" << 'EOF_ARGV'
{
  "password-store": "basic"
}
EOF_ARGV

echo "VSCode password-store configuration added to ~/.vscode/argv.json"

# Set up VSCode Git configuration
mkdir -p ~/.config/Code/User
cat > ~/.config/Code/User/settings.json <<'EOF_SETTINGS'
{
  "git.enabled": false,
  "git.useCredentialStore": false,
  "git.autofetch": false,
  "git.confirmSync": false
}
EOF_SETTINGS

echo "VSCode Git configuration added to ~/.config/Code/User/settings.json"

#*************************************
# Set up custom prompt for Distrobox container
#*************************************
# Ensure .bashrc is sourced from .bash_profile (for login shells)
BASHRC="$HOME/.bashrc"
BASHPROFILE="$HOME/.bash_profile"

if ! grep -q '\.bashrc' "$BASHPROFILE" 2>/dev/null; then
    echo "[[ -f ~/.bashrc ]] && source ~/.bashrc" >> "$BASHPROFILE"
    echo "✔ Added .bashrc sourcing to .bash_profile"
fi

# Add prompt customization block with container hostname in bright green
if ! grep -q 'PS1.*hostname' "$BASHRC"; then
    cat >> "$BASHRC" << 'EOF_PROMPT'

# Custom prompt for Distrobox container
export CONTAINER_ID=1
export PS1="(\h) \u@\[\e[1;32m\]\$(hostname)\[\e[0m\]:\w\$ "
EOF_PROMPT
    echo "✔ Added dynamic prompt to .bashrc"
else
    echo "ℹ Prompt block already present in .bashrc"
fi

# Apply the new prompt immediately
source "$BASHRC"

echo "Custom prompt configuration added to ~/.bashrc"

EOF

#*************************************
# Create project directory
#*************************************
distrobox enter $CONTAINER_NAME -- bash << EOF
# Create C++ demo project
echo "Creating C++ demo project..."
mkdir -p $CONTAINER_PROJECT_FOLDER
EOF

# Read the content of the scripts from host
BUILD_DIST_CONTENT=$(cat "$(dirname "$0")/build.dist.sh")

#*************************************
# Create build.dist.sh
#*************************************
echo "Creating build.dist.sh script..."
distrobox enter $CONTAINER_NAME -- bash << EOF
cd $CONTAINER_PROJECT_FOLDER
cat > build.dist.sh << 'EOF_DIST_SH'
$BUILD_DIST_CONTENT
EOF_DIST_SH
chmod +x build.dist.sh
echo "build.dist.sh created and made executable."
EOF

BUILD_CONTENT=$(cat "$(dirname "$0")/build.sh")

#*************************************
# Create build.sh
#*************************************
echo "Creating build.sh script..."
distrobox enter $CONTAINER_NAME -- bash << EOF
cd $CONTAINER_PROJECT_FOLDER
cat > build.sh << 'EOF_BUILD'
$BUILD_CONTENT
EOF_BUILD
chmod +x build.sh
echo "build.sh created and made executable."
EOF

HELPER_CONTENT=$(cat "$(dirname "$0")/helper.sh")

#*************************************
# Create helper.sh
#*************************************
echo "Creating helper.sh script..."
distrobox enter $CONTAINER_NAME -- bash << EOF
cd $CONTAINER_PROJECT_FOLDER
cat > helper.sh << 'EOF_HELPER'
$HELPER_CONTENT
EOF_HELPER
chmod +x helper.sh
echo "helper.sh created and made executable."
EOF

#*************************************
# Create main.cpp
#*************************************
echo "Creating main.cpp..."
distrobox enter $CONTAINER_NAME -- bash << EOF
cd $CONTAINER_PROJECT_FOLDER
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
EOF

#*************************************
# Create CMakeLists.txt
#*************************************
echo "Creating CMakeLists.txt..."
distrobox enter $CONTAINER_NAME -- bash << EOF
cd $CONTAINER_PROJECT_FOLDER
cat > CMakeLists.txt << 'EOF_CMAKE'
cmake_minimum_required(VERSION 3.15)
project(cpp_demo VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Load binary name from .dist_build
file(STRINGS ".dist_build" DIST_BUILD_CONTENT)
foreach(LINE \${DIST_BUILD_CONTENT})
    if(LINE MATCHES "^Container_Bin_Name=\"([^\"]+)\"$")
        set(APP_BIN_NAME \${CMAKE_MATCH_1})
    endif()
endforeach()

if(NOT DEFINED APP_BIN_NAME)
    set(APP_BIN_NAME "cpp_demo")
    message(WARNING "Container_Bin_Name not found in .dist_build, using default: \${APP_BIN_NAME}")
endif()

message(STATUS "Building executable: \${APP_BIN_NAME}")

# Find dependencies with Conan
if(EXISTS "\${CMAKE_BINARY_DIR}/conan_toolchain.cmake")
    include("\${CMAKE_BINARY_DIR}/conan_toolchain.cmake")
endif()

add_executable(\${APP_BIN_NAME} main.cpp)

install(TARGETS \${APP_BIN_NAME}
        DESTINATION bin)
EOF_CMAKE
EOF

#*************************************
# Create conanfile.txt
#*************************************
echo "Creating conanfile.txt..."
distrobox enter $CONTAINER_NAME -- bash << EOF
cd $CONTAINER_PROJECT_FOLDER
cat > conanfile.txt << 'EOF_CONAN'
[requires]
fmt/9.1.0

[generators]
CMakeDeps
CMakeToolchain
EOF_CONAN
EOF

#*************************************
# Create .env_dist file
#*************************************
echo "Creating .env_dist file..."
distrobox enter $CONTAINER_NAME -- bash << EOF
cd $CONTAINER_PROJECT_FOLDER
cat > .env_dist << 'EOF_ENV'
APP_NAME=cpp_demo
APP_VERSION=\${YYYY}-\${MM}-\${DD}-\${HH}-\${MM}-\${SS}_\${Z}
DEBUG_MODE=true
LOG_LEVEL=info
BUILD_TYPE=Debug
CONTAINER_NAME=\${Container_Bin_Name}
BUILD_TIMESTAMP=\${YYYY}-\${MM}-\${DD}-\${HH}-\${MM}-\${SS}_\${Z}
INSTALL_PATH=\${Container_Bin_Path}
EOF_ENV
EOF

#*************************************
# Create .dist_build file
#*************************************
echo "Creating .dist_build file..."
distrobox enter $CONTAINER_NAME -- bash << EOF
cd $CONTAINER_PROJECT_FOLDER
cat > .dist_build << 'EOF_DIST'
Container_Name="cpp_demo"
Container_Bin_Name="cpp_demo"
Container_Bin_Path="/usr/local/bin/\${Container_Bin_Name}/"
Container_Description="my demo app for distro box"
Container_Mantainer="dev1 <dev001@domain.com>;dev2 <dev2@domain.com>"
Container_Tags="latest;tag1;tag2;\${YYYY}-\${MM}-\${DD}-\${HH}-\${MM}-\${SS}_\${Z}"
Container_Group="cpp_demo"
Container_User="cpp_demo"
Container_Group_Id=1000
Container_User_Id=1000
Container_App_Folders="\${Container_Bin_Path}/logs;\${Container_Bin_Path}/data/\${YYYY}-\${MM}-\${DD}-\${HH}-\${MM}-\${SS}_\${Z}"
EOF_DIST

EOF

#*************************************
# Create VSCode configuration directory
#*************************************
echo "Creating VSCode configuration..."
distrobox enter $CONTAINER_NAME -- bash << EOF
cd $CONTAINER_PROJECT_FOLDER
mkdir -p .vscode
EOF

#*************************************
# Create tasks.json
#*************************************
echo "Creating tasks.json..."
distrobox enter $CONTAINER_NAME -- bash << EOF
cd $CONTAINER_PROJECT_FOLDER
cat > .vscode/tasks.json << 'EOF_TASKS'
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "CMake: build",
            "type": "shell",
            "command": "cd \${workspaceFolder}/build && cmake --build .",
            "group": {
                "kind": "build",
                "isDefault": true
            }
        }
    ]
}
EOF_TASKS
EOF

#*************************************
# Create settings.json
#*************************************
echo "Creating settings.json..."
distrobox enter $CONTAINER_NAME -- bash << EOF
cd $CONTAINER_PROJECT_FOLDER
cat > .vscode/settings.json << 'EOF_SETTINGS'
{
    "C_Cpp.default.configurationProvider": "ms-vscode.cmake-tools",
    "cmake.configureOnOpen": true,
    "cmake.buildDirectory": "\${workspaceFolder}/build",
    "cmake.generator": "Ninja",
    "editor.formatOnSave": true,
    "files.associations": {
        "*.h": "cpp",
        "*.hpp": "cpp",
        "*.cpp": "cpp"
    }
}
EOF_SETTINGS
EOF

#*************************************
# Create extensions.json
#*************************************
echo "Creating extensions.json..."
distrobox enter $CONTAINER_NAME -- bash << EOF
cd $CONTAINER_PROJECT_FOLDER
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
EOF

#*************************************
# Create launch.json
#*************************************
echo "Creating launch.json..."
distrobox enter $CONTAINER_NAME -- bash << EOF
cd $CONTAINER_PROJECT_FOLDER

BIN_NAME="cpp_demo"
if [ -f .dist_build ]; then
    BIN_NAME=\$(awk -F'"' '/^Container_Bin_Name=/{print \$2}' .dist_build)
fi

cat > .vscode/launch.json << 'EOF_LAUNCH'
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Debug C++ Project",
            "type": "cppdbg",
            "request": "launch",
            "program": "\${workspaceFolder}/build/\${BIN_NAME}",
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
EOF

#*************************************
# Create README.md
#*************************************
echo "Creating README.md inside container..."
distrobox enter $CONTAINER_NAME -- bash << EOF
cd $CONTAINER_PROJECT_FOLDER

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

1. Processes variables from \`.dist_build\` and \`.env_dist\` files
2. Builds the project to detect dependencies
3. Analyzes dependencies to determine required packages
4. Generates a Dockerfile with only the necessary dependencies
5. Builds and tags the Docker image
EOF_README
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
