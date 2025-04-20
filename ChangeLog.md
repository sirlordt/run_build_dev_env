# ChangeLog

## 2025-04-19 19:20:00 (America/Los_Angeles, UTC-7:00)

### Added
- New scripts for improved C++ development workflow:
  - Added build.sh script for automating the C++ application build process
  - Added build.dist.sh script for building Docker containers from C++ applications
  - Added create_cpp_project_from_template.sh for creating new projects from templates
  - Added helper.sh utility for building, running, and inspecting containers
- Enhanced Distrobox container management:
  - Added detection for running inside Distrobox container
  - Added Distrobox version checking (minimum 1.8.0 recommended)
  - Added support for project folder configuration
  - Added improved Docker socket handling

### Changed
- Updated .gitignore to include new script files:
  - Added create_cpp_project_from_template.sh
  - Added build.sh
  - Added build.dist.sh
  - Added helper.sh
- Enhanced build_cpp_dev_env.sh:
  - Improved Distrobox installation process
  - Enhanced cleanup functionality
  - Improved file creation and management
  - Better handling of Docker socket permissions

### Fixed
- Improved error handling and validation:
  - Added validation for empty tags to prevent Docker errors
  - Added safety checks for container operations
  - Fixed path handling in various scripts

## 2025-04-19 13:03:00 (America/Los_Angeles, UTC-7:00)

### Fixed
- Fixed debug.sh script issues:
  - Fixed here-document termination in build.dist.sh script
  - Fixed Docker tag format issues in build.dist.sh
  - Added validation for empty tags to prevent Docker errors
  - Improved variable substitution for timestamps

## 2025-04-19 09:25:00 (America/Los_Angeles, UTC-7:00)

### Added
- Docker support for the C++ development environment
  - Added functions to check and install Docker on the host system
  - Added Docker socket mounting from host to container
  - Added Docker installation inside the container
  - Added Docker group management for proper permissions
  - Added automatic Docker image building in build.dist.sh
- Improved log file management
  - Enhanced clean_logs function to skip the current log file
  - Added LOG_FILE export in run_build_dev_env.sh

### Changed
- Updated README.md with Docker support information
- Added Docker-related VSCode extensions
- Improved environment variable handling in build.dist.sh
- Enhanced Dockerfile generation with better dependency management
- Modified run_build_dev_env.sh to handle log files better

### Fixed
- Fixed container home directory cleanup safety checks
- Fixed variable expansion in .env_dist and .dist_build files
