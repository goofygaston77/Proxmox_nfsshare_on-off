# Proxmox NFS Share On/Off Scripts

Small helper scripts to switch NAS-based backup storage on and off on a schedule.

## What the scripts do

- `pbs_nas_sync.sh`
  - `start`: mount NAS share and set PBS datastore to normal mode
  - `stop`: set PBS datastore to offline mode and unmount
  - must run on the Proxmox Backup Server (PBS) host

- `nas-pve-toggle.sh`
  - `start`: enable NFS storage in Proxmox VE
  - `stop`: disable NFS storage in Proxmox VE and lazy-unmount

## Required configuration

Set the IDs/paths inside the scripts to your environment:
- `pbs_nas_sync.sh`: `DATASTORE_ID`, `MOUNT_POINT`
- `nas-pve-toggle.sh`: `PBS_STORAGE_ID`, `NFS_STORAGE_ID`

Also make sure mounts are configured correctly in both systems, with suitable NFS options.
Do not reuse hardcoded paths from other examples.

PBS host mount (placeholder example in `/etc/fstab`):
```bash
<NAS_IP>:/<NAS_EXPORT_PATH> <PBS_MOUNT_POINT> nfs vers=4,rw,noauto,soft,noatime,retrans=2,_netdev 0 0
```

Proxmox VE storage (placeholder example in `/etc/pve/storage.cfg`):
```cfg
nfs: <PVE_STORAGE_ID>
        export <PVE_NAS_EXPORT_PATH>
        path <PVE_MOUNT_POINT>
        server <NAS_IP>
        content backup
        options rw,soft,noatime
```

Mapping must match script variables:
- `<PBS_MOUNT_POINT>` = `MOUNT_POINT`
- `<PVE_STORAGE_ID>` = `NFS_STORAGE_ID`
- `<PVE_MOUNT_POINT>` = `/mnt/pve/<NFS_STORAGE_ID>`

## Install

```bash
sudo cp nas-pve-toggle.sh /usr/local/bin/nas-pve-toggle.sh
sudo cp pbs_nas_sync.sh /usr/local/bin/pbs-nas-sync.sh
sudo chmod +x /usr/local/bin/nas-pve-toggle.sh /usr/local/bin/pbs-nas-sync.sh
```

Optional check:
```bash
proxmox-backup-manager datastore list
```

## Cron example

Use the `crontab-example` file as template and adjust times to your NAS online window.

Cron reliability fix (April 2026):
- Earlier cron runs failed because cron uses a minimal environment.
- Both scripts now export an explicit `PATH` at the top.
- Keep absolute script paths in cron entries (for example `/usr/local/bin/pbs-nas-sync.sh`).

Important:
- Add `pbs-nas-sync.sh` jobs on the PBS host.
- Add `nas-pve-toggle.sh` jobs on the PVE host.

PBS host crontab:
```bash
15 1 * * * /usr/local/bin/pbs-nas-sync.sh start
45 3 * * * /usr/local/bin/pbs-nas-sync.sh stop
```

PVE host crontab:
```bash
05 1 * * * /usr/local/bin/nas-pve-toggle.sh start
55 3 * * * /usr/local/bin/nas-pve-toggle.sh stop
```

## Quick test

```bash
sudo /usr/local/bin/nas-pve-toggle.sh start
sudo /usr/local/bin/nas-pve-toggle.sh stop
sudo /usr/local/bin/pbs-nas-sync.sh start
sudo /usr/local/bin/pbs-nas-sync.sh stop
```

## Notes

- Run scripts as root (or via sudo).
- If something fails, check permissions, mount settings, and system logs.
