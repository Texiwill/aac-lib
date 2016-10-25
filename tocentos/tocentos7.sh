#!/bin/sh
#
# Copyright (c) 2015,2016 AstroArch Consulting, Inc. All rights reserved
#
# Convert an install from RHEL 7 to Centos 7
#
###
# Reference: http://jensd.be/32/linux/migrate-rhel7-to-centos7
###
if [ ! -e /etc/redhat-release ]
then
	echo "Already at CentOS"
	exit
fi

### Setup Constants - need major release not minor
rel=`awk -F'release' '{print $2}' /etc/redhat-release  | awk '{print $1}' | awk -F. '{print $1}'`
arch=`uname -i`

### Setup Directories
rm -rf /tmp/centos
mkdir /tmp/centos
cd /tmp/centos

### Get the CentOS Bits
wget http://mirror.centos.org/centos/$rel/os/$arch/RPM-GPG-KEY-CentOS-7
curl http://mirror.centos.org/centos/$rel/os/$arch/Packages/ > /tmp/centos/centos$$
centosrelease=`grep centos-release /tmp/centos/centos$$ | sed 's/<.*rpm">//' | sed 's/<.*//'`
centosindexhtml=`grep centos-indexhtml /tmp/centos/centos$$ | sed 's/<.*rpm">//' | sed 's/<.*//'`
yum=`grep \>yum /tmp/centos/centos$$ | egrep -v yum-[a-z]|egrep -v yum-N | sed 's/<.*rpm">//' | sed 's/<.*//'`
yumplugin=`grep yum-plugin-fastestmirror /tmp/centos/centos$$ | sed 's/<.*rpm">//' | sed 's/<.*//'`

if [ X"$yum" = X"" ]
then
	echo "No files in CentOS Repository found"
	exit
fi
wget http://mirror.centos.org/centos/$rel/os/$arch/Packages/$centosrelease
wget http://mirror.centos.org/centos/$rel/os/$arch/Packages/$centosindexhtml
wget http://mirror.centos.org/centos/$rel/os/$arch/Packages/$yum
wget http://mirror.centos.org/centos/$rel/os/$arch/Packages/$yumplugin

if [ ! -e $yum ]
then
	echo "No Files Downloaded"
	exit
fi

### GPG Key
rpm --import RPM-GPG-KEY-CentOS-6

### Remove RedHat rpms
yum -y remove remove rhnlib redhat-support-tool redhat-support-lib-python
rpm -e --nodeps redhat-release-server redhat-logos yum
rm -rf /usr/share/doc/redhat-release /usr/share/redhat-release

### Remove Subscription Manager if using it
subscription-manager clean
yum -y remove subscription-manager
yum-config-manager --disable rhel-7-server-rpms

### Force install the CentOS RPMs we downloaded
rpm -Uvh --force *.rpm

### Clean up yum one more time and then upgrade
yum clean all
yum -y upgrade

### Mkconfig required
grub2-mkconfig -o /boot/grub2/grub.cfg

### Reboot
sudo init 6
