#!/bin/bash
#
# Copyright (c) 2017-2018 AstroArch Consulting, Inc. All rights reserved
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.


precheck=0
dryrun=0
nocleanup=0
while [[ $# -gt 0 ]]
do
	key="$1"
	case $key in 
		-p|--precheck)
			precheck=1
			;;
		-d|--dryrun)
			dryrun=1
			nocleanup=1
			;;
		-n|--nocleanup)
			nocleanup=1
			;;
		-h|--help|*)
			echo "Usage: $0 [[-p|--precheck]|[-d|--dryrun]|[-n|--nocleanup]|[-h|--help]]"
			echo "	--dryrun implies --nocleanup"
			exit;
			;;
	esac
	shift
done

if [ -e ~/.govc ]
then
	. ~/.govc
else
	echo << EOF
We need some default settings for govc, which we look for in ~/.govc

export GOVC_INSECURE=1
export GOVC_URL=VCENTER_SERVER_NAME
export GOVC_USERNAME=IMPORT_LOGIN
export GOVC_PASSWORD=IMPORT_PASSWORD
export GOVC_DATASTORE=DEFAULT Datastore
export GOVC_NETWORK=Network
export GOVC_RESOURCE_POOL='/Datacenter/host/Cluster/Resources'
export GOVC_DATACENTER=DatacenterName

EOF

fi

govc=`which govc`
if [ $? != 0 ]
then
	if [ -e /usr/local/bin/govc ]
	then
		govc="/usr/local/bin/govc"
	else
		echo "We need govc somewhere in your path or /usr/local/bin"
		if [ $precheck -eq 0 ]
		then
			exit
		fi
	fi
fi
json_reformat=`which json_reformat`
if [ $? != 0 ]
then
	echo "We need json_reformat (yajl package) somewhere in your path"
	if [ $precheck -eq 0 ]
	then
		exit
	fi
fi

defdir=`dirname $0`
defaults=""
if [ -e $HOME/.ov-defaults ]
then
	defaults="$HOME/.ov-defaults"
else
	if [ -e $defdir/.ov-defaults ]
	then
		defaults="$defdir/.ov-defaults"
	else
		defaults=".ov-defaults"
	fi
fi
if [ ! -e "$defaults" ]
then
	echo "We need a .ov-defaults file $HOME, the directory of the script, or the directory containing the OVA/OVFs to process"
	exit
fi

missing="";
for x in domain netmask dns gw network vswitch ntp
do
	z=`grep -i ${x}-global $defaults|awk '{print $1}'`
	eval g${x}=$z
	if [ Z"$z" = Z"" ]
	then
		missing="$missing\t${x}-global\n"
	fi
done
if [ Z"$missing" != Z"" ]
then
	echo "Missing these global definitions in $defaults"
	echo -e $missing
fi

