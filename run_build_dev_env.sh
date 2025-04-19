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


# Check if --clear-logs is being passed
#if [[ "$*" == *"--clear-logs"* ]]; then
    # Don't create a log file when clearing logs
#    echo "Running in clear-logs mode, no log file will be created."
#    ./$SCRIPT "$@"
    
    # Check if the build script was successful
#    if [ $? -eq 0 ]; then
#        echo "Log files cleared successfully."
#    else
#        echo "Failed to clear log files."
#    fi
#else
    # Generate timestamp for log file
    TIMESTAMP=$(date "+%Y-%m-%d-%H-%M-%S_%z")
    LOG_FILE="${SCRIPT%.sh}-${TIMESTAMP}.log"
    export LOG_FILE

    # Run the build script and capture output to both console and log file
    ./$SCRIPT "$@" 2>&1 | tee "$LOG_FILE"

    # Check if the build script was successful
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        echo "Build script completed successfully. Log saved to $LOG_FILE"
    else
        echo "Build script failed. Check $LOG_FILE for details."
    fi
#fi
