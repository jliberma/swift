#!/bin/bash -x
# install OSP via TripleO
set -x

# configure hosts
cat > /etc/hosts << EOF
172.16.2.100 	rhos0.osplocal.com
10.19.137.100   rhos0
172.31.137.100  rhos0-stor
127.0.0.1   	localhost localhost.localdomain localhost4 localhost4.localdomain4
172.16.2.101 	rhos1.osplocal.com
10.19.137.101   rhos1
172.31.137.101  rhos1-stor
172.16.2.102 	rhos2.osplocal.com
10.19.137.102   rhos2
172.31.137.102  rhos2-stor
172.16.2.103 	rhos3.osplocal.com
10.19.137.103   rhos3
172.31.137.103  rhos3-stor
172.16.2.104 	rhos4.osplocal.com
10.19.137.104   rhos4
172.31.137.104  rhos4-stor
172.16.2.105 	rhos5.osplocal.com
10.19.137.105   rhos5
172.31.137.105  rhos5-stor
172.16.2.106 	rhos6.osplocal.com
10.19.137.106   rhos6
172.31.137.106  rhos6-stor
10.19.143.248   refarch.cloud.lab.eng.bos.redhat.com
10.19.143.247   ra-ns1.cloud.lab.eng.bos.redhat.com
EOF

# configure ssh
echo "UserKnownHostsFile /dev/null" > /root/.ssh/config
echo "StrictHostKeyChecking no" >> /root/.ssh/config
echo "LogLevel quiet" >> /root/.ssh/config
restorecon -Rv /root/.ssh

# copy ssh keys
rm -f ~/.ssh/id_rsa*

# configure the mgmt server
ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa

# configure repos
rpm -Uvh http://rhos-release.virt.bos.redhat.com/repos/rhos-release/rhos-release-latest.noarch.rpm
rhos-release 6 -p A2
yum clean all
yum repolist
yum update -y

# disable ntpd
systemctl disable ntpd.service
systemctl stop ntpd.service

# configure networking
declare -a ext_mac=(54:9F:35:F6:70:21 54:9F:35:F6:70:2E 54:9F:35:F6:70:3B 54:9f:35:f6:70:48 54:9F:35:F6:70:55 54:9F:35:F6:70:62 54:9F:35:F6:70:6F 90:b1:1c:56:33:2a d4:ae:52:b2:1c:36 d4:ae:52:b2:2e:7f)
declare -a pro_mac=(54:9F:35:F6:70:22 54:9F:35:F6:70:2F 54:9F:35:F6:70:3C 54:9f:35:f6:70:49 54:9F:35:F6:70:56 54:9F:35:F6:70:63 54:9F:35:F6:70:70 90:b1:1c:56:33:2c d4:ae:52:b2:1c:37 d4:ae:52:b2:2e:80)
declare -a str_mac=(54:9F:35:F6:70:28 54:9f:35:f6:70:35 54:9f:35:f6:70:42 54:9f:35:f6:70:4F 54:9F:35:F6:70:5C 54:9F:35:F6:70:69 54:9F:35:F6:70:76 90:b1:1c:56:33:26 90:e2:ba:20:bf:7c 90:e2:ba:20:c7:50)
declare -a ten_mac=(54:9F:35:F6:70:25 54:9f:35:f6:70:32 54:9f:35:f6:70:3F 54:9f:35:f6:70:4C 54:9F:35:F6:70:59 54:9F:35:F6:70:66 54:9F:35:F6:70:73 90:b1:1c:56:33:28 90:e2:ba:20:bf:7d 90:E2:BA:20:C7:51)

# back up orig interface files
for j in $(ls /etc/sysconfig/network-scripts/ifcfg-* | grep -v ifcfg-lo)
do
	mv $j $j.orig
done

# set server number
i=$(hostname -s | awk '{print substr($1,length($1),1)}')

# configure external interface
tee /etc/sysconfig/network-scripts/ifcfg-em1 <<EOF
DEVICE="em1"
NAME="em1"
HWADDR=${ext_mac[$i]}
ONBOOT=yes
NETBOOT=yes
BOOTPROTO=dhcp
TYPE=Ethernet
DEFROUTE=yes
NM_CONTROLLED=no
EOF

# set provisioning interface name
pro_int=em2
if (hostname -s | grep rhos[8-9] > /dev/null)
then 
	pro_int=em2
fi

# configure provisioning interface
tee /etc/sysconfig/network-scripts/ifcfg-$pro_int <<EOF
DEVICE="$pro_int"
NAME="$pro_int"
HWADDR=${pro_mac[$i]}
ONBOOT=yes
BOOTPROTO=static
NM_CONTROLLED=no
IPADDR=172.16.2.10$i
NETMASK=255.255.255.0
EOF
ifup $pro_int
ping -c 3 172.16.2.10$i
ping -c 3 172.16.2.100

# configure tenant interface
tee /etc/sysconfig/network-scripts/ifcfg-p3p1 <<EOF
DEVICE="p3p1"
NAME="p3p1"
HWADDR=${ten_mac[$i]}
ONBOOT=yes
BOOTPROTO=static
NM_CONTROLLED=no
IPADDR=172.16.3.10$i
NETMASK=255.255.255.0
EOF
ifup p3p1
ping -c 3 172.16.3.10$i

# configure storage interface
tee /etc/sysconfig/network-scripts/ifcfg-p3p2 <<EOF
DEVICE="p3p2"
NAME="p3p2"
HWADDR=${str_mac[$i]}
ONBOOT=yes
BOOTPROTO=static
NM_CONTROLLED=no
IPADDR=172.31.137.10$i
NETMASK=255.255.0.0
EOF
ifup p3p2
ping -c 3 172.31.143.200

# disable device renaming at boot
#sed -i 's/rhgb quiet/rhgb quiet net.ifnames=0/' /boot/grub2/grub.cfg
sed -i.orig 's/quiet"/quiet net.ifnames=0 biosdevname=0"/' /etc/sysconfig/grub
grub2-mkconfig  -o /boot/grub2/grub.cfg

# disable/remove NetworkManager
systemctl disable NetworkManager.service
systemctl stop NetworkManager.service
yum remove -y NetworkManager*

shutdown -r now
