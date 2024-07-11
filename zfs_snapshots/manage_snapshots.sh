#!/bin/bash

# Get current date and time
NOW=$(date +%Y-%m-%d_%H-%M-%S-%Z)

# Ensure exactly one argument (dataset) is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <dataset>"
    exit 1
fi

# Check if the dataset exists
DATASET="$1"
if ! zfs list "$DATASET" >/dev/null 2>&1; then
    echo "Dataset $DATASET does not exist."
    exit 1
fi

# Function to create necessary directories and files
setup_environment() {
    # Define dataset from argument
    SCRIPT_DIR=$(dirname "$(realpath "$0")")
    LOG_DIR="${SCRIPT_DIR}/logs"

    # Get the owner of the parent directory
    PARENT_DIR=$(dirname "${SCRIPT_DIR}")
    PARENT_OWNER=$(stat -c '%u:%g' "${PARENT_DIR}")

    mkdir -p "${LOG_DIR}"
    chown "${PARENT_OWNER}" "${LOG_DIR}"

    LOG_FILE="${LOG_DIR}/$(basename "${DATASET}").log"
    LOCKFILE="${SCRIPT_DIR}/$(basename "${DATASET}").lock"

    touch "${LOG_FILE}" "${LOCKFILE}"
    chown "${PARENT_OWNER}" "${LOG_FILE}" "${LOCKFILE}"
}

# Function to log messages
log() {
    local level=$1
    local message=$2
    local timestamp=$(date +%Y-%m-%d_%H-%M-%S-%Z)

    echo "$timestamp - ${level} - ${message}" >> "${LOG_FILE}"

    if [ -t 1 ]; then
        echo "$timestamp - ${level} - ${message}"
    elif [ "$level" = "ERROR" ]; then
        echo "$timestamp - ${level} - ${message}" >&2
    fi
}

# Function to create a snapshot with a tag
create_snapshot() {
    local dataset=$1
    local tag=$2
    if zfs snapshot "${dataset}@${NOW}_${tag}"; then
        log "INFO" "Snapshot created: ${dataset}@${NOW}_${tag}"
    else
        log "ERROR" "Failed to create snapshot: ${dataset}@${NOW}_${tag}"
    fi
}

# Function to clean up old snapshots based on retention periods
cleanup_snapshots() {
    local dataset=$1
    local tag=$2
    local keep=$3

    snapshots=$(zfs list -t snapshot -o name -s creation | grep "${dataset}@.*${tag}")
    count=$(echo "$snapshots" | grep -c "${dataset}@.*${tag}")

    if [ "$count" -ge 1 ]; then 
        log "INFO" "$count ${tag} snapshots found for ${dataset}"
    fi

    if [ "$count" -gt "$keep" ]; then
        to_delete=$(echo "$snapshots" | head -n -"$keep")
        if echo "$to_delete" | xargs -n 1 zfs destroy; then
            log "INFO" "$(echo "$to_delete" | wc -l) old ${tag} snapshots deleted for ${dataset}"
            log "INFO" "Deleted snapshots: $(echo "$to_delete" | tr '\n' ' ')"
            cleanup_occurred=true
        else
            log "ERROR" "Failed to delete some ${tag} snapshots for ${dataset}"
            log "ERROR" "Snapshots to delete: $(echo "$to_delete" | tr '\n' ' ')"
        fi
    fi
}

# Function to handle cleanup of snapshots
cleanup_all_snapshots() {
    cleanup_occurred=false
    cleanup_snapshots "${DATASET}" "hourly" 24
    cleanup_snapshots "${DATASET}" "daily" 14
    cleanup_snapshots "${DATASET}" "weekly" 12
    cleanup_snapshots "${DATASET}" "monthly" 12
    cleanup_snapshots "${DATASET}" "yearly" 5

    if [ "$cleanup_occurred" = true ]; then
        log "INFO" "Snapshots were cleaned up."
    else
        log "INFO" "No snapshots to cleanup."
    fi
}

