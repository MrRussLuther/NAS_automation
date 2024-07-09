#!/usr/bin/env python3
import os
import re
import shutil
import sys
from datetime import datetime, timezone

# Specify the directory to output the files
OUTPUT_DIR = "/mnt/RussNAS/plex/plex-media/Library/Drone Videos"
# Specify the directory containing the files to process
FILES_DIR = os.path.join(OUTPUT_DIR, "To Process")

# Determine the script's directory
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

# Set the log file location in the script's directory
LOG_FILE = os.path.join(SCRIPT_DIR, "organize_dji_files.log")

# Function to log messages
def log(level: str, message: str) -> None:
    timestamp = datetime.now(timezone.utc).astimezone().strftime("%Y-%m-%d-%H-%M-%S-%Z")
    log_message = f"{timestamp} - {level} - {message}"
    
    # Log to the logfile
    with open(LOG_FILE, "a") as log_file:
        log_file.write(log_message + "\n")
    
    # Log to stderr if the level is ERROR
    if level == "ERROR":
        print(log_message, file=sys.stderr)
    elif sys.stdout.isatty():
        print(log_message)

def process_files():
    # List all entries in the directory
    all_entries = os.listdir(FILES_DIR)
    
    # Filter out only the files from the entries
    files_to_process = []
    for entry in all_entries:
        entry_path = os.path.join(FILES_DIR, entry)
        if os.path.isfile(entry_path):
            files_to_process.append(entry)
    
    if not files_to_process:
        log("INFO", f"No files to process in {FILES_DIR}")
    else:
        for file in files_to_process:
            file_path = os.path.join(FILES_DIR, file)
            filename = os.path.basename(file_path)

            match = re.match(r"DJI_(\d{8})(\d{6})_(\d{4})_D\.MP4", filename)
            if match:
                year = match.group(1)[:4]
                month = match.group(1)[4:6]
                day = match.group(1)[6:8]

                target_dir = os.path.join(OUTPUT_DIR, year, month, day)
                
                # Create directory structure if it doesn't exist, and log any errors
                if not os.path.isdir(target_dir):
                    try:
                        os.makedirs(target_dir)
                        log("INFO", f"Created directory {target_dir}")
                    except Exception as e:
                        log("ERROR", f"Failed to create directory {target_dir}: {e}")
                        continue

                # Move the file to the appropriate directory, and log any errors
                try:
                    shutil.move(file_path, target_dir)
                    log("INFO", f"Moved {filename} to {target_dir}/")
                except Exception as e:
                    log("ERROR", f"Failed to move {filename} to {target_dir}/: {e}")
            else:
                log("ERROR", f"Skipping {filename} - not in expected format")

def main():
    # Ensure the directory exists
    if not os.path.isdir(OUTPUT_DIR):
        log("ERROR", f"Directory {OUTPUT_DIR} does not exist. Exiting.")
        sys.exit(1)

    # Ensure the directory exists
    if not os.path.isdir(FILES_DIR):
        log("ERROR", f"Directory {FILES_DIR} does not exist. Exiting.")
        sys.exit(1)

    process_files()
    log("INFO", "Organizing files complete")

if __name__ == "__main__":
    main()
