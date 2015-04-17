#!/bin/bash

source /root/keystonerc_admin
env | grep OS_

# configure hash path suffix
openstack-config --set /etc/swift/swift.conf swift-hash swift_hash_path_suffix $(openssl rand -hex 10)

# propogate swift.conf
scp /etc/swift/swift.conf rhos4:/etc/swift
scp /etc/swift/swift.conf rhos5:/etc/swift
scp /etc/swift/swift.conf rhos6:/etc/swift
pdsh -w rhos[4-6] chown -R swift:swift /etc/swift
pdsh -w rhos[4-6] restorecon -R /etc/swift

# start the services
systemctl enable openstack-swift-proxy.service memcached.service
systemctl start openstack-swift-proxy.service memcached.service


# enable the service
pdsh -w rhos[4-6] systemctl enable openstack-swift-account
pdsh -w rhos[4-6] systemctl enable openstack-swift-container
pdsh -w rhos[4-6] systemctl enable openstack-swift-object

# start the services
pdsh -w rhos[4-6] systemctl start openstack-swift-account
pdsh -w rhos[4-6] systemctl start openstack-swift-container
pdsh -w rhos[4-6] systemctl start openstack-swift-object
