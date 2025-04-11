#!/bin/bash

# GlusterFS setup script for Ubuntu 22.04

# Master - node1

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
PEER="node2"
LOCAL_HOSTNAME=$(hostname)

echo "[*] Updating system..."
apt-get update -y && apt-get upgrade -y

echo "[*] Installing GlusterFS server..."
apt-get install -y glusterfs-server

echo "[*] Enabling GlusterFS service..."
systemctl start glusterd && systemctl enable glusterd

echo "[*] Partitioning disk $DEVICE..."
echo -e "n\np\n1\n\n\nw" | fdisk $DEVICE

# n – New partition
# p – Primary partition
# 1 – Partition number
# (blank) – Accept default first sector
# (blank) – Accept default last sector (uses entire disk or free space)
# w – Write changes and exit

echo "[*] Formatting partition as XFS..."
mkfs.xfs -f $PARTITION

echo "[*] Creating mount point $MOUNT_DIR..."
mkdir -p $MOUNT_DIR

echo "[*] Updating /etc/fstab..."
echo "$PARTITION $MOUNT_DIR xfs defaults 0 0" >> /etc/fstab

echo "[*] Reloading systemd daemon to apply new fstab changes..."
systemctl daemon-reload
# systemctl daemon-reexec

echo "[*] Mounting all volumes..."
mount -a

echo "[*] Creating brick directory..."
mkdir -p $MOUNT_DIR/$BRICK_SUBDIR

# Only perform peer probe and volume creation from node1
if [[ "$LOCAL_HOSTNAME" == "node1" ]]; then
    echo "[*] Probing peer node ($PEER)..."
    gluster peer probe $PEER
    sleep 5

    echo "[*] Creating GlusterFS volume..."
    gluster volume create $VOLUME_NAME replica 2 \
        node1:$MOUNT_DIR/$BRICK_SUBDIR \
        node2:$MOUNT_DIR/$BRICK_SUBDIR force

    echo "[*] Starting GlusterFS volume..."
    gluster volume start $VOLUME_NAME
fi

echo "[*] Mounting GlusterFS volume on $MOUNT_TARGET..."
mkdir -p $MOUNT_TARGET
echo "localhost:/$VOLUME_NAME $MOUNT_TARGET glusterfs defaults,_netdev 0 0" >> /etc/fstab

echo "[*] Reloading systemd daemon to apply new fstab changes..."
systemctl daemon-reload

mount -a

echo "[✔] GlusterFS volume '$VOLUME_NAME' successfully configured and mounted at $MOUNT_TARGET."

# chmod +x node1-setup.sh
# sudo ./node1-setup.sh