set -x

vmSize=${7}
SUBEMAIL=${8}
SUBID=${9}
SUBURL=${10}

#if needed, register the machine
if [ "$SUBEMAIL" != "" ]; then
  if [ "$SUBURL" != "" ]; then 
   SUSEConnect -e $SUBEMAIL -r $SUBID --url $SUBURL
  else 
   SUSEConnect -e $SUBEMAIL -r $SUBID
  fi
fi

#get the VM size via the instance api
VMSIZE=`curl -H Metadata:true "http://169.254.169.254/metadata/instance/compute/vmSize?api-version=2017-08-01&format=text"`


#install hana prereqs
zypper install -y glibc-2.22-51.6
zypper install -y systemd-228-142.1
zypper install -y unrar
zypper install -y sapconf
zypper install -y saptune
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

# this assumes that 5 disks are attached at lun 0 through 4
echo "Creating partitions and physical volumes"
pvcreate -ff -y /dev/disk/azure/scsi1/lun0   
pvcreate -ff -y  /dev/disk/azure/scsi1/lun1
pvcreate -ff -y  /dev/disk/azure/scsi1/lun2
pvcreate -ff -y  /dev/disk/azure/scsi1/lun3
pvcreate -ff -y  /dev/disk/azure/scsi1/lun4
pvcreate -ff -y  /dev/disk/azure/scsi1/lun5

if [ $VMSIZE == "Standard_E16s_v3" ] || [ "$VMSIZE" == "Standard_E32s_v3" ] || [ "$VMSIZE" == "Standard_E64s_v3" ] || [ "$VMSIZE" == "Standard_GS5" ] || [ "$VMSIZE" == "Standard_M32ts" ] || [ "$VMSIZE" == "Standard_M32ls" ] || [ "$VMSIZE" == "Standard_M64ls" ] || [ $VMSIZE == "Standard_DS14_v2" ] ; then
echo "logicalvols start" >> /tmp/parameter.txt
  #shared volume creation
  sharedvglun="/dev/disk/azure/scsi1/lun0"
  vgcreate sharedvg $sharedvglun
  lvcreate -l 100%FREE -n sharedlv sharedvg 
 
  #usr volume creation
  usrsapvglun="/dev/disk/azure/scsi1/lun1"
  vgcreate usrsapvg $usrsapvglun
  lvcreate -l 100%FREE -n usrsaplv usrsapvg

  #backup volume creation
  backupvglun="/dev/disk/azure/scsi1/lun2"
  vgcreate backupvg $backupvglun
  lvcreate -l 100%FREE -n backuplv backupvg 

  #data volume creation
  datavg1lun="/dev/disk/azure/scsi1/lun3"
  datavg2lun="/dev/disk/azure/scsi1/lun4"
  datavg3lun="/dev/disk/azure/scsi1/lun5"
  vgcreate datavg $datavg1lun $datavg2lun $datavg3lun
  PHYSVOLUMES=3
  STRIPESIZE=64
  lvcreate -i$PHYSVOLUMES -I$STRIPESIZE -l 70%FREE -n datalv datavg
  lvcreate -i$PHYSVOLUMES -I$STRIPESIZE -l 100%FREE -n loglv datavg


  mkfs.xfs /dev/datavg/datalv
  mkfs.xfs /dev/datavg/loglv
  mkfs -t xfs /dev/sharedvg/sharedlv 
  mkfs -t xfs /dev/backupvg/backuplv 
  mkfs -t xfs /dev/usrsapvg/usrsaplv
  mount -t xfs /dev/datavg/loglv /hana/log 
  echo "/dev/mapper/datavg-loglv /hana/log xfs defaults 0 0" >> /etc/fstab
echo "logicalvols end" >> /tmp/parameter.txt
fi

