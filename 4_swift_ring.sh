#!/bin/bash

source /root/keystonerc_admin
env | grep OS_

# create new swift rings
swift-ring-builder /etc/swift/object.builder create 10 3 1
swift-ring-builder /etc/swift/container.builder create 10 3 1
swift-ring-builder /etc/swift/account.builder create 10 3 1
swift-ring-builder /etc/swift/account.builder add z1-10.19.137.104:6002/sdb 10
swift-ring-builder /etc/swift/container.builder add z1-10.19.137.104:6001/sdb 10
swift-ring-builder /etc/swift/object.builder add z1-10.19.137.104:6000/sdb 10
swift-ring-builder /etc/swift/account.builder add z2-10.19.137.105:6002/sdb 10
swift-ring-builder /etc/swift/container.builder add z2-10.19.137.105:6001/sdb 10
swift-ring-builder /etc/swift/object.builder add z2-10.19.137.105:6000/sdb 10
swift-ring-builder /etc/swift/account.builder add z3-10.19.137.106:6002/sdb 10
swift-ring-builder /etc/swift/container.builder add z3-10.19.137.106:6001/sdb 10
swift-ring-builder /etc/swift/object.builder add z3-10.19.137.106:6000/sdb 10

# verify the rings
swift-ring-builder /etc/swift/account.builder
swift-ring-builder /etc/swift/container.builder
swift-ring-builder /etc/swift/object.builder

# balance the rings
swift-ring-builder /etc/swift/account.builder rebalance
swift-ring-builder /etc/swift/container.builder rebalance
swift-ring-builder /etc/swift/object.builder rebalance

# distribute ring configuration
cd /etc/swift
tar cvfz /tmp/swift_configs.tgz swift.conf *.builder *.gz
scp /tmp/swift_configs.tgz rhos4:/tmp
scp /tmp/swift_configs.tgz rhos5:/tmp
scp /tmp/swift_configs.tgz rhos6:/tmp
scp /etc/swift/*.gz rhos4:/etc/swift
scp /etc/swift/*.gz rhos5:/etc/swift
scp /etc/swift/*.gz rhos6:/etc/swift
pdsh -w rhos[4-6] chown -R root:swift /etc/swift
