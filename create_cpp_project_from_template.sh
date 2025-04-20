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

mkdir -p "$NEW_PROJECT_PATH"
mkdir -p "$NEW_PROJECT_PATH/build"

echo "Creating project '$NEW_PROJECT_NAME' from template '$TEMPLATE_FOLDER'..." | tee "$LOG_FILE"

# Copy files excluding build directory
rsync -av --exclude='build/' "$TEMPLATE_PATH/" "$NEW_PROJECT_PATH/" | tee -a "$LOG_FILE"

# Replace occurrences
find "$NEW_PROJECT_PATH" -type f | while read -r file; do
  if grep -q "$TEMPLATE_NAME" "$file"; then
    grep -n -H "$TEMPLATE_NAME" "$file" | while IFS=: read -r filepath linenum linecontent; do
      colnum=$(echo "$linecontent" | grep -b -o "$TEMPLATE_NAME" | cut -d: -f1)
      ext="${file##*.}"
      result="Success"
      if [[ "$ext" =~ ^(cpp|hpp|c|h)$ ]]; then
        result="Success. [WARNING Source code file changed]"
      fi
      printf "* Operation: Replace\n From: [%s]\n To: [%s]\n  Line: %s\n  Column: %s\n  File: %s\n Result: %s\n" \
        "$TEMPLATE_NAME" "$NEW_PROJECT_NAME" "$linenum" "$colnum" "${file#$SCRIPT_DIR/}" "$result" | tee -a "$LOG_FILE"
    done
    sed -i "s/$TEMPLATE_NAME/$NEW_PROJECT_NAME/g" "$file"
  fi
done

echo "Project '$NEW_PROJECT_NAME' created successfully!" | tee -a "$LOG_FILE"
