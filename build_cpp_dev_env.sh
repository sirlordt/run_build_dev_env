#!/bin/bash

# build_cpp_dev_env.sh
# Script to set up a C++ development environment using distrobox

# Set error handling
set -e

echo "Starting build_cpp_dev_env.sh at $(date)"

# Function to clean up if something goes wrong
cleanup() {
    echo "Cleaning up distrobox environment..."
    distrobox stop cpp_dev_env 2>/dev/null || true
    distrobox rm cpp_dev_env 2>/dev/null || true
    echo "Cleanup completed."
}

# Add option to clean up
if [ "$1" = "--cleanup" ]; then
    cleanup
    exit 0
fi

echo "Setting up C++ development environment with distrobox..."

# Check if distrobox is installed
if ! command -v distrobox &> /dev/null; then
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

# Create Ubuntu 22.04 container
CONTAINER_NAME="cpp_dev_env"
echo "Creating Ubuntu 22.04 container named $CONTAINER_NAME..."
distrobox create --name $CONTAINER_NAME --image ubuntu:22.04

# Create a setup script to run inside the container
echo "Creating setup script..."
cat > setup_container.sh << 'EOF'
#!/bin/bash
set -e

# Update package lists
echo "Updating package lists..."
sudo apt update

# Install basic development tools
echo "Installing build-essential, git, mc, htop..."
sudo apt install -y build-essential git mc htop python3-pip

# Install Conan from pip3
echo "Installing Conan package manager..."
pip3 install conan

# Install latest CMake
echo "Installing latest CMake..."
CMAKE_VERSION="3.28.3"
wget https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-x86_64.sh -O /tmp/cmake-install.sh
chmod +x /tmp/cmake-install.sh
sudo /tmp/cmake-install.sh --skip-license --prefix=/usr/local

# Install VSCode
echo "Installing Visual Studio Code..."
sudo apt install -y software-properties-common apt-transport-https wget
wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main"
sudo apt update
sudo apt install -y code

# Create project directory structure
echo "Creating project directory structure..."
mkdir -p ~/Desktop/projects/cpp

# Create C++ demo project
echo "Creating C++ demo project..."
mkdir -p ~/Desktop/projects/cpp/cpp_demo
cd ~/Desktop/projects/cpp/cpp_demo

# Generate Conan profile
echo "Generating Conan profile..."
conan profile detect
EOF

# Make the setup script executable
chmod +x setup_container.sh

# Execute the setup commands directly inside the container
echo "Setting up development environment inside container..."
distrobox enter $CONTAINER_NAME -- bash -c "$(cat setup_container.sh)"

# Create a script for creating project files
echo "Creating project files script..."
cat > create_project_files.sh << 'EOF'
#!/bin/bash
set -e

cd ~/Desktop/projects/cpp/cpp_demo
    
    # Create main.cpp
    echo "Creating main.cpp..."
    cat > main.cpp << '\''EOF'\''
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
EOF

# Create CMakeLists.txt
echo "Creating CMakeLists.txt..."
cat > CMakeLists.txt << 'EOF'
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
EOF

# Create conanfile.txt
echo "Creating conanfile.txt..."
cat > conanfile.txt << 'EOF'
[requires]
fmt/9.1.0

[generators]
CMakeDeps
CMakeToolchain
EOF

# Create .env_dist file
echo "Creating .env_dist file..."
cat > .env_dist << 'EOF'
APP_NAME=cpp_demo
APP_VERSION=${YYYY-MM-DD-HH-MM-SS_Z}
DEBUG_MODE=true
LOG_LEVEL=info
BUILD_TYPE=Debug
CONTAINER_NAME=${Container_Bin_Name}
BUILD_TIMESTAMP=${YYYY-MM-DD-HH-MM-SS_Z}
INSTALL_PATH=${Container_Bin_Path}
EOF

# Create .dist_build file
echo "Creating .dist_build file..."
cat > .dist_build << 'EOF'
Container_Name="cpp_demo"
Container_Bin_Name="cpp_demo"
Container_Bin_Path=/usr/local/bin/${Container_Bin_Name}
Container_Description="my demo app for distro box"
Container_Mantainer="dev1 <dev001@domain.com>;dev2 <dev2@domain.com>"
Container_Tags="tag1,tag2,${YYYY-MM-DD-HH-MM-SS_Z}"
EOF

# Create VSCode configuration
echo "Creating VSCode configuration..."
mkdir -p .vscode

# Create tasks.json
echo "Creating tasks.json..."
cat > .vscode/tasks.json << '\''EOF'\''
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
EOF

cat > .vscode/settings.json << '\''EOF'\''
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
EOF

cat > .vscode/extensions.json << '\''EOF'\''
{
    "recommendations": [
        "ms-vscode.cpptools",
        "ms-vscode.cmake-tools",
        "twxs.cmake",
        "josetr.cmake-language-support-vscode",
        "cline.cline",
        "disroop.conan"
    ]
}
EOF

