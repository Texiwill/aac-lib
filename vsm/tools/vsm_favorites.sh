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
VERSIONID="3.0.6"

function usage () {
	echo "$0 [--latest][--n+1][--n+2][--n+3][--n+4][--n+5][--n+6][--all][-h|--help][-s|--save][--euc][--vcd][--tanzu][--arm][--wkstn][--fusion][--vsphere|--novsphere][-v|--version][--everything][--rebuild][-mn][-mr]"
	echo "	--latest - get the latest only (default)"
	echo "	--n+1 - get the latest + 1 previous version"
	echo "	--n+2 - get the latest + 2 previous versions"
	echo "	--n+3 - get the latest + 3 previous versions"
	echo "	--n+4 - get the latest + 4 previous versions"
	echo "	--n+5 - get the latest + 5 previous versions"
	echo "	--n+6 - get the latest + 6 previous versions"
	echo "	--all - get all versions"
	echo "	--euc - Add EUC components (implies --wkstn --fusion)"
	echo "	--vcd - Add VCD components"
	echo "	--wkstn - Add Workstation/Player components"
	echo "	--fusion - Add Fusion components"
	echo "	--tanzu - Add Tanzu components"
	echo "	--vsphere - Add vsphere components (default)"
	echo "	--novsphere - remote vsphere components"
	echo "	--arm - Add ESXi on ARM components"
	echo "	--everything - Add all components"
	echo "	--dryrun - Echo out commands issued"
	echo "	--rebuild - rebuild --dlg seed file for your use"
	echo "	-mr   - Clear 1st time use"
	echo "	-mn   - Clear Loging files"
	echo "	-h|--help - this help"
	echo "	-s|--save - save get and --euc options to \$HOME/.vsmfavsrc"
	echo "	-v|--version - version information"
	echo ""
	echo "Uses contents of \$HOME/.vsmfavsrc to set Get and EUC options."
	exit
}

function vsmfav_get_versions() {
	product=$1
	slug=`jq '.productCategoryList[].productList[].actions[0].target' ${cdir}/api.json| egrep "/${product}/"|sed 's/"//g'|sed 's#./info/slug/#category=#' | sed 's#/#\&product=#'  | sed 's#/#\&version=#'`
	versions=`wget -O - --header="$hdr" "https://my.vmware.com/channel/public/api/v1.0/products/getProductHeader?locale=en_US&${slug}" 2>/dev/null|jq '.versions[].id' - 2>/dev/null|sed 's/"//g'`
}

hdr='User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.0 Safari/537.36'
nc=1 # default
save=0
euc=0
wkstn=0
vcd=0
arm=0
tan=0
vsp=1
dry=0
rebuild=''
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
		--wkstn) wkstn=1;;
		--novsphere) vsp=0;;
		--everything) vsp=1; euc=1; vcd=1; arm=1; tan=1;;
		--all) nc=1000;;
		--dryrun) dry=1;;
		--rebuild) rebuild='--keeplocs';;
		-mr) mr="$mr -mr";;
		-mn) mr="$mr -mn";;
		-s|--save) save=1;;
		-v|--version) echo "LinuxVSM Favorites:"; echo "	`basename $0`: $VERSIONID"; exit;;
		-h|--help) usage;;
		*) usage ;; 
	esac 
	shift 
done

echo $rebuild

if [ $save -eq 1 ]
then
	echo "nc=$nc" > $HOME/.vsmfavsrc
	echo "euc=$euc" >> $HOME/.vsmfavsrc
	echo "vcd=$vcd" >> $HOME/.vsmfavsrc
	echo "arm=$arm" >> $HOME/.vsmfavsrc
	echo "tan=$tan" >> $HOME/.vsmfavsrc
	echo "vsp=$vsp" >> $HOME/.vsmfavsrc
	echo "wkstn=$wkstn" >> $HOME/.vsmfavsrc
fi

# local overrides default path
vsm=`which vsm.sh`
if [ -e ./vsm.sh ]
then
	vsm='./vsm.sh'
