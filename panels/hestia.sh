#!/bin/bash

panel_run_backup() {
    local users_file="/root/bin/panels/hestia.users"
    local summary_file="/backup/backup.summary"
    local today
    today=$(date +%F)

    local total=0
    local failed_users=()

    if [[ ! -f "$users_file" ]]; then
        log "ERROR: Hestia users file not found: $users_file"
        return 1
    fi

    while read -r user || [[ -n "$user" ]]; do
        [[ -z "$user" ]] && continue
        [[ "$user" =~ ^# ]] && continue

        ((total++))

        local status_file="/backup/${user}.status"
        local backup_file
        local backup_start_ts

        log "Starting Hestia backup for user: $user"

        backup_start_ts=$(date +%s)

        if ! /usr/local/hestia/bin/v-backup-user "$user" >>"$LOGS_FILE" 2>&1; then
            log "ERROR: Hestia backup failed for user $user"
            echo "CRITICAL user=$user time=$(date +%F_%T) reason=backup_failed" >"$status_file"
            failed_users+=("$user")
            continue
        fi

	backup_file=$(find /backup -maxdepth 1 -type f \
	    -name "${user}.*.tar*" \
	    -newermt "@$backup_start_ts" \
	    -printf '%p\n' \
	    | sort | tail -n1)

        if [[ -z "$backup_file" ]]; then
            log "ERROR: Backup file not found for user $user"
            echo "CRITICAL user=$user time=$(date +%F_%T) reason=backup_file_missing" >"$status_file"
            failed_users+=("$user")
            continue
        fi

        log "Upload START: $backup_file"
        if ! upload_archive "$backup_file" "$today" "$LOGS_FILE"; then
            log "ERROR: Upload failed for $backup_file"
            echo "CRITICAL user=$user time=$(date +%F_%T) reason=upload_failed" >"$status_file"
            failed_users+=("$user")
            continue
        fi
        log "Upload END: $backup_file"

        log "Verification START: $backup_file"
        if ! check_archive "$backup_file" "$LOGS_FILE"; then
            log "ERROR: Verification failed for $backup_file"
            echo "CRITICAL user=$user time=$(date +%F_%T) reason=verification_failed" >"$status_file"
            failed_users+=("$user")
            continue
        fi
        log "Verification END: $backup_file"

        rm -f "$backup_file"
        log "Local backup removed: $backup_file"
        echo "OK user=$user time=$(date +%F_%T)" >"$status_file"

    done <"$users_file"

    if [[ $total -eq 0 ]]; then
        echo "CRITICAL $today   backups: no users found" >"$summary_file"
        return 1
    elif [[ ${#failed_users[@]} -gt 0 ]]; then
        echo "CRITICAL $today  backups: ${#failed_users[@]}/$total failed (${failed_users[*]// /, })" \
            >"$summary_file"
        return 1
    else
        echo "OK $today  backups: $total total" >"$summary_file"
        return 0
    fi
}
