#!/bin/bash
# Copyright (c) AstroArch Consulting, Inc. 2018-2021
# All rights reserved
#
# vim: tabstop=4 shiftwidth=4
#
# Grab all files for various favorite suites
#
# Requires:
# LinuxVSM 
#
VERSIONID="2.0.4"

function usage () {
	echo "$0 [--latest][--n+1][--n+2][--n+3][--n+4][--n+5][--n+6][--all][-h|--help][-s|--save][--euc][--vcd][--tanzu][--arm][--vsphere|--novsphere][-v|--version][--everything]"
	echo "	--latest - get the latest only (default)"
	echo "	--n+1 - get the latest + 1 previous version"
	echo "	--n+2 - get the latest + 2 previous versions"
	echo "	--n+3 - get the latest + 3 previous versions"
	echo "	--n+4 - get the latest + 4 previous versions"
	echo "	--n+5 - get the latest + 5 previous versions"
	echo "	--n+6 - get the latest + 6 previous versions"
	echo "	--all - get everything"
	echo "	--euc - Add Additional EUC components"
	echo "	--vcd - Add VCD components"
	echo "	--tanzu - Add Tanzu components"
	echo "	--vsphere - Add vsphere components (default)"
	echo "	--novsphere - remote vsphere components"
	echo "	--arm - Add ESXi on ARM components"
	echo "	--everything - Add all components"
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
vcd=0
arm=0
tan=0
vsp=1
future=0
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
		--vcd) vcd=1;;
		--arm) arm=1;;
		--tanzu) tan=1;;
		--vsphere) vsp=1;;
		--novsphere) vsp=0;;
		--everything) vsp=1; euc=1; vcd=1; arm=1; tan=1;;
		--all) nc=1000;;
		-mr) mr='-mr';;
		-s|--save) save=1;;
		-v|--version) echo "LinuxVSM Favorites:"; echo "	`basename $0`: $VERSIONID"; exit;;
		-h|--help) usage;;
		-f|--future) future=1;;
		*) usage ;; 
	esac 
	shift 
done

if [ $save -eq 1 ]
then
	echo "nc=$nc" > $HOME/.vsmfavsrc
	echo "euc=$euc" >> $HOME/.vsmfavsrc
	echo "vcd=$vcd" >> $HOME/.vsmfavsrc
	echo "arm=$arm" >> $HOME/.vsmfavsrc
	echo "tan=$tan" >> $HOME/.vsmfavsrc
	echo "vsp=$vsp" >> $HOME/.vsmfavsrc
fi

# local overrides default path
vsm=`which vsm.sh`
if [ -e ./vsm.sh ]
then
	vsm='./vsm.sh'
fi

if [ $future -eq 1 ]
then
	# Get the Versions from VMware directly
	apiout=`wget -O - 'https://my.vmware.com/channel/public/api/v1.0/products/getAllProducts?locale=en_US&isPrivate=false' 2>/dev/null`
	sluglist=`echo $apiout | jq '.productCategoryList[].productList[].actions[0].target' | egrep '/vmware_vsphere/|/vmware_vrealize_suite/|/vmware_nsx_t_data_center/|/vmware_horizon/|/vmware_horizon_clients/'|sed 's/"//g'`
	eucsluglist=`echo $apiout | jq '.productCategoryList[].productList[].actions[0].target' | egrep '/vmware_workstation_player/|/vmware_workspace_one/|/vmware_app_volumes/|/vmware_dynamic_environment_manager/'|sed 's/"//g'`
	
	for x in $sluglist
	do
		echo $x
		xhdr=`echo $x|sed 's#./info/slug/#category=#' | sed 's#/#\&product=#'  | sed 's#/#\&version=#'`
		modlist=`wget -O - "https://my.vmware.com/channel/public/api/v1.0/products/getRelatedDLGList?locale=en_US&${xhdr}&dlgType=PRODUCT_BINARY" 2>/dev/null | jq '.dlgEditionsLists[].name'|sed 's/"//g' | sed 's/ /_/g'`
		verlist=`wget -O - "https://my.vmware.com/channel/public/api/v1.0/products/getProductHeader?locale=en_US&${xhdr}" 2>/dev/null|jq '.versions[].slugUrl'|sed 's/"//g'|sed 's#./info/slug/##'|sed 's#/#_#g'`
		# array for easier access
		echo $verlist
		echo $modlist
	done
	exit
fi

if [ $vsp -eq 1 ]
then
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
fi

