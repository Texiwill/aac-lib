#!/bin/bash
#
# Copyright (c) AstroArch Consulting, Inc.  2018-2023
# All rights reserved
#
# vim: tabstop=4 shiftwidth=4
#
# Build a VAMI update repository from the repo used by LinuxVSM
#
# Requires:
# LinuxVSM
#

# Create a VAMI repository out of VSM Repo
VERSIONID="1.0.1"

# args: stmt error
function colorecho() {
	COLOR=$PURPLE
	if [ Z"$2" = Z"1" ]
	then
		COLOR=$RED
	fi
	if [ $debugv -ne 2 ]
	then
		if [ $docolor -eq 1 ]
		then
			echo "${COLOR}${1}${NC}"
		else
			echo ${1}
		fi
	fi
}

function debugecho() {
	if [ $dodebug -eq 1 ]
	then
		echo ${1}
	fi
}

function usage() {
	echo "$0 [-t|--target tgtName] [-f|--force][-d|--debug][-h|--help]"
cat << EOF
	Uses LinuxVSM repo as target unless tgtName specified.
EOF
	exit
}

function load_vsmrc() {
	if [ -e $HOME/.vsmrc ]
	then
		vsmrc="$HOME/.vsmrc"
		. $HOME/.vsmrc
	elif [ -e "$repo/.vsmrc" ]
	then
		vsmrc="$repo/.vsmrc"
		. $repo/.vsmrc
	elif [ -e "$cdir/.vsmrc" ]
	then
		vsmrc="$cdir/.vsmrc"
		. $cdir/.vsmrc
	else
		# nothing there default
		vsmrc="$HOME/.vsmrc"
	fi
}

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
		# Mac OS
		uname -a | grep Darwin  >& /dev/null
		if [ $? -eq 0 ]
		then
			theos="macos"
		else
			colorecho "Do not know this operating system. LinuxVSM may not work." 1
			theos="unknown"
		fi
	fi
}

function checkdep() {
	dep=$1
	if [ Z"$theos" = Z"centos" ] || [ Z"$theos" = Z"redhat" ] || [ Z"$theos" = Z"fedora" ]
	then
		rpm -q $dep > /dev/null
		if [ $? -eq 1 ]
		then
			echo "Missing Dependency $dep"
			needdep=1
		fi
	fi
	if [ Z"$theos" = Z"debian" ] || [ Z"$theos" = Z"ubuntu" ]
	then
		dpkg -s $dep >& /dev/null
		if [ $? -eq 1 ]
		then
			echo "Missing Dependency $dep"
			needdep=1
		fi
	fi
	if [ Z"$theos" = Z"macos" ]
	then
		if [ Z"$dep" = Z"xcodebuild" ]
		then
			which $dep  >& /dev/null
			if [ $? -eq 1 ]
			then
				echo "Missing Dependency Xcode"
				needdep=1
			fi
		elif [ Z"$dep" = Z"jq" ] || [ Z"$dep" = Z"wget" ] || [ Z"$dep" = Z"gnu-sed" ]
		then
			z=$dep
			if [ Z"$z" = Z"gnu-sed" ]
			then
				z="sed"
			fi
			which $z  >& /dev/null
			if [ $? -eq 1 ]
			then
				t="Not in PATH"
				brew list | grep $dep >& /dev/null
				if [ $? -eq 1 ]
				then
					t="Not Installed"
				fi
				echo "$t Dependency $dep"
				needdep=1
			fi
		elif [ Z"$dep" = Z"urllib2" ]
		then
			python -c "help('modules')" 2>/dev/null | grep $dep >& /dev/null
			if [ $? -eq 1 ]
			then
				echo "Missing Dependency $dep"
				needdep=1
			fi
		else
			which $dep  >& /dev/null
			if [ $? -eq 1 ]
			then
				echo "Missing Dependency $dep"
				needdep=1
			fi
		fi
	fi
	if [ Z"$theos" = Z"unknown" ]
	then
		colorecho "Cannot Check Dependency $dep." 1
	fi
}

# set language to English
LANG=en_US.utf8
export LANG
# check dependencies
theos=''
needdep=0
RED=`tput setaf 1`
PURPLE=`tput setaf 5`
NC=`tput sgr0`
BOLD=`tput smso`
NB=`tput rmso`
TEAL=`tput setaf 6`
docolor=0
findos
checkdep nginx

if [ $needdep -eq 1 ]
then
	colorecho "Install dependencies first!" 1
	exit
fi

vdir=`grep root /etc/nginx/*.d/*.conf /etc/nginx/nginx.conf 2>/dev/null| grep -v \#| awk '{print $3}'`


# onscreen colors
dodebug=0
debugv=0
doforce=0
repo='/tmp/vsm'
load_vsmrc
tgt=$repo

while [[ $# -gt 0 ]]
do
	key="$1"
	case "$key" in
		-t|--target)
			tgt=$2
			shift
			;;
		-f|--force)
			doforce=1
			;;
		-d|--debug)
			debugv=1
			dodebug=1
			;;
		-h|--help)
			usage
			;;
		*)
			usage
			;;
	esac
	shift
done

if [ ! -e $tgt/VAMI ]
then
	mkdir $tgt/VAMI
fi

colorecho "Setup NGINX VAMI Repo!"


for x in `find $repo -name '*updaterepo*.zip' -print`
do
	f=`basename $x`
	z=`dirname $x`
	d=`basename $z`

	# once more
	if [ Z"$d" = Z"DriversTools" ]
	then
		z=`dirname $z`
		d=`basename $z`
	fi

	debugecho "DEBUG: $f $d"

	debugecho "$d"
	cd $tgt/VAMI
	# Make directory in VAMI
	echo -n '.'
	if [ ! -e $d ]
	then
		mkdir $d
		cd $d
		unzip $x >& /dev/null
		# need to move manifest & package-pool to toplevel, 
		# remove all else
		if [ ! -e manifest ]
		then
			m=`find . -type d -name manifest -print`
			n=`dirname $m`
			o=`echo $n | cut -d/ -f2`
			mv $m .
			mv $n/package-pool .
			if [ ${#o} -gt 3 ]
			then
				rm -rf $o
			fi
		fi
	fi
done
echo ''
colorecho "VAMI Repo is in ${tgt}/VAMI"
missingdir=0
optiondirs=''
for x in $vdir
do
	if [ ! -e $x ] || [ ! -e ${x}/VAMI ]
	then
		optiondirs="$optiondirs
	sudo ln -s $tgt/VAMI ${x}"
		missingdir=1
	else
		optiondirs="NGINX VAMI Directory = ${x}"
		missingdir=0
		break
	fi
done
if [ $missingdir -eq 1 ]
then
	colorecho "Missing NGINX VAMI Directory, use one of:" 1
	echo -e $optiondirs
	#exit
fi
