#!/bin/bash

# run_build_dev_env.sh
# Wrapper script to run build scripts and capture their output

# Check if --cpp parameter is provided
if [ "$1" = "--cpp" ]; then
    shift  # Remove --cpp from the arguments
    SCRIPT="build_cpp_dev_env.sh"
else
    echo "Error: Missing parameter. Usage: ./run_build_dev_env.sh --cpp [additional_args]"
    exit 1
fi

# Generate timestamp for log file
TIMESTAMP=$(date "+%Y-%m-%d-%H-%M-%S_%z")
LOG_FILE="${SCRIPT%.sh}-${TIMESTAMP}.log"

# Run the build script and capture output to both console and log file
./$SCRIPT "$@" 2>&1 | tee "$LOG_FILE"

# Check if the build script was successful
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo "Build script completed successfully. Log saved to $LOG_FILE"
else
    echo "Build script failed. Check $LOG_FILE for details."
fi
