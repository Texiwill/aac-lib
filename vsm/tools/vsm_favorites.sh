#!/bin/bash
# Copyright (c) AstroArch Consulting, Inc.  2018
# All rights reserved
#
# vim: tabstop=4 shiftwidth=4
#
# Grab all files for various favorite suites
#
# Requires:
# LinuxVSM 
#

PATH=$PATH:/usr/local/bin
export PATH

# local overrides default path
vsm=`which vsm.sh`
if [ -e ./vsm.sh ]
then
	vsm='./vsm.sh'
fi

# kill any running LinuxVSM
pkill -9 vsm.sh

$vsm -mr -y -q --progress --fav Datacenter_Cloud_Infrastructure_VMware_vSphere_6_7_Enterprise_Plus
$vsm -y --fav Datacenter_Cloud_Infrastructure_VMware_vSphere_6_5_Enterprise_Plus
$vsm -y --fav Datacenter_Cloud_Infrastructure_VMware_vSphere_6_0_Enterprise_Plus
$vsm -y --fav Datacenter_Cloud_Infrastructure_VMware_vSphere_5_5_Enterprise_Plus
