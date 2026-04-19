#!/bin/bash

# VARIABLES
DATASTORE_ID="DEINE_ID" # Enter your ID here
MOUNT_POINT="/mnt/backup-synology/"

case "$1" in
    start)
        echo "Starting NAS connection..."
        mount $MOUNT_POINT
        
        if mountpoint -q $MOUNT_POINT; then
            # Remove maintenance mode (Status: Normal)
            proxmox-backup-manager datastore update ${DATASTORE_ID} --delete maintenance-mode
            echo "NAS mounted and datastore activated."
        else
            echo "Error: Mount failed!"
            exit 1
        fi
        ;;
    stop)
        echo "Stopping NAS connection..."
        # Set datastore to 'offline'
        proxmox-backup-manager datastore update ${DATASTORE_ID} --maintenance-mode type=offline
        
        sleep 5
        
        umount -l $MOUNT_POINT
        echo "Datastore deactivated and NAS unmounted."
        ;;
    *)
        echo "Usage: $0 {start|stop}"
        exit 1
        ;;
esac