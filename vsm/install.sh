#!/bin/bash
# Copyright (c) AstroArch Consulting, Inc.  2017-2024
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
VERSIONID="2.0.2"

###
docolor=1
# onscreen colors
RED=`tput setaf 1`
PURPLE=`tput setaf 5`
NC=`tput sgr0`
machine=`uname -m`
if [ Z"$machine" = Z"arm64" ]
then
	PATH=$PATH:/opt/homebrew/bin
	export PATH
fi
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
		if [ Z"$theos" = Z"linuxmint" ]
        	then
            		theos=`echo $ID_LIKE | tr [:upper:] [:lower:]`
        	fi
		VERSION_ID=`echo $VERSION_ID | awk -F. '{print $1}'`
	elif [ -e /etc/centos-release ]
	then
		theos=`cut -d' ' -f1 < /etc/centos-release | tr [:upper:] [:lower:]`
		VERSION_ID=`awk '{print $3}' /etc/centos-release | awk -F. '{print $1}'`
	elif [ -e /etc/redhat-release ]
	then
		theos=`cut -d' ' -f1 < /etc/redhat-release | tr [:upper:] [:lower:]`
		VERSION_ID=`awk '{print $3}' /etc/redhat-release | awk -F. '{print $1}'`
	elif [ -e /etc/fedora-release ]
	then
		theos=`cut -d' ' -f1 < /etc/fedora-release | tr [:upper:] [:lower:]`
		VERSION_ID=`awk '{print $3}' /etc/fedora-release | awk -F. '{print $1}'`
	elif [ -e /etc/debian-release ]
	then
		theos=`cut -d' ' -f1 < /etc/debian-release | tr [:upper:] [:lower:]`
		VERSION_ID=`awk '{print $3}' /etc/debian-release | awk -F. '{print $1}'`
	else
		# Mac OS
		uname -a | grep Darwin  >& /dev/null
		if [ $? -eq 0 ]
		then
			theos="macos"
			VERSION_ID=`sw_vers | grep ProductVersion | cut -d'	' -f2`
		else
			colorecho "Do not know this operating system. LinuxVSM may not work." 1
			theos="unknown"
		fi
	fi
	export VERSION_ID
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
	if [ Z"$tz" = Z"Etc/UTC" ]
	then
		tz=""
	fi
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
	elif [ Z"$theos" = Z"macos" ]
	then
		which brew >& /dev/null
		if [ $? -eq 1 ]
		then
			/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
		fi
		/opt/homebrew/bin/brew install wget
	fi
fi

mkdir aac-base
cd aac-base
wget -O aac-base.install https://raw.githubusercontent.com/Texiwill/aac-lib/master/base/aac-base.install
chmod +x aac-base.install

echo "oVer=\`grep VERSIONID  /usr/local/bin/vsm.sh | head -1 | sed 's/\.//g'| sed 's/VERSIONID=//'|sed 's/\"//g'\`" > update.sh
echo "nVer=\`wget -O - https://raw.githubusercontent.com/Texiwill/aac-lib/master/vsm/vsm.sh 2>/dev/null|grep VERSIONID | head -1 | sed 's/\.//g'| sed 's/VERSIONID=//'|sed 's/\"//g'\`" >> update.sh
cat >> update.sh << EOF
if [ \$nVer -gt \$oVer ]
then
	touch /tmp/updatevsm
	cd $HOME/aac-base
EOF
if [ Z"$tz" = Z"" ]
then
	./aac-base.install -u
	./aac-base.install -i LinuxVSM
	cat >> update.sh << EOF
	./aac-base.install -u
	./aac-base.install -i LinuxVSM
EOF
else
	./aac-base.install -u $tz
	./aac-base.install -i LinuxVSM $tz
	cat >> update.sh << EOF
	./aac-base.install -u $tz
	./aac-base.install -i LinuxVSM $tz
EOF
fi
cat >> update.sh << EOF
	rm -f /tmp/updatevsm
else
	echo "Nothing to update"
fi
EOF
chmod +x update.sh

colorecho "VSM is now in /usr/local/bin/vsm.sh"
