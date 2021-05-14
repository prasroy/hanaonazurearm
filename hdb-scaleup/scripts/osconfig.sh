#!/bin/bash
#Author : Prasenjit Roy
#set -x
#get the VM size via the instance api
VMSIZE=`curl -H Metadata:true "http://169.254.169.254/metadata/instance/compute/vmSize?api-version=2017-08-01&format=text"`

#install hana prereqs
useradd 
zypper install -y glibc-2.22-51.6
zypper install -y systemd-228-142.1
zypper install -y unrar
zypper install -y sapconf
zypper install -y saptune
zypper install -y libatomic1
mkdir /etc/systemd/login.conf.d
mkdir /hana
mkdir /hana/data
mkdir /hana/log
mkdir /hana/shared
mkdir /hana/backup
mkdir /usr/sap

zypper in -t pattern -y sap-hana
saptune solution apply HANA
saptune daemon start

# step2
echo $Uri >> /tmp/url.txt

cp -f /etc/waagent.conf /etc/waagent.conf.orig
sedcmd="s/ResourceDisk.EnableSwap=n/ResourceDisk.EnableSwap=y/g"
sedcmd2="s/ResourceDisk.SwapSizeMB=0/ResourceDisk.SwapSizeMB=2048/g"
cat /etc/waagent.conf | sed $sedcmd | sed $sedcmd2 > /etc/waagent.conf.new
cp -f /etc/waagent.conf.new /etc/waagent.conf

#don't restart waagent, as this will kill the custom script.
#service waagent restart

# this assumes that only one managed disks are attached at lun 0 and rest of the volume will be NetApp files
echo "Creating partitions and physical volumes"
pvcreate -ff -y /dev/disk/azure/scsi1/lun0

echo "logicalvols start" >> /tmp/parameter.txt
    #usr volume creation
usrsapvglun="/dev/disk/azure/scsi1/lun0"
vgcreate usrsapvg $usrsapvglun
lvcreate -l 100%FREE -n usrsaplv usrsapvg 

 # Formatting and mounting the volume
mkfs -t xfs /dev/usrsapvg/usrsaplv
mount -t xfs /dev/datavg/loglv /hana/log 
echo "/dev/mapper/datavg-loglv /hana/log xfs defaults 0 0" >> /etc/fstab
echo "logicalvols end" >> /tmp/parameter.txt

#!/bin/bash
echo "mounthanavolumes start" >> /tmp/parameter.txt 
mount -t xfs /dev/usrsapvg/usrsaplv /usr/sap
echo "mounthanavoluems end" >> /tmp/parameter.txt

echo "write to fstab start" >> /tmp/parameter.txt
echo "/dev/mapper/usrsapvg-usrsaplv /usr/sap xfs defaults 0 0" >> /etc/fstab
echo "write to fstab end" >> /tmp/parameter.txt

#put host entry in hosts file using instance metadata api
VMIPADDR=`curl -H Metadata:true "http://169.254.169.254/metadata/instance/network/interface/0/ipv4/ipAddress/0/privateIpAddress?api-version=2017-08-01&format=text"`
VMNAME=`hostname`
cat >>/etc/hosts <<EOF
$VMIPADDR $VMNAME
EOF