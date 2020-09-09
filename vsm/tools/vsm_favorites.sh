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
mr='-mr'
echo "Getting vSphere ..."
for x in 7_0 6_7 6_5 6_0 5_5
do
	$vsm $mr -y --debug -q --patches --fav Datacenter_Cloud_Infrastructure_VMware_vSphere_${x}_Enterprise_Plus
	mr=''
done

echo "Getting NSX ..."
for x in 3_x 2_x
do
	$vsm -y --debug --patches --fav Networking_Security_VMware_NSX_T_Data_Center_${x}_VMware_NSX_Data_Center_Enterprise_Plus
done

echo "Getting Horizon ..."
for x in 2006_Horizon 7_12_Horizon_7.12 7_11_Horizon_7.11 7_10_Horizon_7.10
do
	$vsm -y --debug --patches --fav Desktop_End-User_Computing_VMware_Horizon_${x}_Enterprise
done

echo "Getting vRealize Suite ..."
$vsm -y --debug --patches --fav Infrastructure_Operations_Management_VMware_vRealize_Suite_2019_Enterprise
