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

# local overrides default path
vsm=`which vsm.sh`
if [ -e ./vsm.sh ]
then
	vsm='./vsm.sh'
fi

# kill any running LinuxVSM
pkill -9 vsm.sh

$vsm -mr -y --debug -q --patches --fav Datacenter_Cloud_Infrastructure_VMware_vSphere_6_7_Enterprise_Plus
$vsm -y --debug --patches --fav Datacenter_Cloud_Infrastructure_VMware_vSphere_6_5_Enterprise_Plus
$vsm -y --debug --patches --fav Datacenter_Cloud_Infrastructure_VMware_vSphere_6_0_Enterprise_Plus
$vsm -y --debug --patches --fav Datacenter_Cloud_Infrastructure_VMware_vSphere_5_5_Enterprise_Plus
$vsm -y --debug --oauth --fav Networking_Security_VMware_NSX_T_Data_Center_2_x_VMware_NSX_Data_Center_Enterprise_Plus
$vsm -y --debug --oauth --fav Desktop_End_User_Computing_VMware_Horizon_7_6_Horizon_7_Enterprise_Edition
$vsm -y --debug --oauth --fav Infrastructure_Operations_Management_VMware_vRealize_Suite_2018_Enterprise
