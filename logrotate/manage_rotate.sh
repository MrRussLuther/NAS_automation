#!/bin/bash

# Determine the script's directory
SCRIPT_DIR=$(dirname "$0")

# Find all .conf files in SCRIPT_DIR
find "$SCRIPT_DIR" -name '*.conf' -type f | while IFS= read -r file; do
    # Get the current owner and group of the file
    ORIGINAL_OWNER=$(stat -c "%U:%G" "$file")

    # Change the owner to root
    chown root:root "$file"
    chmod 644 "$file"
    # Run logrotate on the file
    logrotate "$file"

    # Set the owner back to the original owner
    chown "$ORIGINAL_OWNER" "$file"
    chmod 755 "$file"
done
