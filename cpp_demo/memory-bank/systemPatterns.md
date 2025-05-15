# System Patterns: C++ Demo Application

## System Architecture

### Overall Architecture
The C++ Demo Application follows a simple, modular architecture designed to demonstrate best practices in C++ development and containerization:

```
┌─────────────────────────────────────────┐
│            C++ Demo Application         │
├─────────────────────────────────────────┤
│                                         │
│  ┌─────────────┐       ┌─────────────┐  │
│  │    Core     │       │ Command-line│  │
│  │ Application │◄─────►│   Parser    │  │
│  │    Logic    │       │             │  │
│  └─────────────┘       └─────────────┘  │
│                                         │
└─────────────────────────────────────────┘
```

### Build System Architecture
The build system follows modern CMake practices with Conan integration:

```
┌─────────────────────────────────────────────────────┐
│                  Build System                       │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────┐  │
│  │    CMake    │───►│    Conan    │───►│  Build  │  │
│  │ Configuration│    │ Dependencies│    │ Output  │  │
│  └─────────────┘    └─────────────┘    └─────────┘  │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### Containerization Architecture
The containerization process follows a dependency-based approach:

```
┌─────────────────────────────────────────────────────────────────┐
│                  Containerization Process                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────────────┐  │
│  │   Build     │───►│ Dependency  │───►│    Dockerfile       │  │
│  │ Application │    │  Analysis   │    │    Generation       │  │
│  └─────────────┘    └─────────────┘    └─────────────────────┘  │
│                                                │                │
│                                                ▼                │
│                                        ┌─────────────────────┐  │
│                                        │    Docker Image     │  │
│                                        │     Building        │  │
│                                        └─────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Key Technical Decisions

### 1. Modern C++ Standard (C++23)
- **Decision**: Use C++23 as the language standard.
- **Rationale**: Provides access to the latest language features and improvements.
- **Implementation**: Set in CMakeLists.txt with `set(CMAKE_CXX_STANDARD 23)`.

### 2. CMake as Build System
- **Decision**: Use CMake for build configuration.
- **Rationale**: Industry standard, cross-platform, and integrates well with modern C++ workflows.
- **Implementation**: Configured with proper project structure and modern CMake practices.

### 3. Conan for Dependency Management
- **Decision**: Use Conan for managing external dependencies.
- **Rationale**: Provides reproducible builds and simplifies dependency management.
- **Implementation**: Integrated with CMake through the CMakeDeps and CMakeToolchain generators.

### 4. Distrobox for Development Environment
- **Decision**: Use Distrobox to create a consistent development environment.
- **Rationale**: Ensures all developers work with the same tools and dependencies.
- **Implementation**: Configured to provide a complete C++ development environment.

### 5. Minimal Docker Containers
- **Decision**: Generate minimal Docker containers with only required dependencies.
- **Rationale**: Reduces container size and potential security vulnerabilities.
- **Implementation**: Dependency analysis in build.dist.sh to determine required packages.

### 6. Environment Variable Management
- **Decision**: Use .env_dist and .dist_build for environment configuration.
- **Rationale**: Separates configuration from code and allows for different deployment scenarios.
- **Implementation**: Variables processed and expanded during the build process.

### 7. VSCode Debug Configuration
- **Decision**: Implement intelligent launch.json processing during project creation.
- **Rationale**: Ensures proper debugging configuration for each project with minimal manual intervention.
- **Implementation**: Automatically configures program paths in launch.json based on project name.

## Design Patterns

### 1. Builder Pattern
- **Usage**: The build.sh and build.dist.sh scripts implement a builder pattern.
- **Implementation**: Sequential steps to build the application and container.

### 2. Factory Pattern
- **Usage**: The CMake configuration acts as a factory for build configurations.
- **Implementation**: Creates different build configurations based on environment.

### 3. Dependency Injection
- **Usage**: External dependencies are injected through Conan.
- **Implementation**: Dependencies declared in conanfile.txt and injected into the build.

## Critical Implementation Paths

### 1. Build Process
```
1. Create build directory
2. Generate Conan files
3. Configure with CMake
4. Build the project
```

### 2. Containerization Process
```
1. Load variables from configuration files
2. Process environment variables
3. Build application locally
4. Analyze dependencies
5. Generate Dockerfile
6. Build and tag Docker image
```

### 3. Application Execution
```
1. Initialize application
2. Parse command-line arguments
3. Execute main functionality
4. Return exit code
```

## Component Relationships

### Build System Components
- **CMakeLists.txt**: Defines project structure and build configuration
- **conanfile.txt**: Defines external dependencies
- **build.sh**: Automates the build process

### Containerization Components
- **.dist_build**: Defines container configuration
- **.env_dist**: Defines environment variables for the container
- **build.dist.sh**: Automates the containerization process

### Application Components
- **main.cpp**: Entry point and main application logic
- **Command-line Argument Handling**: Processes user inputs
