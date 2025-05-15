# ChangeLog

## 2025-05-14 23:15:00 (America/Los_Angeles, UTC-7:00)

### Added
- New script for AI assistant integration:
  - Added inject_cline_custom_instructions.sh for configuring Claude AI assistant
  - Implemented Memory Bank pattern for documentation maintenance
  - Set up structured approach to project documentation
  - Defined workflows for Plan Mode and Act Mode
  - Added SQLite integration for storing configuration in VSCode's database
- Enhanced VSCode integration:
  - Added auto-install extensions task that runs on folder open
  - Added Claude AI extension to recommended extensions
  - Improved launch.json creation with better binary name detection

### Changed
- Enhanced build_cpp_dev_env.sh:
  - Added `sqlite3` and `jq` to the list of installed packages
  - Added code to create and run inject_cline_custom_instructions.sh in the container
  - Added CONTAINER_NAME to system-wide environment variables in /etc/environment
  - Improved tasks.json to use build.sh script for building
  - Updated custom prompt to use container name instead of container ID
- Updated .gitignore:
  - Added inject_cline_custom_instructions.sh to the list of tracked files

## 2025-05-14 19:57:36 (America/Los_Angeles, UTC-7:00)

### Changed
- Updated memory-bank documentation:
  - Updated custom prompt configuration to use CONTAINER_ID instead of hostname
  - Modified PS1 format in all documentation files
  - Updated activeContext.md, techContext.md and progress.md in both directories
  - Ensured consistent documentation across all memory-bank files

## 2025-05-14 19:44:34 (America/Los_Angeles, UTC-7:00)

### Added
- Added git_commands.md with reference for git commands
- Added documentation for custom prompt configuration

### Changed
- Updated memory-bank documentation:
  - Documented custom prompt configuration for Distrobox container
  - Updated activeContext.md, techContext.md and progress.md files
  - Added details about .bashrc and .bash_profile configuration
  - Included prompt format with hostname in bright green
- Updated .gitignore to track memory-bank directories

## 2025-05-14 19:09:30 (America/Los_Angeles, UTC-7:00)

### Added
- Created git_commands.md with references of useful Git commands
- Added documentation for the git --no-pager diff --staged command

### Changed
- Updated memory-bank documentation:
  - Documented VSCode Git configuration
  - Documented disabling of Git features in VSCode within the container
  - Updated activeContext.md, techContext.md and progress.md in both directories

## 2025-05-14 18:30:47 (America/Los_Angeles, UTC-7:00)

### Added
- Enhanced VSCode integration:
  - Added VSCode password-store configuration to prevent credential prompts
  - Enhanced launch.json processing in create_cpp_project_from_template.sh
  - Added proper commenting and project-specific program paths in launch.json

### Changed
- Added nano to installed packages for better text editing options
- Updated memory-bank documentation to reflect these changes

## 2025-04-19 20:02:00 (America/Los_Angeles, UTC-7:00)

### Changed
- Enhanced create_cpp_project_from_template.sh:
  - Improved logging format for all operations (Create, Copy, Replace)
  - Added temporary log file approach to prevent log corruption during replacements
  - Modified Copy operations to show directory paths in From/To fields and filename in File field
- Updated documentation:
  - Added "Project Scripts" section to README.md and README_ES.md
  - Clarified that build.sh, build.dist.sh, and helper.sh are meant to be used within Distrobox
  - Explained that scripts should be used in C++ project folders like cpp_demo
  - Added usage instructions for all project scripts

### Fixed
- Fixed logging issues in create_cpp_project_from_template.sh:
  - Fixed incorrect From/To paths in Create operations
  - Fixed incorrect From/To paths in Copy operations
  - Fixed log file corruption during template name replacements
  - Ensured consistent formatting across all operation types

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
