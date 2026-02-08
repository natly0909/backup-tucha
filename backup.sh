#!/bin/bash

BASE_DIR="/root/bin"

SUMMARY_FILE="/backup/backup.summary"
echo "CRITICAL backup not finished yet" > "$SUMMARY_FILE"

source "$BASE_DIR/backup.conf"
source "$BASE_DIR/backup_tasks.sh"
source "$BASE_DIR/detect_panel.sh"

TODAY=$(date +%F)
LOGS_FILE="${LOGS_DIR}/${TODAY}.log"

mkdir -p "$LOGS_DIR"

log() {
    echo "$(date +%F_%T) => $*" | tee -a "$LOGS_FILE"
}

log "Backup started"

if [[ "$DISK_DEVICE" == /* ]]; then
    DISK_PATH="$DISK_DEVICE"
else
    DISK_PATH="/dev/$DISK_DEVICE"
fi

DISK_USAGE=$(df -P "$DISK_PATH" 2>/dev/null | awk 'NR==2 {gsub("%",""); print $5}')

if [[ -z "$DISK_USAGE" ]]; then
    log "ERROR: Cannot determine disk usage for $DISK_PATH"
    exit 1
fi

if (( DISK_USAGE > MAX_DISK_USAGE )); then
    log "ERROR: Disk usage ${DISK_USAGE}% exceeds limit ${MAX_DISK_USAGE}%"
    exit 1
fi

log "Disk usage ${DISK_USAGE}% — OK"

PANEL=$(detect_panel)
log "Detected panel: $PANEL"

PANEL_SCRIPT="$BASE_DIR/panels/${PANEL}.sh"

if [[ ! -f "$PANEL_SCRIPT" ]]; then
    log "ERROR: Panel handler not found: $PANEL_SCRIPT"
    exit 1
fi

source "$PANEL_SCRIPT"

if ! panel_run_backup; then
    log "Backup failed"
    exit 1
fi

log "Backup finished"
exit 0
