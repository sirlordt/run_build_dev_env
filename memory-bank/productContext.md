# Product Context: C++ Development Environment Setup

## Why This Project Exists

The C++ Development Environment Setup project was created to address several common challenges faced by C++ developers:

1. **Environment Inconsistency**: C++ development environments can vary significantly across different systems, leading to "works on my machine" problems. This project provides a consistent, containerized environment that works the same way regardless of the host system.

2. **Complex Setup Process**: Setting up a complete C++ development environment with all necessary tools (compiler, build system, package manager, IDE, etc.) is often time-consuming and error-prone. This project automates the entire process with a single command.

3. **Docker Integration Challenges**: While containerization is valuable for C++ applications, setting up Docker within development environments and creating optimized containers for C++ applications can be complex. This project streamlines the Docker integration process.

4. **Project Bootstrapping**: Starting new C++ projects with proper structure and configuration is often tedious. This project provides templates and automation to quickly bootstrap new projects.

## Problems It Solves

1. **Development Environment Setup**:
   - Eliminates the need to manually install and configure C++ development tools
   - Ensures all developers use the same versions of tools and libraries
   - Isolates the development environment from the host system to prevent conflicts

2. **Docker Integration**:
   - Provides Docker support within the development container
   - Automates the creation of optimized Docker images for C++ applications
   - Handles proper versioning and tagging of Docker images

3. **Project Management**:
   - Automates the creation of new C++ projects with proper structure
   - Provides scripts for common development tasks (build, run, containerize)
   - Ensures consistent project configuration across the team

4. **Dependency Management**:
   - Integrates Conan for modern C++ package management
   - Automates the resolution and installation of dependencies
   - Ensures consistent dependency versions across different environments

## How It Should Work

The system is designed to work through a series of shell scripts that automate different aspects of the C++ development workflow:

1. **Environment Setup** (`build_cpp_dev_env.sh`):
   - Checks for and installs prerequisites (Distrobox, Docker)
   - Creates an Ubuntu 22.04 container with all necessary development tools
   - Mounts host directories for seamless file access
   - Sets up Docker support within the container

2. **Project Building** (`build.sh`):
   - Automates the C++ application build process
   - Handles CMake configuration and building
   - Manages Conan dependencies

3. **Containerization** (`build.dist.sh`):
   - Creates optimized Docker images from C++ applications
   - Handles environment variables and configuration
   - Supports proper versioning and tagging

4. **Project Creation** (`create_cpp_project_from_template.sh`):
   - Creates new C++ projects from templates
   - Handles project naming and configuration
   - Sets up proper project structure

5. **Utility Functions** (`helper.sh`):
   - Provides utilities for building, running, and inspecting containers
   - Simplifies common development tasks

## User Experience Goals

1. **Simplicity**:
   - Users should be able to set up the entire environment with a single command
   - Common tasks should be automated through simple script invocations
   - The system should handle complexity behind the scenes

2. **Transparency**:
   - Users should understand what the scripts are doing
   - Logs should provide clear information about each step
   - Error messages should be informative and actionable

3. **Flexibility**:
   - Users should be able to customize the environment as needed
   - The system should support different project configurations
   - Scripts should be adaptable to different requirements

4. **Productivity**:
   - The environment should enable developers to start coding quickly
   - Tools should be pre-configured for optimal development experience
   - Common tasks should be streamlined to reduce friction

5. **Learning**:
   - The system should demonstrate best practices for C++ development
   - Scripts should be well-documented and serve as examples
   - The environment should introduce developers to modern tools and techniques
