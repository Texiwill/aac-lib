#!/bin/bash
# Copyright (c) AstroArch Consulting, Inc. 2018-2020
# All rights reserved
#
# vim: tabstop=4 shiftwidth=4
#
# Grab all files for various favorite suites
#
# Requires:
# LinuxVSM 
#
VERSIONID="2.0.0"

function usage () {
	echo "$0 [--latest][--n+1][--n+2][--n+3][--n+4][--n+5][--n+6][--all][-h|--help][-s|--save][--euc][-v|--version]"
	echo "	--latest - get the latest only (default)"
	echo "	--n+1 - get the latest + 1 previous version"
	echo "	--n+2 - get the latest + 2 previous versions"
	echo "	--n+3 - get the latest + 3 previous versions"
	echo "	--n+4 - get the latest + 4 previous versions"
	echo "	--n+5 - get the latest + 5 previous versions"
	echo "	--n+6 - get the latest + 6 previous versions"
	echo "	--all - get everything"
	echo "	--euc - Add Additional EUC components"
	echo "	-mr   - Clear 1st time use"
	echo "	-h|--help - this help"
	echo "	-s|--save - save get and --euc options to \$HOME/.vsmfavsrc"
	echo "	-v|--version - version information"
	echo ""
	echo "Uses contents of \$HOME/.vsmfavsrc to set Get and EUC options."
	exit
}

nc=1 # default
save=0
euc=0
mr=''
if [ -e $HOME/.vsmfavsrc ]
then
	. $HOME/.vsmfavsrc
fi
while [[ $# -gt 0 ]]
do 
	key="$1" 
	case "$key" in 
		--latest) nc=1;;
		--n+1) nc=2;;
		--n+2) nc=3;;
		--n+3) nc=4;;
		--n+4) nc=5;;
		--n+6) nc=6;;
		--euc) euc=1;;
		--all) nc=1000;;
		-mr) mr='-mr';;
		-s|--save) save=1;;
		-v|--version) echo "LinuxVSM Favorites:"; echo "	`basename $0`: $VERSIONID"; exit;;
		-h|--help) usage;;
		*) usage ;; 
	esac 
	shift 
done

if [ $save -eq 1 ]
then
	echo "nc=$nc" > $HOME/.vsmfavsrc
	echo "euc=$euc" >> $HOME/.vsmfavsrc
fi

# local overrides default path
vsm=`which vsm.sh`
if [ -e ./vsm.sh ]
then
	vsm='./vsm.sh'
fi
echo "Getting vSphere ..."
c=0
for x in 7_0 6_7 6_5 6_0 5_5 5_0
do
	c=$(($c+1))
	$vsm $mr -y --debug -q --patches --fav Datacenter_Cloud_Infrastructure_VMware_vSphere_${x}_Enterprise_Plus
	if [ $c -ge $nc ]
	then
		break;
	fi
	mr=''
done

echo "Getting NSX ..."
c=0;
for x in 3_x 2_x 1_x
do
	c=$(($c+1))
	$vsm -y --debug --patches --fav Networking_Security_VMware_NSX_T_Data_Center_${x}_VMware_NSX_Data_Center_Enterprise_Plus
	if [ $c -ge $nc ]
	then
		break;
	fi
done

echo "Getting Horizon ..."
c=0
for x in 2006_Horizon 7_12_Horizon_7.12 7_11_Horizon_7.11 7_10_Horizon_7.10 7_9_Horizon_7.9 7_8_Horizon_7.8 7_7_Horizon_7.7 7_6_Horizon_7.6 7_5_Horizon_7.5 7_4_Horizon_7.4 7_3_Horizon_7.3 7_2_Horizon_7.2 7_0_Horizon_7.0 6_2_Horizon_6.2 6_1_Horizon_6.1
do
	c=$(($c+1))
	$vsm -y --debug --patches --fav Desktop_End-User_Computing_VMware_Horizon_${x}_Enterprise
	if [ $c -ge $nc ]
	then
		break;
	fi
done

echo "Getting Horizon Clients ..."
c=0
for x in 2006 5_0 4_0
do
	c=$(($c+1))
	for y in Windows Mac Linux Chrome
	do
		$vsm $mr -y --debug -q --patches --fav Desktop_End-User_Computing_VMware_Horizon_Clients_${x}_VMware_Horizon_Client_for_${y}
	done
	if [ $c -ge $nc ]
	then
		break;
	fi
done

if [ $euc -eq 1 ]
then
	echo "Getting AppVolumes ..."
	c=0
	# 2_x does not work today
	for x in 4_x_App_Volumes_Advanced_Edition 3_x_App_Volumes_3_Advanced_Edition #2_x
	do
		c=$(($c+1))
		$vsm -y --debug --patches --fav Desktop_End-User_Computing_VMware_App_Volumes_${x}
		if [ $c -ge $nc ]
		then
			break;
		fi
	done
	
	echo "Getting Dynamic Environment Manager (DEM) ..."
	c=0
	for x in 2006 9_11 9_10 9_9 9_8 9_7 9_6 9_5 9_4 9_3 9_2
	do
		c=$(($c+1))
		$vsm -y --debug --patches --fav Desktop_End-User_Computing_VMware_Dynamic_Environment_Manager_${x}
		if [ $c -ge $nc ]
		then
			break;
		fi
	done

	echo "Getting Workspace ONE ..."
	c=0
	for x in '_-_Horizon_Apps_Advanced' '_for_VDI_–_Horizon_Enterprise' '_&_Workspace_ONE_Enterprise_for_VDI_-_Horizon_Cloud'
	do
		c=$(($c+1))
		$vsm -y --debug --patches --fav Desktop_End-User_Computing_VMware_Workspace_ONE_1_0_Workspace_ONE_Enterprise${x}
		if [ $c -ge $nc ]
		then
			break;
		fi
	done
fi

echo "Getting vRealize Suite ..."
c=0
for x in 2019 2018 2017 7_0
do
	c=$(($c+1))
	$vsm -y --debug --patches --fav Infrastructure_Operations_Management_VMware_vRealize_Suite_${x}_Enterprise
	if [ $c -ge $nc ]
	then
		break;
	fi
done
