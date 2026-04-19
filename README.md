# Proxmox NFS Share On/Off Scripts

Automated scripts to manage NAS (Synology) storage mounting and Proxmox storage control with cron jobs. These scripts enable scheduled activation and deactivation of NFS storage to optimize resource usage and reduce network overhead.

## Overview

This project provides two complementary bash scripts that work together to:

1. **Mount/Unmount NFS shares** from a Synology NAS
2. **Enable/Disable Proxmox storage** to prevent unnecessary polling when storage is offline
3. **Control Proxmox Backup Server (PBS) datastore** maintenance mode

## Scripts

### 1. `nas-pve-toggle.sh`

Controls Proxmox storage activation/deactivation for PVE (Proxmox VE).

**Purpose:**
- Activate/deactivate storage in Proxmox
- Prevent continuous status polling to the NAS
- Gracefully handle mount points

**Usage:**
```bash
./nas-pve-toggle.sh start   # Activate storage
./nas-pve-toggle.sh stop    # Deactivate storage
```

**Configuration:**
- `STORAGE_ID`: The Proxmox storage identifier (default: `synology_pbs_backup`)
- `MOUNT_PATH`: The mount point path (default: `/mnt/pve/synology_pbs_backup`)

**What it does:**
- **start**: Enables storage in Proxmox and verifies the mount point
- **stop**: Disables storage in Proxmox and performs a lazy unmount to prevent GUI freezes

---

### 2. `pbs_nas_sync.sh`

Controls NAS mounting and Proxmox Backup Server (PBS) datastore management.

**Purpose:**
- Mount/unmount the NFS share from the Synology NAS
- Manage PBS datastore maintenance mode
- Ensure clean disconnection before NAS goes offline

**Usage:**
```bash
./pbs_nas_sync.sh start   # Mount NAS and activate datastore
./pbs_nas_sync.sh stop    # Deactivate datastore and unmount NAS
```

**Configuration:**
- `DATASTORE_ID`: Your PBS datastore ID (must be configured - see Setup section)
- `MOUNT_POINT`: The mount point path (default: `/mnt/backup-synology/`)

**What it does:**
- **start**: Mounts the NAS and removes the maintenance mode flag on the datastore
- **stop**: Sets datastore to offline maintenance mode and performs a lazy unmount

---

## Crontab Integration

The `crontab-example` file demonstrates how to schedule these scripts to match your NAS availability window.

### Example Scenario

NAS is online/accessible from **01:00 to 04:00** daily:

```bash
# Activate PBS NAS Sync at 01:15 (after NAS is available)
15 1 * * * /usr/local/bin/pbs-nas-sync.sh start

# Deactivate PBS NAS Sync at 03:45 (before NAS goes offline)
45 3 * * * /usr/local/bin/pbs-nas-sync.sh stop

# Activate PVE Storage at 01:05 (after NAS mount is ready)
05 1 * * * /usr/local/bin/nas-pve-toggle.sh start

# ... Your PVE backups run here on the mounted NAS ...

# Deactivate PVE Storage at 03:55 (before NAS goes offline)
55 3 * * * /usr/local/bin/nas-pve-toggle.sh stop
```

### Key Timing Considerations

1. **Start sequence** (morning/activation):
   - PBS sync starts at 01:15 to mount NAS
   - PVE toggle starts at 01:05 to enable storage (or after PBS is ready)
   - NAS backups can then run

2. **Stop sequence** (evening/deactivation):
   - PVE toggle stops at 03:55 to disable storage
   - PBS sync stops at 03:45 to cleanly unmount NAS
   - Order matters to prevent errors

## Installation

### 1. Copy scripts to system location

```bash
sudo cp nas-pve-toggle.sh /usr/local/bin/nas-pve-toggle.sh
sudo cp pbs_nas_sync.sh /usr/local/bin/pbs-nas-sync.sh
sudo chmod +x /usr/local/bin/nas-pve-toggle.sh
sudo chmod +x /usr/local/bin/pbs-nas-sync.sh
```

### 2. Configure PBS datastore ID

