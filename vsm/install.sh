#!/bin/bash
# Copyright (c) AstroArch Consulting, Inc.  2017-2023
# All rights reserved
# vim: tabstop=4 shiftwidth=4
#
# An installer for the Linux version of VMware Software Manager (VSM)
# with some added intelligence the intelligence is around what to download
# and picking up things available but not strictly listed, as well as
# bypassing packages not created yet
#
# Requires:
# wget 
#
docolor=1
# onscreen colors
RED=`tput setaf 1`
PURPLE=`tput setaf 5`
NC=`tput sgr0`
function colorecho() {
	COLOR=$PURPLE
	if [ Z"$2" = Z"1" ]
	then
		COLOR=$RED
	fi
	if [ $docolor -eq 1 ]
	then
		echo "${COLOR}${1}${NC}"
	else
		echo ${1}
	fi
}
function findos() {
	if [ -e /etc/os-release ]
	then
		. /etc/os-release
		theos=`echo $ID | tr [:upper:] [:lower:]`
		ver=`echo $VERSION_ID | awk -F. '{print $1'}`
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

function usage()
{
	#echo "$0 [-h|--help][-u|--user user][timezone]"
	echo "$0 [-h|--help][timezone]"
}

while [[ $# -gt 0 ]]
do
	key="$1"
	case "$key" in
		-h|--help)
			usage
			exit
			;;
		#-u|--user) 
		#	us=$2
		#	shift
		#	;;
		*)
			atz=$1
			;;
	esac
	shift
done

tz=$atz
if [ Z"$atz" = Z"" ]
then
	tz=`ls -l /etc/localtime|awk -F/ '{printf "%s/%s",$(NF-1),$NF}'`
fi

theos=''
findos
which wget >& /dev/null
if [ $? -eq 1 ]
then
	if [ Z"$theos" = Z"centos" ] || [ Z"$theos" = Z"redhat" ] || [ Z"$theos" = Z"fedora" ] || [ Z"$theos" = Z"rocky" ] || [ Z"$theos" = Z"almalinux" ]
	then
		if [ $ver -lt 8 ]
		then
        	sudo yum -y install wget
		else
        	sudo dnf -y install wget
		fi
	elif [ Z"$theos" = Z"debian" ] || [ Z"$theos" = Z"ubuntu" ]
	then
        	sudo apt-get install -y wget
	fi
fi

mkdir aac-base
cd aac-base
wget -O aac-base.install https://raw.githubusercontent.com/Texiwill/aac-lib/master/base/aac-base.install
chmod +x aac-base.install

./aac-base.install -u $tz
./aac-base.install -i LinuxVSM $tz

cat > update.sh << EOF
cd $HOME/aac-base
./aac-base.install -u $tz
./aac-base.install -i LinuxVSM $tz
EOF
chmod +x update.sh

colorecho "VSM is now in /usr/local/bin/vsm.sh"
