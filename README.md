# C++ Development Environment Setup Script

This script (`build_cpp_dev_env.sh`) sets up a complete C++ development environment using Distrobox with Docker support.

## Features

- Checks if Distrobox and Docker are installed and installs them if necessary
- Creates an Ubuntu 22.04 container with Docker support
- Installs development tools inside the container (including Docker)
- Creates a C++ demo project in ~/Desktop/projects/cpp/cpp_demo
- Logs all output to a timestamped log file
- Provides Docker integration for containerizing your C++ applications
- Configures Claude AI assistant with custom instructions for documentation maintenance
- Sets up automatic VSCode extension installation

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

3. To remove all log files:
   ```
   ./build_cpp_dev_env.sh --clean-logs
   ```
   This will delete all log files generated by the script.

4. To specify a custom container name:
   ```
   ./build_cpp_dev_env.sh --container-name my_cpp_dev_env
   ```
   This will create a container with the specified name instead of the default "cpp_dev_env".

5. You can combine multiple options:
   ```
   ./build_cpp_dev_env.sh --cleanup --clean-logs --container-name my_cpp_dev_env
   ```

6. After setup is complete, enter the container and navigate to the project:
   ```
   distrobox enter cpp_dev_env
   cd ~/Desktop/projects/cpp/cpp_demo
   ```

5. See the project's README.md for more information on how to build and run the application.

## Project Scripts

The following scripts are designed to be used within the Distrobox environment and in a C++ project folder (like cpp_demo) that is auto-generated by the run_build_dev_env.sh script:

- **build.sh**: Automates the C++ application build process within the project folder. It handles CMake configuration, building, and can be used to run the application.

- **build.dist.sh**: Used for building Docker containers from your C++ applications. This script creates a Dockerfile based on your project and builds a Docker image that contains your application.

- **helper.sh**: A utility script for building, running, and inspecting containers created from your C++ application. It provides convenient commands for managing the Docker containers.

- **create_cpp_project_from_template.sh**: Creates new C++ projects from templates. This script can be used to create new projects based on existing ones, making it easy to start new applications with a consistent structure.

- **inject_cline_custom_instructions.sh**: Configures Claude AI assistant with custom instructions for maintaining project documentation. This script sets up a "Memory Bank" pattern for documentation, ensuring consistent knowledge transfer and documentation maintenance.

To use these scripts, you must:
1. Be inside the Distrobox container (`distrobox enter cpp_dev_env`)
2. Navigate to a C++ project folder (e.g., `cd ~/Desktop/projects/cpp/cpp_demo`)
3. Run the desired script (e.g., `./build.sh`)

## Options for build_cpp_dev_env.sh

- `--cleanup`: Clean up the distrobox environment (stops and removes the container)
- `--clean-logs`: Remove all log files generated by the script
- `--container-name NAME`: Set the container name (default: cpp_dev_env)
- `--remove-old-container`: Force remove the old container if it exists with the same name
- `--clean-container-home`: Remove all files from container shared with host
- No options: Set up the C++ development environment with Docker support

## ChangeLog

A [ChangeLog.md](ChangeLog.md) file is maintained to track changes to the project. Check it for details about the latest updates and improvements.

## Using the Wrapper Script

The `run_build_dev_env.sh` script is a wrapper that runs the build script and captures its output to a log file:

```
./run_build_dev_env.sh --cpp [additional_args]
```

Options:
- `--cpp`: Required parameter to specify that you want to run the C++ environment setup script
- `--clear-logs`: Clear log files without creating a new log file
- Any other arguments are passed directly to the build_cpp_dev_env.sh script

Example:
```
./run_build_dev_env.sh --cpp --container-name custom_name
```