Edit `pbs_nas_sync.sh` and replace:
```bash
DATASTORE_ID="DEINE_ID"  # Replace with your actual datastore ID
```

Find your datastore ID:
```bash
proxmox-backup-manager datastore list
```

### 3. Configure mounts in PBS and Proxmox with correct parameters

Before using the scripts, ensure both mount definitions are configured correctly and consistently:
- PBS host mount configuration (for the datastore mount used by `pbs_nas_sync.sh`)
- Proxmox VE storage configuration (for the storage used by `nas-pve-toggle.sh`)

Use your own mount points and export paths. Do not copy fixed paths from foreign examples. The values must match your environment and the variables inside the scripts.

Example PBS host mount entry in `/etc/fstab` (placeholders):
```bash
<NAS_IP>:/<NAS_EXPORT_PATH> <PBS_MOUNT_POINT> nfs vers=4,rw,noauto,soft,noatime,retrans=2,_netdev 0 0
```

Example Proxmox VE storage entry in `/etc/pve/storage.cfg` (placeholders):
```cfg
nfs: <PVE_STORAGE_ID>
   export <PVE_NAS_EXPORT_PATH>
   path <PVE_MOUNT_POINT>
   server <NAS_IP>
   content backup
   options rw,soft,noatime
```

Important:
- The mount options must fit your network stability and backup workload.
- `<PBS_MOUNT_POINT>` must match `MOUNT_POINT` in `pbs_nas_sync.sh`.
- `<PVE_STORAGE_ID>` and `<PVE_MOUNT_POINT>` must match `STORAGE_ID` and `MOUNT_PATH` in `nas-pve-toggle.sh`.

### 4. Add cron jobs

```bash
sudo crontab -e
```

Add entries from `crontab-example` adjusted to your schedule.

### 5. Test the scripts manually

```bash
# Test PVE toggle
sudo /usr/local/bin/nas-pve-toggle.sh start
sudo /usr/local/bin/nas-pve-toggle.sh stop

# Test PBS sync
sudo /usr/local/bin/pbs-nas-sync.sh start
sudo /usr/local/bin/pbs-nas-sync.sh stop
```

---

## Requirements

### System Requirements
- Linux system with bash
- Proxmox VE or Proxmox Backup Server installed
- NFS client tools (`mount`, `umount`)
- Sudo/root access for storage commands and mounting

### Network Requirements
- Accessible Synology NAS with NFS export configured
- Network connectivity to NAS during scheduled activation window

### Proxmox Requirements
- Configured storage ID in Proxmox
- PBS datastore with known datastore ID
- NFS mount point configured in system or fstab

---

## Troubleshooting

### Script won't execute
- Check file permissions: `ls -l /usr/local/bin/nas-pve-toggle.sh`
- Ensure scripts have execute permission: `chmod +x`
- Verify root/sudo access for mount/unmount operations

### Cron jobs not running
- Check cron logs: `grep CRON /var/log/syslog`
- Verify crontab syntax: `crontab -l`
- Ensure scripts are at correct path with execute permissions

### Mount failures
- Check NAS network connectivity: `ping 192.168.1.100` (adjust IP)
- Verify NFS export on NAS is enabled and accessible
- Check `/etc/fstab` configuration
- Review system logs: `dmesg | tail`

### Datastore errors
- Verify datastore ID is correct: `proxmox-backup-manager datastore list`
- Check PBS service is running: `systemctl status proxmox-backup`
- Verify user running cron has proper permissions

---

## Use Cases

- **Energy Efficiency**: Turn off NAS and storage polling when not needed
- **Scheduled Backups**: Activate storage only during backup windows
- **Network Optimization**: Reduce unnecessary NAS traffic
- **Maintenance Windows**: Automatically handle NAS maintenance periods
- **Multi-Site Setups**: Coordinate storage access across different backup schedules

---

## License

These scripts are provided as-is for managing Proxmox/Synology infrastructure.

## Support

For issues or improvements, please check:
- Script permissions and ownership
- System logs and dmesg output
- Proxmox and NAS configuration
- Network connectivity and NFS configuration
