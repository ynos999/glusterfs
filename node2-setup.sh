#!/bin/bash

# GlusterFS setup script for Ubuntu 22.04 (Node 2)

# First step add :
# sudo nano /etc/hosts
# 10.211.55.37 node1
# 10.211.55.38 node2

set -e

# Configurable variables
DEVICE="/dev/sdb" # If You need, change DEVICE="/dev/sdb
PARTITION="${DEVICE}1"
MOUNT_DIR="/glustervolume"
BRICK_SUBDIR="vol1"
VOLUME_NAME="vol1"
MOUNT_TARGET="/opt"

# Ensure you're running as root
if [[ $EUID -ne 0 ]]; then
   echo "[!] This script must be run as root." 
   exit 1
fi

echo "[*] Updating system..."
apt-get update -y && apt-get upgrade -y

echo "[*] Installing GlusterFS server..."
apt-get install -y glusterfs-server

echo "[*] Enabling GlusterFS service..."
systemctl start glusterd && systemctl enable glusterd

# Only create partition if it doesn't exist
if [ ! -b "$PARTITION" ]; then
    echo "[*] Partitioning disk $DEVICE..."
    echo -e "n\np\n1\n\n\nw" | fdisk $DEVICE
    partprobe $DEVICE
else
    echo "[*] Partition $PARTITION already exists. Skipping partitioning."
fi

echo "[*] Formatting partition as XFS..."
mkfs.xfs -f $PARTITION

echo "[*] Creating mount point $MOUNT_DIR..."
mkdir -p $MOUNT_DIR

echo "[*] Updating /etc/fstab..."
grep -q "$PARTITION" /etc/fstab || echo "$PARTITION $MOUNT_DIR xfs defaults 0 0" >> /etc/fstab

echo "[*] Reloading systemd daemon to apply new fstab changes..."
systemctl daemon-reload

echo "[*] Mounting all volumes..."
mount -a

echo "[*] Creating GlusterFS brick directory..."
mkdir -p $MOUNT_DIR/$BRICK_SUBDIR

echo "[*] Preparing GlusterFS mount at $MOUNT_TARGET..."
mkdir -p $MOUNT_TARGET
grep -q "localhost:/$VOLUME_NAME" /etc/fstab || echo "localhost:/$VOLUME_NAME $MOUNT_TARGET glusterfs defaults,_netdev 0 0" >> /etc/fstab

echo "[*] Reloading systemd daemon to apply new fstab changes..."
systemctl daemon-reload

mount -a

echo "[✔] Node 2 is ready. GlusterFS volume '$VOLUME_NAME' mounted at $MOUNT_TARGET."

# chmod +x node2-setup.sh
# sudo ./node2-setup.sh
