#!/bin/bash

# Get current date and time
NOW=$(date +%Y-%m-%d-%H-%M-%S)

# Function to log messages
log() {
    local level=$1
    local message=$2
    echo "$(date +%Y-%m-%d-%H-%M-%S) - ${level} - ${message}" >> ${LOGFILE}
}

# Ensure dataset is provided as an argument
if [ -z "$1" ]; then
    echo "Usage: $0 <dataset>"
    exit 1
fi

# Define dataset from argument
DATASET="$1"
SCRIPT_DIR=$(dirname "$(realpath "$0")")
LOG_DIR="${SCRIPT_DIR}/logs"

# Get the owner of the parent directory
PARENT_DIR=$(dirname "${SCRIPT_DIR}")
PARENT_OWNER=$(stat -c '%u:%g' "${PARENT_DIR}")

# Create log directory if it doesn't exist with the same ownership as the parent directory
mkdir -p "${LOG_DIR}"
chown "${PARENT_OWNER}" "${LOG_DIR}"

LOGFILE="${LOG_DIR}/$(basename "${DATASET}").log"
LOCKFILE="${SCRIPT_DIR}/$(basename "${DATASET}").lock"

# Create log and lock files with the same ownership as the parent directory
touch "${LOGFILE}" "${LOCKFILE}"
chown "${PARENT_OWNER}" "${LOGFILE}" "${LOCKFILE}"

# Log start of the script
log "INFO" "Script started for dataset ${DATASET}"

# Function to create a snapshot with a tag
create_snapshot() {
    local tag=$1
    if zfs snapshot "${DATASET}@${NOW}-${tag}"; then
        log "INFO" "Created snapshot ${DATASET}@${NOW}-${tag}"
    else
        log "ERROR" "Failed to create snapshot ${DATASET}@${NOW}-${tag}"
    fi
}

# Function to clean up old snapshots based on retention periods
cleanup_snapshots() {
    local dataset=$1
    local tag=$2
    local keep=$3

    # Get list of snapshots matching the tag
    snapshots=$(zfs list -t snapshot -o name -s creation | grep "${dataset}@.*-${tag}")
    
    # Count snapshots
    count=$(echo "$snapshots" | grep -c "${dataset}@.*-${tag}")
    
    # Log the number of snapshots before cleanup
    log "INFO" "Found $count ${tag} snapshots for ${dataset}"

    # Remove old snapshots if more than the 'keep' count
    if [ "$count" -gt "$keep" ]; then
        to_delete=$(echo "$snapshots" | head -n -$keep)
        if echo "$to_delete" | xargs -n 1 zfs destroy; then
            log "INFO" "Deleted $(echo "$to_delete" | wc -l) old ${tag} snapshots for ${dataset}"
            log "INFO" "Snapshot Names: $(echo "$to_delete" | tr '\n' ' ')"
        else
            log "ERROR" "Failed to delete some ${tag} snapshots for ${dataset}"
        fi
    fi
}

# Ensure only one instance of the script runs at a time
if [ -e "${LOCKFILE}" ]; then
    LOCK_PID=$(cat "${LOCKFILE}")
    if [ -n "$LOCK_PID" ] && kill -0 "$LOCK_PID" 2>/dev/null; then
        echo "Script is already running"
        log "ERROR" "Script is already running"
        exit 1
    fi
fi


# Create a lock file
trap 'rm -f "${LOCKFILE}"; exit' INT TERM EXIT
echo $$ > "${LOCKFILE}"

# Flag to indicate if a higher priority snapshot is taken
snapshot_taken=false

# Parse the captured date and time into individual components
current_hour=$(echo $NOW | cut -d'-' -f4)
current_minute=$(echo $NOW | cut -d'-' -f5)
current_second=$(echo $NOW | cut -d'-' -f6)
current_day=$(echo $NOW | cut -d'-' -f3)
current_weekday=$(date +%u)
current_month=$(echo $NOW | cut -d'-' -f2)

# Daily Snapshots: Tag daily snapshot at midnight
if [ "$current_hour" -eq 0 ] && [ "$current_minute" -eq 0 ]; then
    create_snapshot "daily"
    snapshot_taken=true
fi

# Weekly Snapshots: Tag weekly snapshot at midnight on Sunday
if [ "$current_weekday" -eq 7 ] && [ "$current_hour" -eq 0 ] && [ "$current_minute" -eq 0 ]; then
    create_snapshot "weekly"
    snapshot_taken=true
fi

# Monthly Snapshots: Tag monthly snapshot at midnight on the 1st
if [ "$current_day" -eq 1 ] && [ "$current_hour" -eq 0 ] && [ "$current_minute" -eq 0 ]; then
    create_snapshot "monthly"
    snapshot_taken=true
fi

# Yearly Snapshots: Tag yearly snapshot at midnight on January 1st
if [ "$current_month" -eq 1 ] && [ "$current_day" -eq 1 ] && [ "$current_hour" -eq 0 ] && [ "$current_minute" -eq 0 ]; then
    create_snapshot "yearly"
    snapshot_taken=true
fi

# Create a frequent snapshot every time the script runs if no other snapshot is taken
if [ "$snapshot_taken" = false ]; then
    create_snapshot "frequent"
fi

# Frequent Snapshots: Keep snapshots every 1 hour for 1 day
cleanup_snapshots "${DATASET}" "frequent" 24

# Daily Snapshots: Keep daily snapshots for 2 weeks
cleanup_snapshots "${DATASET}" "daily" 14

# Weekly Snapshots: Keep weekly snapshots for 3 months
cleanup_snapshots "${DATASET}" "weekly" 12

# Monthly Snapshots: Keep monthly snapshots for 1 year
cleanup_snapshots "${DATASET}" "monthly" 12

# Yearly Snapshots: Keep yearly snapshots for 5 years
cleanup_snapshots "${DATASET}" "yearly" 5

# Remove lock file
rm -f "${LOCKFILE}"
trap - INT TERM EXIT

# Log completion of the script
log "INFO" "Script completed for dataset ${DATASET}"
