#!/bin/bash

# GlusterFS authentication allow script
set -euo pipefail

# === Configuration ===
ALLOWED_IPS="10.211.55.37,10.211.55.38"
GLUSTERD_VOL="/etc/glusterfs/glusterd.vol"
VOLUME_NAME="vol1"

echo "[*] Backing up original $GLUSTERD_VOL..."
cp $GLUSTERD_VOL ${GLUSTERD_VOL}.bak.$(date +%s)

echo "[*] Setting auth.allow for volume $VOLUME_NAME..."
gluster volume set "$VOLUME_NAME" auth.allow "$ALLOWED_IPS"

echo "[*] Modifying glusterd configuration ($GLUSTERD_VOL) to include rpc-auth.allow..."
# Insert the rpc-auth.allow line before the end-volume line
if grep -q "option rpc-auth.allow" "$GLUSTERD_VOL"; then
    sed -i "s|option rpc-auth.allow.*|option rpc-auth.allow $ALLOWED_IPS|" "$GLUSTERD_VOL"
else
    sed -i "/end-volume/i\    option rpc-auth.allow $ALLOWED_IPS" "$GLUSTERD_VOL"
fi

echo "[*] Restarting glusterd service..."
systemctl restart glusterd

echo "[✔] Configuration completed. Volume $VOLUME_NAME now allows access from IPs $ALLOWED_IPS."

# chmod +x glusterfs-secure.sh
# sudo ./glusterfs-secure.sh