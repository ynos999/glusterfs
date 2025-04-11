# GlusterFS setup script for Ubuntu 22.04
###
### First step add to hosts file your IP's:
#### sudo nano /etc/hosts
#### 10.211.55.37 node1 # My Example IP, write Your IP
#### 10.211.55.38 node2 # My Example IP, write Your IP
#### sudo -i
###
### Copy scripts to master node1 node1-setup.sh and glusterfs-secure.sh
###
#### chmod +x node1-setup.sh
#### sudo ./node1-setup.sh If You need, change DEVICE="/dev/sdb
#### chmod +x glusterfs-secure.sh and edit ALLOWED_IPS="10.211.55.37,10.211.55.38" to your Ip's.
#### sudo ./glusterfs-secure.sh
###
### Copy scripts to node2 node2-setup.sh and glusterfs-secure.sh
#### chmod +x node2-setup.sh If You need, change DEVICE="/dev/sdb
#### sudo ./node2-setup.sh
#### chmod +x glusterfs-secure.sh and edit ALLOWED_IPS="10.211.55.37,10.211.55.38" to your Ip's.
#### sudo ./glusterfs-secure.sh
###
###
##### Test:
##### touch /opt/test1 /opt/test2
##### ls -l /opt/
##### service glusterd stop
##### gluster peer status
##### gluster volume status
##### touch /opt/test3 /opt/test4
##### service glusterd start
##### ls -l /opt/
###
### Security manual
###
#### 1. Restrict Trusted Pool to Specific Hosts
#### nano /etc/glusterfs/glusterd.vol
#### Add this inside the volume block before end-volume
#### option rpc-auth.allow 10.211.55.37,10.211.55.38
#### Replace IPs with your actual Gluster nodes.
#### Then restart the service:
#### systemctl restart glusterd

#### 2. Firewall (UFW or iptables)
#### Open only the necessary ports between the Gluster nodes:
#### Allow GlusterFS ports (default)
#### ufw allow from 10.211.55.37/32 to any port 24007 # Change IP
#### ufw allow from 10.211.55.37/32 to any port 24008 # Change IP
#### ufw allow from 10.211.55.37/32 to any port 49152:49251 proto tcp # Change IP
#### ufw enable

#### 3. SELinux / AppArmor
#### Ubuntu uses AppArmor — GlusterFS profiles are typically permissive by default, but you can enforce them.
#### For SELinux (on RHEL/CentOS), set:
#### setsebool -P virt_use_fusefs on

#### 4. Use Encrypted Communication (TLS)
#### GlusterFS supports TLS encryption for node-to-node and client-to-node traffic.
#### Steps:
#### Generate a CA, and sign certs for each node.
#### Place certs in /etc/ssl/glusterfs/:
#### glusterfs.pem
#### glusterfs.key
#### glusterfs.ca
###
#### Enable encryption in /etc/glusterfs/glusterd.vol:
#### option transport.socket.ssl-enabled on
#### option transport.socket.ssl-cert /etc/ssl/glusterfs/glusterfs.pem
#### option transport.socket.ssl-key /etc/ssl/glusterfs/glusterfs.key
#### option transport.socket.ssl-ca-list /etc/ssl/glusterfs/glusterfs.ca
#### Restart glusterd.
###
#### 5. Enable Client Authentication
#### Restrict which clients can mount the Gluster volume:
#### gluster volume set vol1 auth.allow 10.211.55.37,10.211.55.38
#### You can also use hostnames if DNS is solid.
###
#### 6. Log Monitoring
#### Watch logs for unauthorized attempts:
#### tail -f /var/log/glusterfs/glusterd.log
#### Consider integrating with fail2ban, or ship logs to a SIEM.
###
#### 7. Keep GlusterFS Up to Date
#### Always run:
#### apt update && apt upgrade glusterfs-server
#### Gluster has active patching — security holes are patched quickly.

### If crush after security script:
#### sudo systemctl reset-failed glusterd.service
#### sudo systemctl start glusterd
#### sudo systemctl status glusterd
#### sudo ./glusterfs-secure.sh