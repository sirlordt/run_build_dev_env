# Technical Context: C++ Demo Application

## Technologies Used

### Core Technologies

| Technology | Version | Purpose |
|------------|---------|---------|
| C++ | C++23 | Primary programming language |
| CMake | 3.28.3 | Build system |
| Conan | Latest | Package manager |
| Distrobox | Latest | Development environment containerization |
| Docker | Latest | Application containerization |
| Ubuntu | 22.04 | Base OS for containers |

### Dependencies

| Dependency | Version | Purpose |
|------------|---------|---------|
| fmt | 9.1.0 | Modern formatting library for C++ |

### Development Tools

| Tool | Purpose |
|------|---------|
| Visual Studio Code | Primary IDE |
| GCC | C++ compiler |
| Git | Version control |
| Midnight Commander (mc) | File management |
| htop | System monitoring |
| nano | Text editing |

## Development Setup

### Environment Setup

The development environment is set up using Distrobox, which provides a containerized environment with all necessary tools pre-installed. This ensures consistency across different development machines.

#### Key Components:
- **build-essential**: Provides essential build tools
- **CMake**: Modern build system
- **Conan**: C++ package manager
- **Git**: Version control
- **VSCode**: IDE with C++ extensions
- **nano**: Simple text editor for quick edits

#### VSCode Configuration:
- **Extensions**: C/C++, CMake Tools, Docker
- **Debugging**: Configured for C++ applications
- **Password Store**: Set to "basic" to prevent credential prompts
  ```json
  {
    "password-store": "basic"
  }
  ```
- **Git Configuration**: Disabled Git features in VSCode
  ```json
  {
    "git.enabled": false,
    "git.useCredentialStore": false,
    "git.autofetch": false,
    "git.confirmSync": false
  }
  ```

#### Shell Configuration:
- **Custom Prompt**: Configured for better visibility in Distrobox container
  ```bash
  # Custom prompt for Distrobox container
  export CONTAINER_ID=1
  export PS1="(\h) \u@\[\e[1;32m\]$CONTAINER_ID\[\e[0m\]:\w\$ "
  ```
- **Login Shell Setup**: Ensures .bashrc is sourced from .bash_profile
  ```bash
  [[ -f ~/.bashrc ]] && source ~/.bashrc
  ```

### Build Configuration

The build configuration is managed through CMake with the following key settings:

```cmake
cmake_minimum_required(VERSION 3.15)
project(cpp_demo VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
```

### Dependency Management

Dependencies are managed through Conan, with the following configuration in `conanfile.txt`:

```
[requires]
fmt/9.1.0

[generators]
CMakeDeps
CMakeToolchain
```

### Build Process

The build process is automated through the `build.sh` script, which:
1. Creates the build directory
2. Generates Conan files
3. Configures the project with CMake
4. Builds the project

### Containerization

The containerization process is managed through the `build.dist.sh` script, which:
1. Processes variables from configuration files
2. Builds the project to detect dependencies
3. Generates a Dockerfile with minimal dependencies
4. Builds and tags the Docker image

## Technical Constraints

### Language Constraints
- Must adhere to C++23 standard
- Must compile with GCC compiler

### Build System Constraints
- Must use CMake 3.15 or higher
- Must support Conan integration

### Dependency Constraints
- External dependencies must be managed through Conan
- Dependencies should be pinned to specific versions

### Containerization Constraints
- Docker containers must be based on Ubuntu 22.04
- Containers must include only necessary dependencies
- Container images must be properly tagged

## Tool Usage Patterns

### CMake Usage

```cmake
# Load binary name from .dist_build
file(STRINGS ".dist_build" DIST_BUILD_CONTENT)
foreach(LINE ${DIST_BUILD_CONTENT})
    if(LINE MATCHES "^Container_Bin_Name=\"([^\"]+)\"$")
        set(APP_BIN_NAME ${CMAKE_MATCH_1})
    endif()
endforeach()

# Find dependencies with Conan
if(EXISTS "${CMAKE_BINARY_DIR}/conan_toolchain.cmake")
    include("${CMAKE_BINARY_DIR}/conan_toolchain.cmake")
endif()

add_executable(${APP_BIN_NAME} main.cpp)
```

### Conan Usage

```bash
# Generate Conan files
conan install .. --output-folder=. --build=missing

# Configure with CMake using Conan toolchain
cmake .. -DCMAKE_TOOLCHAIN_FILE=conan_toolchain.cmake -DCMAKE_BUILD_TYPE=Debug
```

### Docker Usage

```bash
# Build Docker image
docker build -t "$Container_Name" -f dockerfile.dist .

# Tag Docker image
docker tag "$Container_Name" "$Container_Name:$tag"
```

## Development Workflow

### Local Development

1. Clone the repository
2. Run `build.sh` to build the application
3. Execute the application from the build directory
4. Make changes to the code
5. Rebuild with `build.sh`

### Containerization Workflow

1. Update configuration in `.dist_build` and `.env_dist`
2. Run `build.dist.sh` to create a Docker container
3. Test the containerized application
4. Push the container to a registry if needed

## Deployment Considerations

### Container Configuration

The container is configured with:
- A non-root user (`cpp_demo`)
- Minimal dependencies
- Environment variables from `.env_dist`
- Proper permissions for application directories

### Runtime Environment

The application expects:
- Access to command-line arguments
- Proper environment variables set
- Appropriate permissions for file access

### Versioning

Container images are tagged with:
- `latest` tag
- Custom tags specified in `.dist_build`
- Timestamp-based tags for versioning