fi

if [ $dry -eq 1 ]
then
	vsm='echo vsm.sh '
fi

# get cdir or use default
cdir="/tmp/vsm.$HOME"
x=`grep cdir $HOME/.vsmrc`
if [ Z"$x" != Z"" ]
then
	eval $x
fi

if [ ! -d $cdir ]
then
	mkdir $cdir
fi

rm $cdir/api.json 2>/dev/null
wget -O $cdir/api.json --header="$hdr" 'https://my.vmware.com/channel/public/api/v1.0/products/getAllProducts?locale=en_US&isPrivate=true' 2>/dev/null

if [ $vsp -eq 1 ]
then
	echo "Getting vSphere ..."
	vsmfav_get_versions vmware_vsphere
	c=0
	for x in $versions
	do
		c=$(($c+1))
		$vsm $mr $rebuild -y --debug -q --patches --fav Datacenter_Cloud_Infrastructure_VMware_vSphere_${x}_Enterprise_Plus
		if [ $c -ge $nc ]
		then
			break;
		fi
		mr=''
	done

	echo "Getting NSX ..."
	c=0;
	vsmfav_get_versions vmware_nsx_t_data_center
	for x in $versions
	do
		c=$(($c+1))
		$vsm $rebuild -y --debug --patches --fav Networking_Security_VMware_NSX_T_Data_Center_${x}_VMware_NSX_Data_Center_Enterprise_Plus
		if [ $c -ge $nc ]
		then
			break;
		fi
	done

	echo "Getting vRealize Suite ..."
	c=0
	vsmfav_get_versions vmware_vrealize_suite
	for x in $versions
	do
		c=$(($c+1))
		$vsm $rebuild -y --debug --patches --fav Infrastructure_Operations_Management_VMware_vRealize_Suite_${x}_Enterprise
		if [ $c -ge $nc ]
		then
			break;
		fi
	done
fi

if [ $euc -eq 1 ]
then
	wkstn=1
	fusion=1
	echo "Getting Horizon ..."
	c=0
	vsmfav_get_versions vmware_horizon
	for x in $versions
	do
		y=$x
		z=`echo $x |sed 's/_.*//'`
		if [ $z -gt 10 ]
		then
			x="${y}_Horizon"
		else
			x="${y}_Horizon_${z}"
		fi
		c=$(($c+1))
		$vsm $rebuild -y --debug --patches --fav Desktop_End-User_Computing_VMware_Horizon_${x}_Enterprise
		if [ $c -ge $nc ]
		then
			break;
		fi
	done
	
	echo "Getting Horizon Clients ..."
	c=0
	vsmfav_get_versions vmware_horizon_clients
	for x in $versions
	do
		c=$(($c+1))
		for y in Windows Mac Linux Chrome
		do
			$vsm $rebuild -y --debug -q --patches --fav Desktop_End-User_Computing_VMware_Horizon_Clients_${x}_VMware_Horizon_Client_for_${y}
		done
		if [ $c -ge $nc ]
		then
			break;
		fi
	done

	echo "Getting AppVolumes ..."
	c=0
	vsmfav_get_versions vmware_app_volumes
	# 2_x does not work today
	vers=`echo $versions | sed 's/2_x//'`
	for x in $vers
	do
		# fix versions
		if [ $x = '3_x' ]
		then
			y=$x
			z=`echo $x |sed 's/_x//'`
			x="${y}_App_Volumes_${z}_Advanced_Edition"
		else
			y=$x
			x="${y}_App_Volumes_Advanced_Edition"
		fi
		c=$(($c+1))
		$vsm $rebuild -y --debug --patches --fav Desktop_End-User_Computing_VMware_App_Volumes_${x}
		if [ $c -ge $nc ]
		then
			break;
		fi
	done
	
	echo "Getting Dynamic Environment Manager (DEM) ..."
	c=0
	vsmfav_get_versions vmware_dynamic_environment_manager
	for x in $versions
	do
		y=$x
		z=`echo $x |sed 's/_.*//'`
		if [ $z -gt 10 ]
		then
			x="${y}_VMware_Dynamic_Environment_Manager_Enterprise"
		fi
		c=$(($c+1))
		$vsm $rebuild -y --debug --patches --fav Desktop_End-User_Computing_VMware_Dynamic_Environment_Manager_${x}
		if [ $c -ge $nc ]
		then
			break;
		fi
	done

	echo "Getting Unified Access Gateway"
	c=0
	vsmfav_get_versions vmware_unified_access_gateway
	for x in $versions
	do
		y=$x
		c=$(($c+1))
		z=`echo $x|sed 's/_/./'`
		$vsm $rebuild -y --debug --patches --fav Desktop_End-User_Computing_VMware_Unified_Access_Gateway_${x}_VMware_Unified_Access_Gateway_${z}
		if [ $c -ge $nc ]
		then
			break;
		fi
	done

	echo "Getting Workspace ONE ..."
	c=0
	vsmfav_get_versions vmware_workspace_one
	for x in $versions
	do
		c=$(($c+1))
		names=`wget -O - --header="$hdr" "https://my.vmware.com/channel/public/api/v1.0/products/getRelatedDLGList?locale=en_US&${slug}&dlgType=PRODUCT_BINARY" 2>/dev/null|jq '.dlgEditionsLists[].name' - 2>/dev/null|sed 's/"//g'|sed 's/ /_/g'`
		for y in $names
		do
			$vsm $rebuild -y --debug --patches --fav Desktop_End-User_Computing_VMware_Workspace_ONE_${x}_${y}
		done
		if [ $c -ge $nc ]
		then
			break;
		fi
	done

