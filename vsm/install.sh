#!/bin/sh
# Copyright (c) AstroArch Consulting, Inc.  2017,2018
# All rights reserved
#
# An installer for the Linux version of VMware Software Manager (VSM)
# with some added intelligence the intelligence is around what to download
# and picking up things available but not strictly listed, as well as
# bypassing packages not created yet
#
# Requires:
# wget 
#
# vim: tabstop=4 shiftwidth=4
function findos() {
	if [ -e /etc/os-release ]
	then
		. /etc/os-release
		theos=`echo $ID | tr [:upper:] [:lower:]`
	elif [ -e /etc/centos-release ]
	then
		theos=`cut -d' ' -f1 < /etc/centos-release | tr [:upper:] [:lower:]`
	elif [ -e /etc/redhat-release ]
	then
		theos=`cut -d' ' -f1 < /etc/redhat-release | tr [:upper:] [:lower:]`
	elif [ -e /etc/fedora-release ]
	then
		theos=`cut -d' ' -f1 < /etc/fedora-release | tr [:upper:] [:lower:]`
	elif [ -e /etc/debian-release ]
	then
		theos=`cut -d' ' -f1 < /etc/debian-release | tr [:upper:] [:lower:]`
	else
		colorecho "Do not know this operating system. LinuxVSM may not work." 1
		theos="unknown"
	fi
}

theos=''
findos
which wget >& /dev/null
if [ $? -eq 1 ]
then
	if [ Z"$theos" = Z"centos" ] || [ Z"$theos" = Z"redhat" ] || [ Z"$theos" = Z"fedora" ]
	then
        	sudo yum -y install wget
	elif [ Z"$theos" = Z"debian" ] || [ Z"$theos" = Z"ubuntu" ]
	then
        	sudo apt-get install -y wget
	fi
fi

wget -O aac-base.install https://raw.githubusercontent.com/Texiwill/aac-lib/master/base/aac-base.install
chmod +x aac-base.install
./aac-base.install -u
sudo ./aac-base.install -i vsm

echo "VSM is now in /usr/local/bin/vsm.sh"
