#!/bin/bash

# SELinux
setenforce Permissive

# install swift
yum install -y openstack-swift-account openstack-swift-container openstack-swift-object xfsprogs xinetd openstack-utils rsync

# create disk
parted -s /dev/sdb mklabel gpt
parted -s /dev/sdb mkpart primary 2048 100%
mkfs.xfs /dev/sdb1
mkdir -p /srv/node/sdb
echo "/dev/sdb1 /srv/node/sdb xfs defaults 1 2" >> /etc/fstab
mount -av 
chown -R swift:swift /srv/node
restorecon -R /srv/node

i=$(hostname -s | awk '{print substr($1,length($1),1)}')

# configure rsync for consistencey
cat > /etc/rsyncd.conf << EOF
uid = swift
gid = swift
log file = /var/log/rsyncd.log
pid file = /var/run/rsyncd.pid
address = 10.19.137.10$i
 
[account]
max connections = 2
path = /srv/node/
read only = false
lock file = /var/lock/account.lock
 
[container]
max connections = 2
path = /srv/node/
read only = false
lock file = /var/lock/container.lock
 
[object]
max connections = 2
path = /srv/node/
read only = false
lock file = /var/lock/object.lock
EOF

systemctl enable rsyncd.service
systemctl start rsyncd.service

# configure swift
openstack-config --set /etc/swift/object-server.conf DEFAULT bind_ip 10.19.137.10$i
openstack-config --set /etc/swift/object-server.conf DEFAULT devices /srv/node
openstack-config --set /etc/swift/account-server.conf DEFAULT bind_ip 10.19.137.10$i
openstack-config --set /etc/swift/account-server.conf DEFAULT devices /srv/node
openstack-config --set /etc/swift/container-server.conf DEFAULT bind_ip 10.19.137.10$i
openstack-config --set /etc/swift/container-server.conf DEFAULT devices /srv/node
chown -R root:swift /etc/swift

# configure service files
openstack-config --set /etc/swift/account-server.conf DEFAULT bind_port 6002
openstack-config --set /etc/swift/account-server.conf pipeline:main pipeline "healthcheck recon account-server"
openstack-config --set /etc/swift/account-server.conf filter:recon recon_cache_path /var/cache/swift
openstack-config --set /etc/swift/account-server.conf filter:recon use 'egg:swift#recon'
openstack-config --set /etc/swift/account-server.conf filter:recon recon_cache_path /var/cache/swift
openstack-config --set /etc/swift/account-server.conf filter:recon account_recon true
openstack-config --set /etc/swift/account-server.conf filter:healthcheck use 'egg:swift#healthcheck'

openstack-config --set /etc/swift/container-server.conf DEFAULT bind_port 6001
openstack-config --set /etc/swift/container-server.conf pipeline:main pipeline "healthcheck recon container-server"
openstack-config --set /etc/swift/container-server.conf filter:recon use 'egg:swift#recon'
openstack-config --set /etc/swift/container-server.conf filter:recon recon_cache_path /var/cache/swift
openstack-config --set /etc/swift/container-server.conf filter:recon container_recon true
openstack-config --set /etc/swift/container-server.conf filter:healthcheck use 'egg:swift#healthcheck'

openstack-config --set /etc/swift/object-server.conf DEFAULT bind_port 6000
openstack-config --set /etc/swift/object-server.conf pipeline:main pipeline "healthcheck recon object-server"
openstack-config --set /etc/swift/object-server.conf filter:recon use 'egg:swift#recon'
openstack-config --set /etc/swift/object-server.conf filter:recon recon_cache_path /var/cache/swift
openstack-config --set /etc/swift/object-server.conf filter:recon object_recon true
openstack-config --set /etc/swift/object-server.conf filter:healthcheck use 'egg:swift#healthcheck'

# create cache directory
mkdir -p /var/cache/swift
chown -R swift:swift /var/cache/swift

# configure the firewall
firewall-cmd --add-port=6000/tcp
firewall-cmd --add-port=6000/tcp --permanent
firewall-cmd --add-port=6001/tcp
firewall-cmd --add-port=6001/tcp --permanent
firewall-cmd --add-port=6002/tcp
firewall-cmd --add-port=6002/tcp --permanent
firewall-cmd --add-port=8080/tcp
firewall-cmd --add-port=8080/tcp --permanent

# extract ring files
#cd /etc/swift
#tar xvfz /tmp/swift_configs.tgz
#chown -R root:swift /etc/swift
#restorecon -R /etc/swift

# enable the service
#systemctl enable openstack-swift-account
#systemctl enable openstack-swift-container
#systemctl enable openstack-swift-object

# start the services
#systemctl start openstack-swift-account
#systemctl start openstack-swift-container
#systemctl start openstack-swift-object
#swift-init all start
