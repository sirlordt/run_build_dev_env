#!/usr/bin/env bash

# create_cpp_project_from_template.sh
# Creates a new C++ project from a template.

set -e

show_usage() {
  echo "Usage: $0 --template TEMPLATE_FOLDER [--template_name TEMPLATE_NAME] --name NEW_PROJECT_NAME"
}

# Variables
TEMPLATE_FOLDER=""
TEMPLATE_NAME=""
NEW_PROJECT_NAME=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --template)
      TEMPLATE_FOLDER="$2"
      shift 2
      ;;
    --template_name)
      TEMPLATE_NAME="$2"
      shift 2
      ;;
    --name)
      NEW_PROJECT_NAME="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1"
      show_usage
      exit 1
      ;;
  esac
done

# Check mandatory parameters
if [[ -z "$TEMPLATE_FOLDER" || -z "$NEW_PROJECT_NAME" ]]; then
  echo "Error: --template and --name parameters are required."
  show_usage
  exit 1
fi

if [[ -z "$TEMPLATE_NAME" ]]; then
  TEMPLATE_NAME="$TEMPLATE_FOLDER"
fi

SCRIPT_DIR="$(pwd)"
TEMPLATE_PATH="$SCRIPT_DIR/$TEMPLATE_FOLDER"
NEW_PROJECT_PATH="$SCRIPT_DIR/$NEW_PROJECT_NAME"
LOG_FILE="$NEW_PROJECT_PATH/project_creation.log"
TEMP_LOG_FILE="/tmp/project_creation_temp.log"

# Verify template folder
if [[ ! -d "$TEMPLATE_PATH" ]]; then
  echo "Error: Template folder '$TEMPLATE_PATH' does not exist."
  exit 1
fi

# Verify if new project folder exists
if [[ -d "$NEW_PROJECT_PATH" ]]; then
  echo "Error: The project folder '$NEW_PROJECT_NAME' already exists."
  exit 1
fi

# Function to log operations
log_operation() {
  local operation=$1
  local from=$2
  local to=$3
  local file=$4
  local result=$5

  printf " * Operation: %s\n    From: %s\n    To: %s\n" "$operation" "$from" "$to" | tee -a "$TEMP_LOG_FILE"
  if [[ -n "$file" ]]; then
    printf "    File: %s\n" "$file" | tee -a "$TEMP_LOG_FILE"
  fi
  printf "    Result: %s\n\n" "$result" | tee -a "$TEMP_LOG_FILE"
}

# Initialize temporary log file
> "$TEMP_LOG_FILE"

echo "Creating project '$NEW_PROJECT_NAME' from template '$TEMPLATE_FOLDER'..." | tee "$TEMP_LOG_FILE"

# Create project directory
mkdir -p "$NEW_PROJECT_PATH"
log_operation "Create" "$TEMPLATE_FOLDER" "$NEW_PROJECT_NAME" "" "Success"

# Create build directory
mkdir -p "$NEW_PROJECT_PATH/build"
log_operation "Create" "$TEMPLATE_FOLDER/build" "$NEW_PROJECT_NAME/build" "" "Success"

# Copy files excluding build directory
echo "Copying files from template..." | tee -a "$TEMP_LOG_FILE"

# Instead of using rsync directly, find files and copy them individually to log each operation
find "$TEMPLATE_PATH" -type f -not -path "*/build/*" | while read -r src_file; do
  rel_path="${src_file#$TEMPLATE_PATH/}"
  dest_file="$NEW_PROJECT_PATH/$rel_path"
  
  # Create destination directory if it doesn't exist
  dest_dir="$(dirname "$dest_file")"
  if [[ ! -d "$dest_dir" ]]; then
    mkdir -p "$dest_dir"
    rel_src_dir="${src_file%/*}"
    rel_src_dir="${rel_src_dir#$TEMPLATE_PATH/}"
    dest_dir_rel="${dest_dir#$SCRIPT_DIR/}"
    src_dir_rel="$TEMPLATE_FOLDER/$rel_src_dir"
    log_operation "Create" "$src_dir_rel" "$dest_dir_rel" "" "Success"
  fi
  
  # Copy the file
  cp "$src_file" "$dest_file"
  file_name="$(basename "$src_file")"
  rel_src_dir="$(dirname "$rel_path")"
  if [[ "$rel_src_dir" == "." ]]; then
    rel_src_dir=""
  else
    rel_src_dir="$rel_src_dir/"
  fi
  rel_src_path="$TEMPLATE_FOLDER/$rel_src_dir"
  rel_dest_path="$NEW_PROJECT_NAME/$rel_src_dir"
  log_operation "Copy" "$rel_src_path" "$rel_dest_path" "$file_name" "Success"
done

# Replace occurrences
echo "Replacing template name occurrences..." | tee -a "$TEMP_LOG_FILE"
find "$NEW_PROJECT_PATH" -type f | while read -r file; do
  if grep -q "$TEMPLATE_NAME" "$file"; then
    grep -n -H "$TEMPLATE_NAME" "$file" | while IFS=: read -r filepath linenum linecontent; do
      colnum=$(echo "$linecontent" | grep -b -o "$TEMPLATE_NAME" | cut -d: -f1)
      ext="${file##*.}"
      result="Success"
      if [[ "$ext" =~ ^(cpp|hpp|c|h)$ ]]; then
        result="Success. [WARNING Source code file changed]"
      fi
      
      # Log replacement in the new format
      printf " * Operation: Replace\n    From: %s\n    To: %s\n    File: %s\n    Line: %s\n    Column: %s\n    Result: %s\n\n" \
        "$TEMPLATE_NAME" "$NEW_PROJECT_NAME" "${file#$SCRIPT_DIR/}" "$linenum" "$colnum" "$result" | tee -a "$TEMP_LOG_FILE"
    done
    sed -i "s/$TEMPLATE_NAME/$NEW_PROJECT_NAME/g" "$file"
  fi
done

echo "Project '$NEW_PROJECT_NAME' created successfully!" | tee -a "$TEMP_LOG_FILE"

# Copy the log file to the project directory
mkdir -p "$(dirname "$LOG_FILE")"
cp "$TEMP_LOG_FILE" "$LOG_FILE"