if [ $VMSIZE == "Standard_M64s" ]; then
  #this is the medium size
  # this assumes that 6 disks are attached at lun 0 through 5
  echo "Creating partitions and physical volumes"
  pvcreate -ff -y  /dev/disk/azure/scsi1/lun6
  pvcreate -ff -y  /dev/disk/azure/scsi1/lun7
  pvcreate -ff -y /dev/disk/azure/scsi1/lun8
  pvcreate -ff -y /dev/disk/azure/scsi1/lun9

  echo "logicalvols start" >> /tmp/parameter.txt
  #shared volume creation
  sharedvglun="/dev/disk/azure/scsi1/lun0"
  vgcreate sharedvg $sharedvglun
  lvcreate -l 100%FREE -n sharedlv sharedvg 
 
  #usr volume creation
  usrsapvglun="/dev/disk/azure/scsi1/lun1"
  vgcreate usrsapvg $usrsapvglun
  lvcreate -l 100%FREE -n usrsaplv usrsapvg

  #backup volume creation
  backupvg1lun="/dev/disk/azure/scsi1/lun2"
  backupvg2lun="/dev/disk/azure/scsi1/lun3"
  vgcreate backupvg $backupvg1lun $backupvg2lun
  lvcreate -l 100%FREE -n backuplv backupvg 

  #data volume creation
  datavg1lun="/dev/disk/azure/scsi1/lun4"
  datavg2lun="/dev/disk/azure/scsi1/lun5"
  datavg3lun="/dev/disk/azure/scsi1/lun6"
  datavg4lun="/dev/disk/azure/scsi1/lun7"
  vgcreate datavg $datavg1lun $datavg2lun $datavg3lun $datavg4lun
  PHYSVOLUMES=4
  STRIPESIZE=64
  lvcreate -i$PHYSVOLUMES -I$STRIPESIZE -l 100%FREE -n datalv datavg

  #log volume creation
  logvg1lun="/dev/disk/azure/scsi1/lun8"
  logvg2lun="/dev/disk/azure/scsi1/lun9"
  vgcreate logvg $logvg1lun $logvg2lun
  PHYSVOLUMES=2
  STRIPESIZE=32
  lvcreate -i$PHYSVOLUMES -I$STRIPESIZE -l 100%FREE -n loglv logvg
  mount -t xfs /dev/logvg/loglv /hana/log 
echo "/dev/mapper/logvg-loglv /hana/log xfs defaults 0 0" >> /etc/fstab

  mkfs.xfs /dev/datavg/datalv
  mkfs.xfs /dev/logvg/loglv
  mkfs -t xfs /dev/sharedvg/sharedlv 
  mkfs -t xfs /dev/backupvg/backuplv 
  mkfs -t xfs /dev/usrsapvg/usrsaplv
echo "logicalvols end" >> /tmp/parameter.txt
fi

if [ $VMSIZE == "Standard_M64ms" ] || [ $VMSIZE == "Standard_M128s" ]; then

  # this assumes that 6 disks are attached at lun 0 through 9
  echo "Creating partitions and physical volumes"
  pvcreate -ff -y  /dev/disk/azure/scsi1/lun6
  pvcreate -ff -y  /dev/disk/azure/scsi1/lun7
  pvcreate  -ff -y /dev/disk/azure/scsi1/lun8

  echo "logicalvols start" >> /tmp/parameter.txt
  #shared volume creation
  sharedvglun="/dev/disk/azure/scsi1/lun0"
  vgcreate sharedvg $sharedvglun
  lvcreate -l 100%FREE -n sharedlv sharedvg 
 
  #usr volume creation
  usrsapvglun="/dev/disk/azure/scsi1/lun1"
  vgcreate usrsapvg $usrsapvglun
  lvcreate -l 100%FREE -n usrsaplv usrsapvg

  #backup volume creation
  backupvg1lun="/dev/disk/azure/scsi1/lun2"
  backupvg2lun="/dev/disk/azure/scsi1/lun3"
  vgcreate backupvg $backupvg1lun $backupvg2lun
  lvcreate -l 100%FREE -n backuplv backupvg 

  #data volume creation
  datavg1lun="/dev/disk/azure/scsi1/lun4"
  datavg2lun="/dev/disk/azure/scsi1/lun5"
  datavg3lun="/dev/disk/azure/scsi1/lun6"
  vgcreate datavg $datavg1lun $datavg2lun $datavg3lun 
  PHYSVOLUMES=3
  STRIPESIZE=64
  lvcreate -i$PHYSVOLUMES -I$STRIPESIZE -l 100%FREE -n datalv datavg

  #log volume creation
  logvg1lun="/dev/disk/azure/scsi1/lun7"
  logvg2lun="/dev/disk/azure/scsi1/lun8"
  vgcreate logvg $logvg1lun $logvg2lun
  PHYSVOLUMES=2
  STRIPESIZE=32
  lvcreate -i$PHYSVOLUMES -I$STRIPESIZE -l 100%FREE -n loglv logvg
  mount -t xfs /dev/logvg/loglv /hana/log   
echo "/dev/mapper/logvg-loglv /hana/log xfs defaults 0 0" >> /etc/fstab

  mkfs.xfs /dev/datavg/datalv
  mkfs.xfs /dev/logvg/loglv
  mkfs -t xfs /dev/sharedvg/sharedlv 
  mkfs -t xfs /dev/backupvg/backuplv 
  mkfs -t xfs /dev/usrsapvg/usrsaplv
