#!/bin/bash

# Exit on error, undefined variable, or pipe failure
set -euo pipefail

# Get current date and time
NOW=$(date +%Y-%m-%d-%H-%M-%S)

# Specify the directory containing the files
FILES_DIR="/mnt/RussNAS/plex/plex-media/Library/Drone Videos/To Process"

# Determine the script's directory
SCRIPT_DIR=$(dirname "$0")

# Set the log file location in the script's directory
LOG_FILE="${SCRIPT_DIR}/organize_dji_files.log"

# Function to log messages
log() {
    local level=$1
    local message=$2
    echo "$(date +%Y-%m-%d-%H-%M-%S) - ${level} - ${message}" | tee -a ${LOG_FILE} >&2
}

# Ensure the directory exists
if [ ! -d "$FILES_DIR" ]; then
    log "ERROR" "Directory $FILES_DIR does not exist. Exiting." 
    exit 1
fi

# Check if there are any files to process
if [ "$(find "$FILES_DIR" -type f | wc -l)" -eq 0 ]; then
    log "INFO" "No files to process in $FILES_DIR."
else
    find "$FILES_DIR" -type f | while read -r file; do
        filename=$(basename -- "$file")

        if [[ "$filename" =~ DJI_([0-9]{8})([0-9]{6})_([0-9]{4})_D\.MP4 ]]; then
            year="${BASH_REMATCH[1]:0:4}"
            month="${BASH_REMATCH[1]:4:2}"
            day="${BASH_REMATCH[1]:6:2}"

            target_dir="$FILES_DIR/$year/$month/$day"
            
            # Create directory structure if it doesn't exist, and log any errors
            if mkdir -p "$target_dir"; then
                log "INFO" "Created directory $target_dir"
            else
                log "ERROR" "Failed to create directory $target_dir"
                continue
            fi

            # Move the file to the appropriate directory, and log any errors
            if mv "$file" "$target_dir/"; then
                log "INFO" "Moved $filename to $target_dir/"
            else
                log "ERROR" "Failed to move $filename to $target_dir/" 
            fi
        else
            log "ERROR" "Skipping $filename - not in expected format."
        fi
    done
fi

log "INFO" "Organizing files complete."
