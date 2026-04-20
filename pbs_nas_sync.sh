#!/bin/bash

# Ensure cron can find all required commands
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# VARIABLES (keep as-is if the ID matches your logs)
DATASTORE_ID="backup-synology_nfs"
MOUNT_POINT="/mnt/backup-synology/"

case "$1" in
    start)
        echo "Starting NAS connection..."
        # 1. Mount
        mount $MOUNT_POINT
        
        # 2. Give the system 3 seconds (NFS may need a short delay)
        sleep 3
        
        # 3. Verify that the mount point is actually active
        if mountpoint -q $MOUNT_POINT; then
            # 4. Remove maintenance mode (enables the datastore in PBS)
            proxmox-backup-manager datastore update "$DATASTORE_ID" --delete maintenance-mode
            echo "Successfully enabled."
        else
            echo "ERROR: Mount point $MOUNT_POINT is not active!"
            exit 1
        fi
        ;;
    stop)
        echo "Stopping NAS connection..."
        # 1. Immediately set datastore to offline
        proxmox-backup-manager datastore update "$DATASTORE_ID" --maintenance-mode type=offline
        
        # 2. Wait briefly so PBS can close the connection
        sleep 5
        
        # 3. Unmount (lazy unmount)
        umount -l $MOUNT_POINT
        echo "Successfully disabled."
        ;;
    *)
        echo "Usage: $0 {start|stop}"
        exit 1
        ;;
esac