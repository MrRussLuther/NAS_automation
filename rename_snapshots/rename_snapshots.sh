#!/bin/bash

# Verify if dataset argument is passed
if [ -z "$1" ]; then
    echo "Usage: $0 <DATASET>" >&2
    exit 1
fi

DATASET="$1"

# Define the regex pattern for snapshot names
SNAPSHOT_PATTERN="^${DATASET}@[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}\.[0-9]{2}\.[0-9]{2}_-[0-9]{4}_(hourly|daily|weekly|monthly|yearly)$"

# Verify if dataset exists
if ! zfs list -H -o name | grep -q "^${DATASET}$"; then
    echo "Dataset '${DATASET}' does not exist." >&2
    exit 1
fi

# Define a mapping of numeric timezones to abbreviations
declare -A timezone_map=(
    ["-0500"]="EST"
    ["-0400"]="EDT"
    # Add more timezones as needed
)

# Get list of snapshots for the dataset
snapshots=$(zfs list -t snapshot -o name -H | grep "^${DATASET}@")

# Loop over each snapshot
for snapshot in $snapshots; do
    # Extract snapshot name and timezone part
    name=$(echo "$snapshot" | cut -d'@' -f2)
    timezone=$(echo "$name" | cut -d'_' -f3)

    # Check if the snapshot name matches the specific format
    if [[ "$snapshot" =~ $SNAPSHOT_PATTERN ]]; then
        # Use the manual mapping to get the written timezone
        written_timezone=${timezone_map[$timezone]}

        # Check if the timezone was successfully mapped
        if [ -z "$written_timezone" ]; then
            echo "Unknown timezone: '${timezone}' for snapshot '${snapshot}'" >&2
            continue
        else
            # Create new snapshot name with written out timezone
            new_name=$(echo "$name" | sed "s/${timezone}/${written_timezone}/")

            # Rename the snapshot and check if the operation was successful
            if ! zfs rename "${DATASET}@${name}" "${DATASET}@${new_name}"; then
                echo "Error renaming snapshot '${DATASET}@${name}' to '${DATASET}@${new_name}'" >&2
                continue
            fi
        fi
    else
        echo "Snapshot '${snapshot}' did not match the expected pattern" >&2
    fi
done