# Function to ensure only one instance of the script runs at a time
ensure_single_instance() {
    if [ -e "${LOCKFILE}" ]; then
        LOCK_PID=$(cat "${LOCKFILE}")
        if [ -n "$LOCK_PID" ] && kill -0 "$LOCK_PID" 2>/dev/null; then
            log "ERROR" "Script is already running. PID: $LOCK_PID"
            exit 1
        fi
    fi

    trap 'rm -f "${LOCKFILE}"; exit' INT TERM EXIT
    echo $$ > "${LOCKFILE}"
}

# Function to parse the captured date and time into individual components
parse_current_time() {
    current_hour=$(echo $NOW | cut -d'_' -f2 | cut -d'-' -f1)
    current_minute=$(echo $NOW | cut -d'_' -f2 | cut -d'-' -f2)
    current_second=$(echo $NOW | cut -d'_' -f2 | cut -d'-' -f3 | cut -d'-' -f1)
    current_day=$(echo $NOW | cut -d'_' -f1 | cut -d'-' -f3)
    current_weekday=$(date +%u)
    current_month=$(echo $NOW | cut -d'_' -f1 | cut -d'-' -f2)
}

# Function to handle snapshot creation based on time
handle_snapshot_policy() {

    snapshot_taken=false        

    if [ "$current_minute" -eq 0 ]; then
        create_snapshot "${DATASET}" "hourly"
        snapshot_taken=true
    fi
    
    if [ "$current_hour" -eq 0 ] && [ "$current_minute" -eq 0 ]; then
        create_snapshot "${DATASET}" "daily"
        snapshot_taken=true
    fi
    
    if [ "$current_weekday" -eq 7 ] && [ "$current_hour" -eq 0 ] && [ "$current_minute" -eq 0 ]; then
        create_snapshot "${DATASET}" "weekly"
        snapshot_taken=true
    fi
    
    if [ "$current_day" -eq 1 ] && [ "$current_hour" -eq 0 ] && [ "$current_minute" -eq 0 ]; then
        create_snapshot "${DATASET}" "monthly"
        snapshot_taken=true
    fi

    if [ "$current_month" -eq 1 ] && [ "$current_day" -eq 1 ] && [ "$current_hour" -eq 0 ] && [ "$current_minute" -eq 0 ]; then
        create_snapshot "${DATASET}" "yearly"
        snapshot_taken=true
    fi
    
    if [ "$snapshot_taken" = true ]; then
        log "ERROR" "Snapshot script ran outside the expected schedule for ${DATASET}"
    fi
    cleanup_all_snapshots
}

# Function to prompt user for manual snapshot and cleanup
interactive_prompt() {
    log "INFO" "Script ran interactively. Prompting user for manual snapshot."
    echo "Would you like to take a manual snapshot now? The snapshot name will be: \"${DATASET}@${NOW}_manual\""
    read -p "(yes/no) " snapshot_response
    if [ "$snapshot_response" = "yes" ]; then
        log "INFO" "User opted to take a manual snapshot."
        create_snapshot "${DATASET}" "manual"
    else
        log "INFO" "User declined to take a manual snapshot."
    fi

    log "INFO" "Prompting user for snapshot cleanup."
    echo "Would you like to clean up snapshots now?"
    read -p "(yes/no) " cleanup_response
    if [ "$cleanup_response" = "yes" ]; then
        log "INFO" "User opted to clean up scheduled snapshots."
        cleanup_all_snapshots
    else
        log "INFO" "User declined to clean up scheduled snapshots."
    fi
}

main() {
    setup_environment "$1"
    log "INFO" "Script started for dataset ${DATASET}"
    ensure_single_instance
    parse_current_time

    if [ -t 1 ]; then
        interactive_prompt
    else
        handle_snapshot_policy
    fi

    rm -f "${LOCKFILE}"
    trap - INT TERM EXIT
    log "INFO" "Script completed for dataset ${DATASET}"
}

main "$1"