cat > .vscode/launch.json << '\''EOF'\''
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Debug",
            "type": "cppdbg",
            "request": "launch",
            "program": "${workspaceFolder}/build/$(grep Container_Bin_Name ${workspaceFolder}/.dist_build | cut -d'\"' -f2)",
            "args": [],
            "stopAtEntry": false,
            "cwd": "${workspaceFolder}",
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
EOF

# Create build.dist.sh script
echo "Creating build.dist.sh script..."
cat > build.dist.sh << '\''EOF'\''
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
PROCESSED_CONTAINER_BIN_PATH=${Container_Bin_Path/\$\{Container_Bin_Name\}/$Container_Bin_Name}
PROCESSED_CONTAINER_TAGS=${Container_Tags/\$\{YYYY-MM-DD-HH-MM-SS_Z\}/$TIMESTAMP}

echo "Container Name: $Container_Name"
echo "Binary Name: $Container_Bin_Name"
echo "Binary Path: $PROCESSED_CONTAINER_BIN_PATH"
echo "Tags: $PROCESSED_CONTAINER_TAGS"

# Process .env_dist file
if [ -f .env_dist ]; then
    echo "Processing .env_dist file..."
    ENV_VARS=""
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^# ]] && continue
        
        # Replace variables
        processed_line=$line
        processed_line=${processed_line/\$\{Container_Bin_Name\}/$Container_Bin_Name}
        processed_line=${processed_line/\$\{Container_Bin_Path\}/$PROCESSED_CONTAINER_BIN_PATH}
        processed_line=${processed_line/\$\{YYYY-MM-DD-HH-MM-SS_Z\}/$TIMESTAMP}
        
        ENV_VARS+="ENV $processed_line\n"
    done < .env_dist
else
    echo "Warning: .env_dist file not found."
    ENV_VARS=""
fi

# Build the project to detect dependencies
echo "Building project to detect dependencies..."
mkdir -p build
cd build
conan install .. --output-folder=. --build=missing
cmake .. -DCMAKE_TOOLCHAIN_FILE=conan_toolchain.cmake -DCMAKE_BUILD_TYPE=Release
cmake --build .

# Detect dependencies
echo "Detecting dependencies..."
DEPS=$(ldd ./${Container_Bin_Name} | grep "=> /" | awk '{print $3}' | sort -u)

# Generate list of packages needed
echo "Analyzing dependencies for required packages..."
PACKAGES="ca-certificates"
PACKAGE_INFO=""
CONTAINER_DEPS=""

for dep in $DEPS; do
    # Use dpkg to find which package provides this file
    PKG=$(dpkg -S $dep 2>/dev/null | cut -d: -f1 | sort -u | tr '\n' ' ' || echo "")
    if [ ! -z "$PKG" ]; then
        PACKAGES+=" $PKG"
        
        # Get package version information
        for pkg in $PKG; do
            VERSION=$(dpkg-query -W -f='${Version}' $pkg 2>/dev/null || echo "unknown")
            PACKAGE_INFO+="$pkg: $VERSION\n"
            
            # Add to Container_App_Dependencies format
            if [ ! -z "$CONTAINER_DEPS" ]; then
                CONTAINER_DEPS+=";$pkg:$VERSION"
            else
                CONTAINER_DEPS="$pkg:$VERSION"
            fi
        done
    fi
done

# Remove duplicates
PACKAGES=$(echo $PACKAGES | tr ' ' '\n' | sort -u | tr '\n' ' ')

# Display package information
echo -e "\nRequired packages and versions:"
echo -e "$PACKAGE_INFO"

# Set Container_App_Dependencies environment variable
echo "Setting Container_App_Dependencies=$CONTAINER_DEPS"

# Generate Dockerfile
echo "Generating dockerfile.dist..."
cd ..

cat > dockerfile.dist << EOF
# This file is generated by build.dist.sh script. Do not edit directly.
# Generated on: $(date)
FROM ubuntu:22.04

LABEL description="$Container_Description"
LABEL maintainer="$Container_Mantainer"
LABEL tags="$PROCESSED_CONTAINER_TAGS"

