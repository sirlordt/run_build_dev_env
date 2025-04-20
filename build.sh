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
