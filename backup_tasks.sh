#!/bin/bash
# Written by Vasyl T

# =====================
# Upload archive via SFTP (SSH)
# =====================
upload_archive() {
    local file="$1"
    local date="$2"
    local log_file="$3"

    local filename
    filename=$(basename "$file")

    echo "$(date +%F_%T) => Uploading via SFTP: $filename" | tee -a "$log_file"

    sftp -i /root/.ssh/id_rsa -o StrictHostKeyChecking=no \
        "$FTP_USER@$FTP_HOST" <<EOF >> "$log_file" 2>&1
cd $REMOTE_DIR
put $file
bye
EOF

    if [[ $? -ne 0 ]]; then
        echo "$(date +%F_%T) => ERROR: SFTP upload failed for $file" | tee -a "$log_file"
        return 1
    fi

    echo "$(date +%F_%T) => SFTP upload completed: $file" | tee -a "$log_file"
    return 0
}


# =====================
# Remote archive check (SFTP / SSH)
# =====================
check_archive() {
    local local_file="$1"
    local log_file="$2"
    local fname
    fname=$(basename "$local_file")

    local local_size
    local_size=$(stat -c%s "$local_file") || {
        echo "$(date +%F_%T) => ERROR: Cannot get local size for $local_file" | tee -a "$log_file"
        return 1
    }

    remote_size=$(sftp -i /root/.ssh/id_rsa "$FTP_USER@$FTP_HOST" <<EOF 2>/dev/null | awk '{print $5}'
cd $REMOTE_DIR
ls -l "$fname"
bye
EOF
)

    if [[ -z "$remote_size" ]]; then
        echo "$(date +%F_%T) => ERROR: Remote file not found: $REMOTE_DIR/$fname" | tee -a "$log_file"
        return 1
    fi

    if [[ "$local_size" -eq "$remote_size" ]]; then
        echo "$(date +%F_%T) => Archive $fname verified OK" | tee -a "$log_file"
        return 0
    fi

    echo "$(date +%F_%T) => ERROR: Size mismatch for $fname" | tee -a "$log_file"
    return 1
}

# =====================
# Remove local backups
# =====================
remove_local_backup() {
    local dir="$1"
    local log_file="$2"

    echo "$(date +%Y-%m-%d_%H:%M:%S) => Removing local backup: $dir" >> "$log_file"

    rm -rf "$dir"

    if [[ $? -eq 0 ]]; then
        echo "$(date +%Y-%m-%d_%H:%M:%S) => Local backup removed" >> "$log_file"
    else
        echo "$(date +%Y-%m-%d_%H:%M:%S) => ERROR: Failed to remove $dir" >> "$log_file"
    fi
}
