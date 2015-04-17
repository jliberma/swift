#!/bin/bash

source /root/keystonerc_admin
env | grep OS_

# add iptables rules
iptables -I INPUT 1 -i em1 -p tcp --dport 8080 -j ACCEPT
iptables -I INPUT 1 -i em1 -p tcp --dport 6000 -j ACCEPT
iptables -I INPUT 1 -i em1 -p tcp --dport 6001 -j ACCEPT
iptables -I INPUT 1 -i em1 -p tcp --dport 6002 -j ACCEPT
service iptables save

# create swift service in openstack
keystone user-create --name swift --pass redhat
keystone user-role-add --user swift --tenant services --role admin
keystone role-create --name SwiftOperator
keystone service-create --name swift --type object-store \
  --description "OpenStack Object Storage"
keystone endpoint-create --region RegionOne \
  --service-id $(keystone service-list | awk '/ object-store / {print $2}') \
  --publicurl 'http://10.19.137.100:8080/v1/AUTH_%(tenant_id)s' \
  --internalurl 'http://10.19.137.100:8080/v1/AUTH_%(tenant_id)s' \
  --adminurl 'http://10.19.137.100:8080' 

# install swift packages
yum install -y openstack-swift-proxy python-swiftclient python-keystoneclient \
  python-keystonemiddleware memcached

# config files
openstack-config --set /etc/swift/proxy-server.conf filter:authtoken admin_user swift
openstack-config --set /etc/swift/proxy-server.conf filter:authtoken admin_password redhat
openstack-config --set /etc/swift/proxy-server.conf filter:authtoken delay_auth_decision true
openstack-config --set /etc/swift/proxy-server.conf filter:authtoken admin_tenant_name services
openstack-config --set /etc/swift/proxy-server.conf filter:authtoken identity_uri http://10.19.137.100:35357
openstack-config --set /etc/swift/proxy-server.conf filter:authtoken auth_uri http://10.19.137.100:5000/v2.0

# create new swift rings
#swift-ring-builder /etc/swift/object.builder create 16 3 24
#swift-ring-builder /etc/swift/container.builder create 16 3 24
#swift-ring-builder /etc/swift/account.builder create 16 3 24
#swift-ring-builder /etc/swift/account.builder add z1-10.19.137.104:6002/sdb 10
#swift-ring-builder /etc/swift/container.builder add z1-10.19.137.104:6001/sdb 10
#swift-ring-builder /etc/swift/object.builder add z1-10.19.137.104:6000/sdb 10
#swift-ring-builder /etc/swift/account.builder add z2-10.19.137.105:6002/sdb 10
#swift-ring-builder /etc/swift/container.builder add z2-10.19.137.105:6001/sdb 10
#swift-ring-builder /etc/swift/object.builder add z2-10.19.137.105:6000/sdb 10
#swift-ring-builder /etc/swift/account.builder add z3-10.19.137.106:6002/sdb 10
#swift-ring-builder /etc/swift/container.builder add z3-10.19.137.106:6001/sdb 10
#swift-ring-builder /etc/swift/object.builder add z3-10.19.137.106:6000/sdb 10
#swift-ring-builder /etc/swift/account.builder rebalance
#swift-ring-builder /etc/swift/container.builder rebalance
#swift-ring-builder /etc/swift/object.builder rebalance
#
## distribute ring configuration
#cd /etc/swift
#tar cvfz /tmp/swift_configs.tgz swift.conf *.builder *.gz
#scp /tmp/swift_configs.tgz rhos4:/tmp
#scp /tmp/swift_configs.tgz rhos5:/tmp
#scp /tmp/swift_configs.tgz rhos6:/tmp
#chown -R root:swift /etc/swift
#
# disable and stop old swift services
#systemctl disable openstack-swift-account-auditor.service
#systemctl disable openstack-swift-account-reaper.service
#systemctl disable openstack-swift-account-replicator.service
#systemctl disable openstack-swift-account.service
#systemctl disable openstack-swift-container-auditor.service
#systemctl disable openstack-swift-container-replicator.service
#systemctl disable openstack-swift-container-updater.service
#systemctl disable openstack-swift-container.service
#systemctl disable openstack-swift-object-auditor.service
#systemctl disable openstack-swift-object-replicator.service
#systemctl disable openstack-swift-object-updater.service
#systemctl disable openstack-swift-object.service
#systemctl stop openstack-swift-account-auditor.service
#systemctl stop openstack-swift-account-reaper.service
#systemctl stop openstack-swift-account-replicator.service
#systemctl stop openstack-swift-account.service
#systemctl stop openstack-swift-container-auditor.service
#systemctl stop openstack-swift-container-replicator.service
#systemctl stop openstack-swift-container-updater.service
#systemctl stop openstack-swift-container.service
#systemctl stop openstack-swift-object-auditor.service
#systemctl stop openstack-swift-object-replicator.service
#systemctl stop openstack-swift-object-updater.service
#systemctl stop openstack-swift-object.service

# start swift
#systemctl start openstack-swift-proxy
#systemctl enable openstack-swift-proxy
#systemctl start openstack-swift-object-expirer
#systemctl enable openstack-swift-object-expirer
#firewall-cmd --add-port=8080/tcp
#firewall-cmd --add-port=8080/tcp --permanent
