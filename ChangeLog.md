# ChangeLog

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
