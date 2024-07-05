#!/bin/bash

# Determine the script's directory
SCRIPT_DIR=$(dirname "$0")

# Find all .conf files in SCRIPT_DIR
find "$SCRIPT_DIR" -name '*.conf' -type f | while IFS= read -r file; do
    # Get the current owner, group, and permissions of the file
    ORIGINAL_OWNER=$(stat -c "%U:%G" "$file")
    ORIGINAL_PERMISSIONS=$(stat -c "%a" "$file")

    # Change the owner to root
    chown root:root "$file"
    chmod 600 "$file"

    # Run logrotate on the file
    logrotate "$file"

    # Set the owner and permissions back to the original values
    chown "$ORIGINAL_OWNER" "$file"
    chmod "$ORIGINAL_PERMISSIONS" "$file"
done
