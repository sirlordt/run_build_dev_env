# Active Context: C++ Demo Application

## Current Work Focus

The current focus is on initializing the memory bank for the C++ Demo Application. This involves creating comprehensive documentation to capture the project's purpose, architecture, technical details, and current status.

### Memory Bank Initialization
- Creating core documentation files to establish project context
- Documenting system architecture and patterns
- Capturing technical details and constraints
- Establishing a baseline for future development

## Recent Changes

### Environment Enhancements
- Added new script **inject_cline_custom_instructions.sh**:
  - Creates custom instructions for Claude AI assistant
  - Configures Claude to maintain a "Memory Bank" of project documentation
  - Sets up a structured approach to documentation with core files
  - Defines workflows for Plan Mode and Act Mode
  - Establishes documentation update processes
  - Uses SQLite to store configuration in VSCode's database

- Enhanced build_cpp_dev_env.sh:
  - Added `nano`, `sqlite3`, and `jq` to the list of installed packages
  - Added code to create and run inject_cline_custom_instructions.sh in the container
  - Added CONTAINER_NAME to system-wide environment variables in /etc/environment
  - Added VSCode password-store configuration to use basic authentication
  - Added VSCode Git configuration to disable Git features in the container:
    - Disabled Git integration in VSCode
    - Disabled Git credential store
    - Disabled Git auto-fetch
    - Disabled Git sync confirmation prompts
    - Added `"extensions.ignoreRecommendations": false` to allow extension recommendations
  - Added custom prompt configuration for Distrobox container:
    - Ensures .bashrc is sourced from .bash_profile for login shells
    - Adds a custom prompt with container name in bright green
    - Sets PS1 with format "(\h) \u@\[\e[1;32m\]$CONTAINER_NAME\[\e[0m\]:\w\$"
    - Applies the new prompt immediately

- Enhanced VSCode integration:
  - Improved tasks.json to use build.sh script for building
  - Added auto-install extensions task that runs on folder open
  - Improved launch.json creation with better binary name detection
  - Added automatic VSCode extension installation

### Memory Bank Creation
- Created memory-bank directory
- Initialized core documentation files:
  - projectbrief.md
  - productContext.md
  - systemPatterns.md
  - techContext.md
  - activeContext.md (this file)
  - progress.md

## Next Steps

### Short-term Tasks
1. Complete memory bank initialization
2. Review existing code for potential improvements
3. Consider adding more comprehensive examples of C++ features
4. Explore adding unit tests to the project

### Medium-term Tasks
1. Enhance the demo application with more advanced C++ features
2. Add examples of using the fmt library
3. Improve error handling in the application
4. Add more comprehensive documentation for developers

### Long-term Tasks
1. Implement CI/CD pipeline examples
2. Add more advanced containerization techniques
3. Demonstrate integration with common C++ frameworks
4. Create examples of multi-threading and concurrency

## Active Decisions and Considerations

### AI Assistant Integration
- **Decision**: Integrate Claude AI assistant with custom instructions for documentation
- **Rationale**: Ensures consistent documentation maintenance and knowledge transfer
- **Status**: Implemented

### Documentation Strategy
- **Decision**: Create comprehensive memory bank documentation
- **Rationale**: Establish clear context for the project to facilitate future development
- **Status**: In progress

### Code Organization
- **Decision**: Maintain the current simple structure for the demo
- **Rationale**: Keeps the focus on demonstrating the environment setup rather than complex application logic
- **Status**: Accepted

### Dependency Management
- **Decision**: Use Conan for dependency management
- **Rationale**: Provides a modern, reliable way to manage C++ dependencies
- **Status**: Implemented

### Containerization Approach
- **Decision**: Generate minimal Docker containers with only required dependencies
- **Rationale**: Reduces container size and potential security vulnerabilities
- **Status**: Implemented

## Important Patterns and Preferences

### Code Style
- Use modern C++ idioms and features
- Follow consistent naming conventions
- Prefer explicit over implicit constructs

### Build Process
- Use CMake for build configuration
- Integrate Conan for dependency management
- Automate build steps with scripts

### Documentation
- Maintain comprehensive documentation in the memory bank
- Document key decisions and their rationales
- Keep documentation up-to-date with code changes
- Store useful commands and references in git_commands.md

### Containerization
- Use minimal base images
- Include only necessary dependencies
- Configure proper permissions and non-root users

## Learnings and Project Insights

### Key Insights
- Distrobox provides an effective way to standardize C++ development environments
- Conan simplifies dependency management for C++ projects
- CMake's flexibility allows for complex build configurations
- Docker containerization can be optimized for C++ applications

### Challenges
- Ensuring consistent behavior between development and production environments
- Managing C++ dependencies effectively
- Optimizing Docker containers for C++ applications

### Opportunities
- Expand the demo to showcase more C++ features
- Demonstrate integration with more external libraries
- Add examples of modern C++ patterns and practices
