#!/usr/bin/env python3
import os
import re
import shutil
import sys
import logging
from datetime import datetime, timezone

# Specify the directory to output the files
OUTPUT_DIR = "/mnt/RussNAS/media/Drone Videos"
# Specify the directory containing the files to process
FILES_DIR = os.path.join(OUTPUT_DIR, "To Process")

# Determine the script's directory
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

# Set up the logger
LOG_FILE = os.path.join(SCRIPT_DIR, "organize_dji_files.log")
logging.basicConfig(level=logging.INFO,
                    format='%(asctime)s - %(levelname)s - %(message)s',
                    datefmt='%Y-%m-%d-%H-%M-%S-%Z',
                    handlers=[logging.FileHandler(LOG_FILE)])

# Add StreamHandler if script is run via terminal
if sys.stdout.isatty():
    console_handler = logging.StreamHandler()
    console_handler.setLevel(logging.INFO)
    console_handler.setFormatter(logging.Formatter('%(asctime)s - %(levelname)s - %(message)s'))
    logging.getLogger().addHandler(console_handler)

def process_files():
    # List all entries in the directory
    all_entries = os.listdir(FILES_DIR)
    
    # Filter out only the files from the entries
    files_to_process = [entry for entry in all_entries if os.path.isfile(os.path.join(FILES_DIR, entry))]
    
    if not files_to_process:
        logging.info(f"No files to process in {FILES_DIR}")
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
                        logging.info(f"Created directory {target_dir}")
                    except Exception as e:
                        logging.error(f"Failed to create directory {target_dir}: {e}")
                        continue

                # Move the file to the appropriate directory, and log any errors
                try:
                    shutil.move(file_path, target_dir)
                    logging.info(f"Moved {filename} to {target_dir}/")
                except Exception as e:
                    logging.error(f"Failed to move {filename} to {target_dir}/: {e}")
            else:
                logging.error(f"Skipping {filename} - not in expected format")

def main():
    # Ensure the directory exists
    logging.info("Organizing files started")
    if not os.path.isdir(OUTPUT_DIR):
        logging.error(f"Directory {OUTPUT_DIR} does not exist. Exiting.")
        sys.exit(1)

    # Ensure the directory exists
    if not os.path.isdir(FILES_DIR):
        logging.error(f"Directory {FILES_DIR} does not exist. Exiting.")
        sys.exit(1)

    process_files()
    logging.info("Organizing files complete")

if __name__ == "__main__":
    main()