fi

if [ $fusion -eq 1 ]
then
	echo "Getting VMware Fusion ..."
	c=0
	vsmfav_get_versions vmware_fusion
	# need first version listed
	xv=($versions)
	n=${xv[0]}
	for x in $versions
	do
		c=$(($c+1))
		# need more available information
		xslug=`echo $slug | sed "s/${n}/${x}/"`
		names=`wget -O - --header="$hdr" "https://my.vmware.com/channel/public/api/v1.0/products/getRelatedDLGList?locale=en_US&${xslug}&dlgType=PRODUCT_BINARY" 2>/dev/null|jq '.dlgEditionsLists[].name' - 2>/dev/null|sed 's/"//g'|sed 's/ /_/g'`
		for y in $names
		do
			$vsm $rebuild -y --debug --patches --fav Desktop_End-User_Computing_VMware_Fusion_${x}_VMware_Fusion_${y}
		done
		if [ $c -ge $nc ]
		then
			break;
		fi
	done
fi

if [ $wkstn -eq 1 ]
then
	echo "Getting VMware Workstation ..."
	c=0
	vsmfav_get_versions vmware_workstation_pro
	# need first version listed
	xv=($versions)
	n=${xv[0]}
	for x in $versions
	do
		c=$(($c+1))
		# need more available information
		xslug=`echo $slug | sed "s/${n}/${x}/"`
		names=`wget -O - --header="$hdr" "https://my.vmware.com/channel/public/api/v1.0/products/getRelatedDLGList?locale=en_US&${xslug}&dlgType=PRODUCT_BINARY" 2>/dev/null|jq '.dlgEditionsLists[].name' - 2>/dev/null|sed 's/"//g'|sed 's/ /_/g'`
		for y in $names
		do
			z="${x}_${y}"
			$vsm $rebuild -y --debug --patches --fav Desktop_End-User_Computing_VMware_Workstation_Pro_${z}
		done
		if [ $c -ge $nc ]
		then
			break;
		fi
	done

	echo "Getting VMware Workstation Player ..."
	c=0
	vsmfav_get_versions vmware_workstation_player
	# need first version listed
	xv=($versions)
	n=${xv[0]}
	for x in $versions
	do
		c=$(($c+1))
		# need more available information
		xslug=`echo $slug | sed "s/${n}/${x}/"`
		names=`wget -O - --header="$hdr" "https://my.vmware.com/channel/public/api/v1.0/products/getRelatedDLGList?locale=en_US&${xslug}&dlgType=PRODUCT_BINARY" 2>/dev/null|jq '.dlgEditionsLists[].name' - 2>/dev/null|sed 's/"//g'|sed 's/ /_/g'`
		for y in $names
		do
			z="${x}_${y}"
			$vsm $rebuild -y --debug --patches --fav Desktop_End-User_Computing_VMware_Workstation_Player_${z}
		done
		if [ $c -ge $nc ]
		then
			break;
		fi
	done
