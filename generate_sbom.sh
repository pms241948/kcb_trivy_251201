#!/bin/bash

# =============================================================================
# Script Name: generate_sbom.sh
# Description: Generates SBOM for a specified target (File or Directory) using Trivy.
#              - If a FILE is provided, generates SBOM for that file.
#              - If a DIRECTORY is provided, recursively finds all files and generates SBOMs.
# Usage: ./generate_sbom.sh <TARGET_PATH>
# =============================================================================

# 1. Input Validation
if [ -z "$1" ]; then
  echo "Error: Target path is required."
  echo "Usage: $0 <TARGET_PATH>"
  exit 1
fi

TARGET_INPUT="$1"

# Convert to absolute path
# (Simple conversion, assumes standard linux-like environment or Git Bash)
if [[ "$TARGET_INPUT" != /* ]] && [[ "$TARGET_INPUT" != ?:* ]]; then
    TARGET_INPUT="$(pwd)/$TARGET_INPUT"
fi

# 2. Configuration
DATE_STR=$(date +"%Y%m%d")
if [ -d "/app/trivy-sbom" ]; then
    BASE_OUTPUT_DIR="/app/trivy-sbom/output"
else
    BASE_OUTPUT_DIR="$(pwd)/output"
    echo "  [Info] /app/trivy-sbom not found. Using local output: $BASE_OUTPUT_DIR"
fi
TODAY_OUTPUT_DIR="$BASE_OUTPUT_DIR/$DATE_STR"
CACHE_DIR="$(pwd)/trivy-cache"

# Create directories
mkdir -p "$TODAY_OUTPUT_DIR"
mkdir -p "$CACHE_DIR"

# Check Docker
if ! docker info > /dev/null 2>&1; then
  echo "Error: Docker is not running or not accessible."
  exit 1
fi

# Function to scan a single file
scan_file() {
    local FILE_PATH="$1"
    local FILE_NAME=$(basename "$FILE_PATH")
    local FILE_DIR=$(dirname "$FILE_PATH")
    
    # Output Filename: YYYYMMDD_FILENAME_SBOM.json
    local OUTPUT_FILENAME="${DATE_STR}_${FILE_NAME}_SBOM.json"
    local OUTPUT_FILE_PATH="$TODAY_OUTPUT_DIR/$OUTPUT_FILENAME"

    echo "--------------------------------------------------"
    echo "Scanning: $FILE_NAME"
    
    # We mount the directory containing the file to /scan_target
    # and tell Trivy to scan /scan_target/filename
    
    # Determine scan mode based on file type
    if [[ "$FILE_NAME" == *.tar ]]; then
        # Check if it looks like a Docker image (contains manifest.json at root)
        # Using tar -tf to list files. 
        # We redirect stderr to null to hide errors if not a valid tar.
        if tar -tf "$FILE_PATH" 2>/dev/null | grep -q "^manifest.json$"; then
             echo "  [!] Type: Docker Image Archive (manifest.json found)"
             ARG_TYPE="image"
             INPUT_ARG="--input /scan_target/$FILE_NAME"
             TARGET_ARG=""
        else
             echo "  [!] Type: Regular Tar Archive (Treated as filesystem)"
             ARG_TYPE="filesystem"
             INPUT_ARG=""
             TARGET_ARG="/scan_target/$FILE_NAME"
        fi
    else
        echo "  [!] Type: File/Directory"
        ARG_TYPE="filesystem"
        INPUT_ARG=""
        TARGET_ARG="/scan_target/$FILE_NAME"
    fi

    docker run --rm \
      -v "$FILE_DIR":/scan_target:ro \
      -v "$TODAY_OUTPUT_DIR":/output \
      -v "$CACHE_DIR":/root/.cache/trivy \
      aquasec/trivy:latest $ARG_TYPE \
      --format cyclonedx \
      --offline-scan \
      --skip-db-update \
      --output "/output/$OUTPUT_FILENAME" \
      $INPUT_ARG $TARGET_ARG

    local EXIT_CODE=$?
    
    if [ $EXIT_CODE -eq 0 ]; then
        echo "SUCCESS: $OUTPUT_FILE_PATH"
    else
        echo "FAILED: $FILE_NAME (Exit Code: $EXIT_CODE)"
    fi
}

echo "=========================================="
echo "Starting SBOM Generation Batch"
echo "Target: $TARGET_INPUT"
echo "Output: $TODAY_OUTPUT_DIR"
echo "Date:   $DATE_STR"
echo "=========================================="

if [ -f "$TARGET_INPUT" ]; then
    # Case 1: Single File
    echo "Mode: Single File"
    scan_file "$TARGET_INPUT"

elif [ -d "$TARGET_INPUT" ]; then
    # Case 2: Directory (Recursive)
    echo "Mode: Directory (Recursive)"
    
    # Use find to list all files. 
    # -print0 and read -d '' handles filenames with spaces correctly.
    find "$TARGET_INPUT" -type f -print0 | while IFS= read -r -d '' file; do
        scan_file "$file"
    done

else
    echo "Error: Target '$TARGET_INPUT' is not a valid file or directory."
    exit 1
fi

echo "=========================================="
echo "Batch Processing Completed."
echo "=========================================="