for x in `ls *.ova *.ovf 2>/dev/null|grep -v new.ovf`
do
	tmpdir=0
	# extract name of ova by file
	y=`echo ${x} | sed 's/[\.-][0-9].*$//'|sed 's/\.[a-Z].*$//'`

	# Check to see if we can import
	z=`grep -i noimport-${y} $defaults|awk '{print $1}'`
	if [ Z"$z" != Z"" ]
	then
		echo "INFO: Cannot import $y. It has issues when using govc"
		continue
	fi

	# count the network segments required
	$govc import.spec $x | python -m json.tool > a.json
	networks=`grep \"Network\": a.json | wc -l`

	# determine where to stop the pre-check loop
	dobreak=""
	z=`grep -i break-${y} $defaults|awk '{print $1}'`
	if [ Z"$z" != Z"" ]
	then
		dobreak=$z
	fi

	# precheck loop
	missing=""
	for xx in domain network vswitch ntp ssh ip netmask dns gw hostname
	do
		z=`grep -i ${xx}-${y} $defaults|awk '{print $1}'`
		eval ${xx}=$z
		if [ Z"$z" = Z"" ]
		then
			eval ${xx}=\$g$xx
			missing="$missing\t${xx}-${y}\n"
		fi
		if [ Z"$xx" = "$dobreak" ]
		then
			break
		fi
	done

	# Now search for more network settings
	if [ $networks -gt 1 ]
	then
		for n in $(seq 2 $networks)
		do
			for nn in vswitch network
			do
				
				vet=${nn}${n}
				z=`grep -i ${vet}-${y} $defaults|awk '{print $1}'`
				eval ${vet}=$z
				if [ Z"$z" = Z"" ]
				then
					missing="$missing\t${vet}-${y}\n"
				fi
			done
		done
	fi
	if [ Z"$missing" != Z"" ]
	then
		echo "Missing these definitions in $defaults for $y"
		echo -e $missing
		echo "	Using Global Definitions if any or DHCP mode"
	fi

	# Now we process the spec and replace with elements as needed
	if [ $precheck -eq 0 ]
	then
		# lets get the spec and do something interesting with it
		#	namely 'deployment' often leads to errors
		#	as does vm.name
		#	as does not specifying IP info
		for xx in netmask0 ip0 DNS gateway ntp ssh hostname
		do
			# need to preserve quotes in eval
			z=`grep -i ${xx} a.json|sed 's/ //g'|sed 's/"/\\\\"/g'|sed 's/(/\\\\(/'|sed 's/)/\\\\)/'`
			eval j${xx}="$z"
		done

		# domain is special, not everything has it
		jdomain=""
		grep -i domain a.json > /dev/null 2>&1
		if [ $? -eq 0 ]
		then
			z=`grep -i domain a.json|sed 's/ //g'|sed 's/"/\\\\"/g'|sed 's/(/\\\\(/'|sed 's/)/\\\\)/'`
			jdomain="$z"
		fi
		
		# now for passwords
		spass=""
		pass=""
		z=`egrep -i 'password|passwd' a.json|sed s'/ //g'|sed 's/"/\\\\"/g'`
		if [ Z"$z" != Z"" ]
		then
			password=$z
			pass=`grep -i password-${y} $defaults|awk '{print $1}'`
			if [ Z"$pass" = Z"" ]
			then
				echo -n "Enter $y Root Password: "
				read -s pass
			fi
			# govc will ask during import
			if [ Z"$pass" = Z"" ]
			then
				pass="PASSWORD"
			fi
			spass="s/{$password\"Value\":\"\"/{$password\"Value\":\"${pass}\"/"
		fi
		
		if [ Z"$netmask" = Z"" ]
		then
			snetmask="s/{$jnetmask0\"Value\":\"\"}//"
			sip="s/{$jip0\"Value\":\"\"}//"
			sgw="s/{$jgateway\"Value\":\"\"}//"
			sdns="s/{$jDNS\"Value\":\"\"}//"
			if [ Z"$jdomain" != Z"" ]
			then
				sdomain="s/{$jdomain\"Value\":\"\"}//"
			fi
		else
			snetmask="s/{$jnetmask0\"Value\":\"\"/{$jnetmask0\"Value\":\"${netmask}\"/"
			shostname="s/{$jhostname\"Value\":\"\"/{$jhostname\"Value\":\"${hostname}\"/"
			sip="s/{$jip0\"Value\":\"\"/{$jip0\"Value\":\"${ip}\"/"
			sgw="s/{$jgateway\"Value\":\"\"/{$jgateway\"Value\":\"${gw}\"/"
			sdns="s/{$jDNS\"Value\":\"\"/{$jDNS\"Value\":\"${dns}\"/"
			sntp="s/{$jntp\"Value\":\"\"/{$jntp\"Value\":\"${ntp}\"/"
			if [ Z"$jdomain" != Z"" ]
			then
				sdomain="s/{$jdomain\"Value\":\"\"/{$jdomain\"Value\":\"${domain}\"/"
			fi
		fi

		# Name
		name=`awk '/vm.vmname/{A=1}{if (A==2) { B=$0; exit;} if (A==1) {A++;}}END{print B}' a.json | awk -F\" '{print $4}'|sed 's/_/ /g'|sed 's/(.*)//'|sed 's/\s*$//g'`
		if [ Z"$name" = Z"" ]
		then
			name=$y
		fi
		deployment=`awk '/deployment_scenario/{A=1}{if (A==2) { B=$0; exit;} if (A==1) {A++;}}END{print B}' a.json | awk -F\" '{print $4}'|sed 's/_/ /g'|sed 's/(.*)//'|sed 's/\s*$//g'`
		sshv=`awk '/enable_sshd/{A=1}{if (A==2) { B=$0; exit;} if (A==1) {A++;}}END{print B}' a.json | awk -F\" '{print $4}'|sed 's/_/ /g'|sed 's/(.*)//'|sed 's/\s*$//g'`
		remap=`awk '/NetworkMapping/{A=1}{if (A==3) { B=$0; exit;} if (A>0 && A<3) {A++;}}END{print B}' a.json | awk -F\" '{print $4}'|sed 's/_/ /g'|sed 's/(.*)//'|sed 's/\s*$//g'`

		# get the ov type (ova/ovf)
		ov=`echo $x | awk -F\. '{print $NF}'`

		# Special for bad ovf/ova
		doremap="0"
		z=`grep -i remap-${y} $defaults|awk '{print $1}'`
		if [ Z"$z" != Z"" ]
		then
			if [ $ov = "ovf" ]
			then
				doremap=1
			else
				doremap=2
			fi
			
		fi

		# handle malformed ova/ovf files
		dir="."
		loc=`pwd`
		if [ "$doremap" != "0" ]
		then
			snetmask="s/{$jnetmask0\"Value\":\"\"}//"
			sgw="s/{$jgateway\"Value\":\"\"}//"
			sdns="s/{$jDNS\"Value\":\"\"}//"
			sdomain="s/{$jdomain\"Value\":\"\"}//"
		fi
		if [ "$doremap" = "2" ]
		then
			tmpdir=1
			dir=/tmp/$y-$$
			# these need to be unpacked and then modified
			mkdir $dir
			(cd $dir; tar -xf $loc/$x)
			nx=`ls $dir/*.ovf`
			x=`basename $nx`
			ov="ovf"
		fi
		if [ "$doremap" != "0" ]
		then
			sed "s/$remap/$network/g" $dir/$x > $dir/new.ovf
		fi

		# Handle multiple networks
		snetwork="s/\"NetworkMapping\":\[.*\],\"PowerOn\"/\"NetworkMapping\":\["{\"Name\":\"${vswitch}\",\"Network\":\"${network}\"}
		if [ $networks -gt 1 ]
		then
			for n in $(seq 2 $networks)
			do
				vet="vswitch$n"
				net="network$n"
				snetwork="${snetwork},{\"Name\":\"${!vet}\",\"Network\":\"${!net}\"}"
			done
		fi
		snetwork="${snetwork}\],\"PowerOn\"/"

		$json_reformat -m < a.json |
		sed 's/,"Deployment":"small"//' |
		sed 's/{"Deployment":"small",/{/' |
        	sed 's/,{"Key":"vm.vmname","Value":.*}\]/\]/' |
		sed $snetwork | sed $sntp | sed $shostname |
		sed $snetmask | sed $sip | sed $sgw | sed $sdns > b.json
		if [ Z"$spass" != Z"" ]
		then 
			sed $spass b.json > c.json
			mv c.json b.json
		fi
		if [ Z"$sshv" != Z"" ]
		then
        		sed "s/,{$jssh\"Value\":\"$sshv\"}//" b.json > c.json
			mv c.json b.json
		fi
		if [ Z"$deployment" != Z"" ]
		then 
        		sed "s/,{\"Key\":\"deployment_scenario\",\"Value\":\"$deployment\"}//" b.json > c.json
			mv c.json b.json
		fi
		if [ Z"$jdomain" != Z"" ]
		then 
			sed $sdomain b.json > c.json
			mv c.json b.json
		fi
		if [ Z"$name" != Z"" ]
		then
			sed "s/\"Name\":null/\"Name\":\"$name\"/" b.json > c.json
			mv c.json b.json
		fi
		# final cleanup
		sed 's/,,//g' b.json | sed 's/}{/},{/' | sed 's/\[,\]/\[\]/g' | 
		sed 's/\[,{/\[{/g' | sed 's/,\]/\]/' > c.json
		mv c.json b.json
		if [ $dryrun -eq 1 ]
		then
			cp b.json d.json
		fi
		$json_reformat < b.json > c.json
		mv c.json b.json
		
		if [ $dryrun -eq 0 ]
		then
			z=$x
			if [ -e "$dir/new.$ov" ]
			then
				z=$dir/new.$ov
			fi
			(cd $dir; $govc import.$ov -options $loc/b.json $z)
		else
			mv a.json ${y}.a.json
			mv b.json ${y}.b.json
		fi
	fi
done

if [ $nocleanup -eq 0 ]
then
	rm *.json new.ovf 2>/dev/null
	if [ $tmpdir -eq 1 ]
	then
		rm -rf $dir
	fi
fi
