#!/bin/bash
set -u

# =================================================================================================
# Mount the backup drive
#
mkdir /mnt/Backup
mount /dev/sdb1 /mnt/Backup
pvesm add dir Backup --path /mnt/Backup --content backup


# =================================================================================================
# Restore each VM
#
# Backups are located in /mnt/Backup/dumps
# We also need to get the most recent backup, and not install all of them
# File names are as thus
# vzdump-qemu-<vid>-<date>.vma.zst
find /mnt/Backup/dump -type f -name "*.zst" > backup_list.txt
python3 backup_identify.py