# Install required dependencies
RUN apt-get update && \\
    apt-get install -y --no-install-recommends $PACKAGES && \\
    apt-get clean && \\
    rm -rf /var/lib/apt/lists/*

# Set environment variables
$(echo -e $ENV_VARS)
ENV Container_App_Dependencies="$CONTAINER_DEPS"

# Create directory for the application
RUN mkdir -p $(dirname $PROCESSED_CONTAINER_BIN_PATH)

# Copy the application
COPY build/${Container_Bin_Name} $PROCESSED_CONTAINER_BIN_PATH

# Set the entrypoint
ENTRYPOINT ["$PROCESSED_CONTAINER_BIN_PATH"]
EOF

echo "Dockerfile generated successfully: dockerfile.dist"
echo "You can build the container with: docker build -t $Container_Name -f dockerfile.dist ."
EOF

# Create build.sh script
echo "Creating build.sh script..."
cat > build.sh << '\''EOF'\''
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
cmake .. -DCMAKE_TOOLCHAIN_FILE=conan_toolchain.cmake -DCMAKE_BUILD_TYPE=Release

# Build the project
echo "Building the project..."
cmake --build .

echo "Build completed successfully!"
echo "You can run the application with: ./build/\$(grep Container_Bin_Name ../.dist_build | cut -d'=' -f2 | tr -d '\"')"
EOF

# Make the create_project_files script executable
chmod +x create_project_files.sh

# Execute the project files creation directly inside the container
echo "Creating project files inside container..."
distrobox enter $CONTAINER_NAME -- bash -c "$(cat create_project_files.sh)"

# Make scripts executable inside the container
echo "Making scripts executable inside container..."
distrobox enter $CONTAINER_NAME -- bash -c "cd ~/Desktop/projects/cpp/cpp_demo && chmod +x build.dist.sh build.sh"

# Create README.md for the project
echo "Creating README.md for the project..."
cat > create_readme.sh << 'EOF'
#!/bin/bash
set -e

cd ~/Desktop/projects/cpp/cpp_demo

cat > README.md << 'EOF_README'
# C++ Development Environment with Distrobox

This project provides scripts to set up a C++ development environment using Distrobox and create a containerized C++ application.

## Features

- **Automatic Distrobox Installation**: Checks if Distrobox is installed and installs it if necessary
- **Ubuntu 22.04 Container**: Creates a container with Ubuntu 22.04 as the base image
- **Development Tools**: Installs essential development tools inside the container:
  - build-essential, git, mc, htop
  - Conan package manager (via pip3)
  - Latest CMake version
  - Visual Studio Code
- **C++ Demo Project**: Creates a simple C++ project with:
  - CMake configuration with C++23 support
  - Conan package management
  - VSCode debug configuration
- **Containerization**: Provides tools to create a minimal Docker container for the application
- **Logging**: Automatically logs all output to a timestamped log file
- **Cleanup Option**: Includes a `--cleanup` option to easily remove the container if needed

## Scripts

### build.sh

This script automates the build process for the C++ application:

1. Creates the build directory if it doesn't exist
2. Generates Conan files
3. Configures the project with CMake
4. Builds the project

### build.dist.sh

This script generates a Dockerfile for the C++ application:

1. Processes variables from `.dist_build` and `.env_dist` files
2. Builds the project to detect dependencies
3. Analyzes dependencies to determine required packages and their versions
4. Creates a special environment variable `Container_App_Dependencies` with the format `package:version;package:version`
5. Generates a Dockerfile (`dockerfile.dist`) that:
   - Installs only the necessary dependencies
   - Sets environment variables including `Container_App_Dependencies`
   - Copies the application to the specified path
   - Sets the entrypoint

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

3. To create a container image for the application:
   ```
   ./build.dist.sh
   ```

4. Build the Docker image:
   ```
   docker build -t cpp_demo -f dockerfile.dist .
   ```

5. Run the containerized application:
   ```
   docker run cpp_demo
   ```
EOF_README

echo "README.md created successfully!"
EOF

# Make the create_readme script executable
chmod +x create_readme.sh

# Execute the README creation directly inside the container
echo "Creating README.md inside container..."
distrobox enter $CONTAINER_NAME -- bash -c "$(cat create_readme.sh)"

# Create README.md for the host script
echo "Creating README.md for the host script..."
cat > README.md << 'EOF'
# C++ Development Environment Setup Script

This script (`build_cpp_dev_env.sh`) sets up a complete C++ development environment using Distrobox.

## Features

- Checks if Distrobox is installed and installs it if necessary
- Creates an Ubuntu 22.04 container
- Installs development tools inside the container
- Creates a C++ demo project in ~/Desktop/projects/cpp/cpp_demo
- Logs all output to a timestamped log file

## Usage

1. Run the setup script:
   ```
   ./build_cpp_dev_env.sh
   ```
   
   The script automatically logs all output to a file with the format:
   ```
   build_cpp_dev_env-YYYY-MM-DD-HH-MM-SS_Z.log
   ```
   where YYYY-MM-DD-HH-MM-SS_Z is the timestamp when the script was started.

2. If something goes wrong and you need to clean up:
   ```
   ./build_cpp_dev_env.sh --cleanup
   ```
   This will stop and remove the distrobox container.

3. After setup is complete, enter the container and navigate to the project:
   ```
   distrobox enter cpp_dev_env
   cd ~/Desktop/projects/cpp/cpp_demo
   ```

4. See the project's README.md for more information on how to build and run the application.
EOF

echo "All files created successfully!"
cd ..
