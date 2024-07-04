#!/bin/bash

# Exit on error, undefined variable, or pipe failure
set -euo pipefail

# Specify the directory containing the files
FILES_DIR="/mnt/RussNAS/plex/plex-media/Library/Drone Videos/To Process"

# Determine the script's directory
SCRIPT_DIR=$(dirname "$0")

# Set the log file location in the script's directory
LOG_FILE="${SCRIPT_DIR}/organize_dji_files.log"

log() {
    local message="$1"
    local log_type="${2:-}"
    if [ "$log_type" == "error" ]; then
        echo "$(date) - ERROR: $message" >> "$LOG_FILE"
    else
        echo "$(date) - $message" >> "$LOG_FILE"
    fi
}

# Ensure the directory exists
if [ ! -d "$FILES_DIR" ]; then
    log "Directory $FILES_DIR does not exist. Exiting." "error"
    exit 1
fi

# Check if there are any files to process
if [ "$(find "$FILES_DIR" -type f | wc -l)" -eq 0 ]; then
    log "No files to process in $FILES_DIR."
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
                log "Created directory $target_dir"
            else
                log "Failed to create directory $target_dir" "error"
                continue
            fi

            # Move the file to the appropriate directory, and log any errors
            if mv "$file" "$target_dir/"; then
                log "Moved $filename to $target_dir/"
            else
                log "Failed to move $filename to $target_dir/" "error"
            fi
        else
            log "Skipping $filename - not in expected format." "error"
        fi
    done
fi

log "Organizing files complete."
echo "Log file is located at: $LOG_FILE"
