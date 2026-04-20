#!/bin/bash

# Set PATH for the PVE environment (critical for cron)
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# IDs of your storages (check these in Datacenter -> Storage)
PBS_STORAGE_ID="backup-synology-nfs" 
NFS_STORAGE_ID="synology_pbs_backup"

case "$1" in
    start)
        echo "$(date): Enabling storages on PVE..."
        # Enable storages
        pvesm set $PBS_STORAGE_ID --disable 0
        pvesm set $NFS_STORAGE_ID --disable 0
        ;;
    stop)
        echo "$(date): Disabling storages on PVE..."
        # Disable storages (stops pvestatd polling)
        pvesm set $PBS_STORAGE_ID --disable 1
        pvesm set $NFS_STORAGE_ID --disable 1
        
        # Wait 2 seconds
        sleep 2
        
        # Unmount NFS share if it is still mounted
        umount -l /mnt/pve/$NFS_STORAGE_ID 2>/dev/null
        ;;
    *)
        echo "Usage: $0 {start|stop}"
        exit 1
        ;;
esac