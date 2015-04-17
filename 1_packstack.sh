#!/bin/bash

# install ssh keys
for i in $(seq 0 6)
do
	SSH_COPY_ID_LEGACY=TRUE ssh-copy-id -i ~/.ssh/id_rsa.pub rhos$i
done

# install pdsh
tar xvf /pub/projects/rhos/icehouse/scripts/jliberma/HA/pdsh/pdsh-2.29.tar
cd pdsh-2.29/
yum install -y gcc
./configure --with-ssh --without-rsh --with-machines=/etc/pdsh/machines
make && make install 
mkdir /etc/pdsh

cat > /etc/pdsh/machines << EOF
rhos0
rhos1
rhos2
rhos3
rhos4
rhos5
rhos6
EOF
which pdsh

# configure pdsh alias
echo "alias pdsh='pdsh -R ssh'" >> ~/.bashrc
source ~/.bashrc
pdsh -a uptime

yum install -y openstack-packstack
#packstack --answer-file=/pub/projects/rhos/juno/scripts/jliberma/sahara/update/ans1.txt
packstack --answer-file=/pub/projects/rhos/juno/scripts/jliberma/sahara/update/ans2.txt
