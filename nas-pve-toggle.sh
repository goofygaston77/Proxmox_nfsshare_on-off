#!/bin/bash

# Variables
STORAGE_ID="synology_pbs_backup"
MOUNT_PATH="/mnt/pve/synology_pbs_backup"

case "$1" in
    start)
        echo "Activating $STORAGE_ID..."
        # Set storage in Proxmox back to 'active'
        pvesm set $STORAGE_ID --disable 0
        
        # As a precaution, check if the mount exists
        if mountpoint -q $MOUNT_PATH; then
            echo "Storage is online and ready."
        else
            echo "Storage activated, mount will follow automatically."
        fi
        ;;
    stop)
        echo "Deactivating $STORAGE_ID..."
        # Deactivate storage in Proxmox (stops status queries)
        pvesm set $STORAGE_ID --disable 1
        
        # Brief pause for the system
        sleep 2
        
        # Unmount NFS mount 'lazy' to avoid GUI freezes
        umount -l $MOUNT_PATH 2>/dev/null
        echo "Storage is now offline."
        ;;
    *)
        echo "Usage: $0 {start|stop}"
        exit 1
        ;;
esac