echo "logicalvols end" >> /tmp/parameter.txt
fi

if [ $VMSIZE == "Standard_M128ms" || [ $VMSIZE == "Standard_M208ms_v2" ]; then

  # this assumes that 6 disks are attached at lun 0 through 5
  echo "Creating partitions and physical volumes"
  pvcreate -ff -y  /dev/disk/azure/scsi1/lun6
  pvcreate -ff -y  /dev/disk/azure/scsi1/lun7
  pvcreate  -ff -y /dev/disk/azure/scsi1/lun8
  pvcreate  -ff -y /dev/disk/azure/scsi1/lun9
  pvcreate  -ff -y /dev/disk/azure/scsi1/lun10

  echo "logicalvols start" >> /tmp/parameter.txt
  #shared volume creation
  sharedvglun="/dev/disk/azure/scsi1/lun0"
  vgcreate sharedvg $sharedvglun
  lvcreate -l 100%FREE -n sharedlv sharedvg 
 
  #usr volume creation
  usrsapvglun="/dev/disk/azure/scsi1/lun1"
  vgcreate usrsapvg $usrsapvglun
  lvcreate -l 100%FREE -n usrsaplv usrsapvg

  #backup volume creation
  backupvg1lun="/dev/disk/azure/scsi1/lun2"
  backupvg2lun="/dev/disk/azure/scsi1/lun3"
  vgcreate backupvg $backupvg1lun $backupvg2lun
  lvcreate -l 100%FREE -n backuplv backupvg 

  #data volume creation
  datavg1lun="/dev/disk/azure/scsi1/lun4"
  datavg2lun="/dev/disk/azure/scsi1/lun5"
  datavg3lun="/dev/disk/azure/scsi1/lun6"
  datavg4lun="/dev/disk/azure/scsi1/lun7"
  datavg5lun="/dev/disk/azure/scsi1/lun8"
  vgcreate datavg $datavg1lun $datavg2lun $datavg3lun $datavg4lun $datavg5lun
  PHYSVOLUMES=4
  STRIPESIZE=64
  lvcreate -i$PHYSVOLUMES -I$STRIPESIZE -l 100%FREE -n datalv datavg

  #log volume creation
  logvg1lun="/dev/disk/azure/scsi1/lun9"
  logvg2lun="/dev/disk/azure/scsi1/lun10"
  vgcreate logvg $logvg1lun $logvg2lun
  PHYSVOLUMES=2
  STRIPESIZE=32
  lvcreate -i$PHYSVOLUMES -I$STRIPESIZE -l 100%FREE -n loglv logvg
  mount -t xfs /dev/logvg/loglv /hana/log 
  echo "/dev/mapper/logvg-loglv /hana/log xfs defaults 0 0" >> /etc/fstab

  mkfs.xfs /dev/datavg/datalv
  mkfs.xfs /dev/logvg/loglv
  mkfs -t xfs /dev/sharedvg/sharedlv 
  mkfs -t xfs /dev/backupvg/backuplv 
  mkfs -t xfs /dev/usrsapvg/usrsaplv
fi

#!/bin/bash
echo "mounthanashared start" >> /tmp/parameter.txt
mount -t xfs /dev/sharedvg/sharedlv /hana/shared
mount -t xfs /dev/backupvg/backuplv /hana/backup 
mount -t xfs /dev/usrsapvg/usrsaplv /usr/sap
mount -t xfs /dev/datavg/datalv /hana/data
echo "mounthanashared end" >> /tmp/parameter.txt

echo "write to fstab start" >> /tmp/parameter.txt
echo "/dev/mapper/datavg-datalv /hana/data xfs defaults 0 0" >> /etc/fstab
echo "/dev/mapper/sharedvg-sharedlv /hana/shared xfs defaults 0 0" >> /etc/fstab
echo "/dev/mapper/backupvg-backuplv /hana/backup xfs defaults 0 0" >> /etc/fstab
echo "/dev/mapper/usrsapvg-usrsaplv /usr/sap xfs defaults 0 0" >> /etc/fstab
echo "write to fstab end" >> /tmp/parameter.txt

#put host entry in hosts file using instance metadata api
VMIPADDR=`curl -H Metadata:true "http://169.254.169.254/metadata/instance/network/interface/0/ipv4/ipAddress/0/privateIpAddress?api-version=2017-08-01&format=text"`
VMNAME=`hostname`
cat >>/etc/hosts <<EOF
$VMIPADDR $VMNAME
EOF