fi

if [ $vcd -eq 1 ]
then
	echo "Getting vCloud Director ..."
	vsmfav_get_versions vmware_cloud_director
	c=0
	for x in $versions
	do
		c=$(($c+1))
		$vsm $rebuild -y --debug --patches --fav Datacenter_Cloud_Infrastructure_VMware_Cloud_Director_${x}_VMware_vCloud_Director
		if [ $c -ge $nc ]
		then
			break;
		fi
	done

	echo "Getting vCloud Director Availability ..."
	c=0
	vsmfav_get_versions vmware_cloud_director_availability
	for x in $versions
	do
		if [ $x = "3_5" ] || [ $x = "3_0" ]
		then
			y=$x
			z=`echo $x | sed 's/_/./'`
			x="${y}_vCloud_Availability_${z}_Appliance_for_Cloud_Providers"
		fi
		c=$(($c+1))
		$vsm $rebuild -y --debug --patches --fav Datacenter_Cloud_Infrastructure_VMware_Cloud_Director_Availability_${x}
		if [ $c -ge $nc ]
		then
			break;
		fi
	done

	echo "Getting vCloud Usage Meter..."
	c=0
	vsmfav_get_versions vmware_vcloud_usage_meter
	for x in $versions
	do
		c=$(($c+1))
		$vsm $rebuild -y --debug --patches --fav Datacenter_Cloud_Infrastructure_VMware_vCloud_Usage_Meter_${x}
		if [ $c -ge $nc ]
		then
			break;
		fi
	done

	echo "Getting vCloud Director Object Storage Extension ..."
	c=0
	vsmfav_get_versions vmware_cloud_director_object_storage_extension
	for x in $versions
	do
		c=$(($c+1))
		$vsm $rebuild -y --debug --patches --fav Datacenter_Cloud_Infrastructure_VMware_Cloud_Director_Object_Storage_Extension_${x}
		if [ $c -ge $nc ]
		then
			break;
		fi
	done

	echo "Getting vCloud Director App Launchpad..."
	c=0
	vsmfav_get_versions vmware_cloud_director_app_launchpad
	for x in $versions
	do
		c=$(($c+1))
		$vsm $rebuild -y --debug --patches --fav Datacenter_Cloud_Infrastructure_VMware_Cloud_Director_App_Launchpad_${x}
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
	vsmfav_get_versions vmware_tanzu_kubernetes_grid
	for x in $versions
	do
		c=$(($c+1))
		$vsm $rebuild -y --debug --patches --fav Infrastructure_Operations_Management_VMware_Tanzu_Kubernetes_Grid_${x}
		if [ $c -ge $nc ]
		then
			break;
		fi
	done
	vsmfav_get_versions vmware_tanzu_toolkit_for_kubernetes
	for x in $versions
	do
		c=$(($c+1))
		$vsm $rebuild -y --debug --patches --fav Infrastructure_Operations_Management_VMware_Tanzu_Toolkit_for_Kubernetes_${x}_VMware_Tanzu_Tookit_for_Kubernetes
		if [ $c -ge $nc ]
		then
			break;
		fi
	done
	vsmfav_get_versions vmware_tanzu_kubernetes_grid_integrated_edition
	for x in $versions
	do
		c=$(($c+1))
		$vsm $rebuild -y --debug --patches --fav Infrastructure_Operations_Management_VMware_Tanzu_Kubernetes_Grid_Integrated_Edition_${x}_TKG_Integrated_Edition
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
