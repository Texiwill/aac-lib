#!/bin/bash
# Copyright (c) AstroArch Consulting, Inc.  2018
# All rights reserved
#
# vim: tabstop=4 shiftwidth=4
# Grab all files based on search string and release number using the
# Linux version of VMware Software Manager (VSM)
#
# Requires:
# LinuxVSM 
#

if [ Z"$1" = Z"" ] || [ Z"$2" = Z"" ]
then
	cat << EOF
Usage: $0 package refinement
	package is the general name of a package
	refinement is a refinement upon that search
	Example: $0 VCSA iso
	- which would download all iso images for every iso version of VCSA
EOF
	exit
fi

# local overrides default path
vsm=`which vsm.sh`
if [ -e ./vsm.sh ]
then
	vsm='./vsm.sh'
fi

# Do the deed
l=`$vsm -y -q -nh --dlgl $1 | grep $2 | cut -d' ' -f2`
for x in $l
do
	$vsm -y -q --ouath --dlg $x
done
