#!/bin/sh
#
# Copyright (c) 2015 AstroArch Consulting, Inc. All rights reserved
#
# Convert an install from RHEL to Centos for versions 6 or 7, etc.
#
###

# easy way
if [ -e /etc/os-release ]
then
	. /etc/os-release
	if [ X"$REDHAT_SUPPORT_PRODUCT" = X"centos" ]
	then
		echo "Already at CentOS"
		exit
	fi

	rel=`echo ${VERSION_ID} | awk -F\. '{print $1}'`
else
	#hard way
	grep -v 'CentOS' /etc/redhat-release >& /dev/null
	if [ $? = 0 ]
	then
		echo "Already at CentOS"
		exit
	fi
	rel=`awk -F'release' '{print $2}' /etc/redhat-release  | awk -F\. '{print $1}'|awk '{print $1}'`
fi

echo "Found RHEL version $rel ... time to convert..."

# run the version specific script
if [ -e tocentos${rel}.sh ]
then
	./tocentos${rel}.sh
else
	echo "We do not have a script for $rel version of RHEL yet, make a pull request or email elh at astroarch dot com for assistance."
fi