if [ $euc -eq 1 ]
then
	echo "Getting Horizon ..."
	c=0
	for x in 2012_Horizon 2006_Horizon 7_13_Horizon_7.13 7_12_Horizon_7.12 7_11_Horizon_7.11 7_10_Horizon_7.10 7_9_Horizon_7.9 7_8_Horizon_7.8 7_7_Horizon_7.7 7_6_Horizon_7.6 7_5_Horizon_7.5 7_4_Horizon_7.4 7_3_Horizon_7.3 7_2_Horizon_7.2 7_0_Horizon_7.0 6_2_Horizon_6.2 6_1_Horizon_6.1
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
	for x in 8 8_ 7_5_0 7_4_0
	do
		c=$(($c+1))
		for y in Windows Mac Linux Chrome
		do
			$vsm $mr -y --debug -q --patches --fav Desktop_End-User_Computing_VMware_Horizon_Clients_horizon_${x}_VMware_Horizon_Client_for_${y}
		done
		if [ $c -ge $nc ]
		then
			break;
		fi
	done

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
	for x in 2009_VMware_Dynamic_Environment_Manager_Enterprise 2006_VMware_Dynamic_Environment_Manager_Enterprise 9_11 9_10 9_9 9_8 9_7 9_6 9_5 9_4 9_3 9_2
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

	echo "Getting VMware Workstation Player ..."
	c=0
	for x in 16_0_VMware_Workstation_Player_16.0 15_0_VMware_Workstation_Player_15.5.6 14_0_VMware_Workstation_Player_14.1.8
	do
		c=$(($c+1))
		$vsm -y --debug --patches --fav Desktop_End-User_Computing_VMware_Workstation_Player_${x}
		if [ $c -ge $nc ]
		then
			break;
		fi
	done
fi

if [ $vcd -eq 1 ]
then
	echo "Getting vCloud Director ..."
	c=0
	for x in 10_2 10_1 10_0 9_7 9_5 9_1 9_0 8_20 8_10
	do
		c=$(($c+1))
		$vsm -y --debug --patches --fav Datacenter_Cloud_Infrastructure_VMware_Cloud_Director_${x}_VMware_vCloud_Director
		if [ $c -ge $nc ]
		then
			break;
		fi
	done

	echo "Getting vCloud Director Availability ..."
	c=0
	for x in 4_1 4_0 3_5_vCloud_Availability_3.5_Appliance_for_Cloud_Providers 3_0_vCloud_Availability_3.0_Appliance_for_Cloud_Providers
	do
		c=$(($c+1))
		$vsm -y --debug --patches --fav Datacenter_Cloud_Infrastructure_VMware_Cloud_Director_Availability_${x}
		if [ $c -ge $nc ]
		then
			break;
		fi
	done

	echo "Getting vCloud Usage Meter..."
	c=0
	for x in 4_3 4_2
	do
		c=$(($c+1))
		$vsm -y --debug --patches --fav Datacenter_Cloud_Infrastructure_VMware_vCloud_Usage_Meter_${x}
		if [ $c -ge $nc ]
		then
			break;
		fi
	done

	echo "Getting vCloud Director Object Storage Extension ..."
	c=0
	for x in 2_0 1_5 1_0
	do
		c=$(($c+1))
		$vsm -y --debug --patches --fav Datacenter_Cloud_Infrastructure_VMware_Cloud_Director_Object_Storage_Extension_${x}
		if [ $c -ge $nc ]
		then
			break;
		fi
	done

	echo "Getting vCloud Director App Launchpad..."
	c=0
	for x in 2_0 1_0
	do
		c=$(($c+1))
		$vsm -y --debug --patches --fav Datacenter_Cloud_Infrastructure_VMware_Cloud_Director_App_Launchpad_${x}
		if [ $c -ge $nc ]
		then
			break;
		fi
	done
fi

if [ $tan -eq 1 ]
then
	echo "Getting Tanzu"
	c=0
	for x in 1_x
	do
		c=$(($c+1))
		$vsm -y --debug --patches --fav Infrastructure_Operations_Management_VMware_Tanzu_Kubernetes_Grid_${x}
		if [ $c -ge $nc ]
		then
			break;
		fi
	done
	for x in 1_1 1_0
	do
		c=$(($c+1))
		$vsm -y --debug --patches --fav Infrastructure_Operations_Management_VMware_Tanzu_Toolkit_for_Kubernetes_${x}_VMware_Tanzu_Tookit_for_Kubernetes
		if [ $c -ge $nc ]
		then
			break;
		fi
	done
	for x in 1_9 1_8
	do
		c=$(($c+1))
		$vsm -y --debug --patches --fav Infrastructure_Operations_Management_VMware_Tanzu_Kubernetes_Grid_Integrated_Edition_${x}_TKG_Integrated_Edition
		if [ $c -ge $nc ]
		then
			break;
		fi
	done
fi

if [ $arm -eq 1 ]
then
	echo "Getting ESXi on ARM"
	$vsm -y --debug --patches --dlgroup ESXI-ARM beta
fi
