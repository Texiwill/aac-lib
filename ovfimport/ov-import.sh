#!/bin/bash
#
# Copyright (c) 2017 AstroArch Consulting, Inc. All rights reserved
#

precheck=0
dryrun=0
nocleanup=0
ovaovf=""
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
		-h|--help)
			echo "Usage: $0 [[-p|--precheck]|[-d|--dryrun]|[-n|--nocleanup]|[-h|--help]] [ova/ovf file]"
			echo "	--dryrun implies --nocleanup"
			exit;
			;;
		-*)
			echo "Usage: $0 [[-p|--precheck]|[-d|--dryrun]|[-n|--nocleanup]|[-h|--help]] [ova/ovf file]"
			echo "	--dryrun implies --nocleanup"
			exit;
			;;
		*)
			ovaovf="$1"
			;;
			
	esac
	shift
done

if [ -e ~/.govc ]
then
	. ~/.govc
else
	echo << EOF
We need some default settings for ovftool, which we look for in ~/.govc

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

ovftool=`which ovftool`
if [ $? != 0 ]
then
	echo "We need ovftool somewhere in your path or /usr/local/bin"
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
for x in domain netmask dns gw network vswitch ntp ceip syslog password
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

# if we specified single file and it exists then do not unzip
dounzip=1
if [ Z"$ovaovf" != Z"" ]
then
	dounzip=0
	if [ ! -e $ovaovf ]
	then
		dounzip=1
	fi
fi

# handle zip files
zipdir=0
zfiles=""
if [ $dounzip -eq 1 ]
then
	for z in `ls *.zip 2>/dev/null`
	do
		zipdir=1
		zfiles="$zfiles `unzip -l $z |egrep -v 'Name|----' |awk '{print $4}' | egrep -v '^$'`"
		unzip $z
	done
fi
	
if [ Z"$ovaovf" = Z"" ]
then
	ovaovf=`ls *.ova *.ovf 2> /dev/null | grep -v new.ovf`
fi

# Handle ova/ov files
for x in $ovaovf
do

	tmpdir=0
	# extract name of ova/ovf by file
	y=`echo ${x} | sed 's/[\.-][0-9].*$//'|sed 's/\.[a-Z].*$//'`
	# VRNI needs a bit more
	case ${x} in
		*proxy*)
			y="$y-proxy"
			;;
		*platform*)
			y="$y-platform"
			;;
	esac

	# extract the data from the OVA/OVF
	$ovftool --hideEula $x > a.txt

	# determine the OVA Name
	name=`grep ^Name: a.txt|awk -F: '{print $2}'|sed 's/^ *//;s/ *$//'`
	if [ Z"$name" = Z"" ]
	then
		name=$y
	fi
	name=`echo $name|sed 's/_/ /g'|sed 's/(.*)//'|sed 's/\s*$//g'`

	echo -e "Working on $name\n\tfrom file $x"

	# fallback to OVA/OVF name if necessary
	# but we really want the software name
	if [ Z"$name" != Z"" ]
	then
		y=`echo $name|sed 's/ /_/g'`
	fi

	# Check to see if we can import
	z=`grep -i noimport-${y} $defaults|awk '{print $1}'`
	if [ Z"$z" != Z"" ]
	then
		echo "INFO: As requested, will not import $y."
		continue
	fi
	
	# check for allExtraConfig needed by Nested
	allExtraConfig=""
	z=`grep -i allextraconfig-${y} $defaults|awk '{print $1}'`
	if [ Z"$z" = Z"1" ]
	then
		allExtraConfig="--allowAllExtraConfig --X:enableHiddenProperties"
	fi

	# count the network segments required
	networkl=`awk '/Networks:/{A=1}/Name:/{if (A==1) { print $0 }}/Virtual Machines/{exit}' a.txt|awk -F: '{print $2}'|sed 's/^ *//;s/ *$//'|sed 's/ /%20/g'`
	networks=`echo $networkl | wc -l`


	# determine where to stop the pre-check loop
	dobreak=""
	z=`grep -i break-${y} $defaults|awk '{print $1}'`
	if [ Z"$z" != Z"" ]
	then
		dobreak=$z
	fi

	# Now get the global defaults
	missing=""
	for xx in domain network vswitch ntp ssh ip netmask dns gw hostname ceip searchpath syslog
	do
		z=`grep -i ${xx}-${y} $defaults|awk '{print $1}'`
		eval ${xx}=$z
		if [ Z"$z" = Z"" ]
		then
			#missing="$missing\tusing global for ${xx}-${y}\n"
			eval ${xx}=\$g$xx
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
			done
		done
	fi

	# Now we process the spec and replace with elements as needed
	# lets get the spec and do something interesting with it
	#vaminame=`awk '/^Virtual Machines:/{A=1}/Name:/{if (A==1) { print $0;exit}}' a.txt|awk -F: '{print $2}'|sed 's/^ *//;s/ *$//'`
	properties=`awk '/Properties:/{A=1}/ClassId:/{class=$0}/Key:/{key=$0}/InstanceId/{if (A==1) { split(key,k,":");split(class,c,":");split($0,i,"Id");printf "%s.%s.%s\n",c[2],k[2],i[2];class="";A=2;}}/Category:/{if (A==1) {split(key,k,":");split(class,c,":");printf "%s.%s\n",c[2],k[2];} else {A=1;}}/Deployment Options/{exit}' a.txt | sed 's/ *//g'|sed 's/^\.//'`
	vservice=`awk '/^VService Dependency:/{A=1}/ID:/{id=$0}/Name:/{if (A==1) { split($0,k,":");split(id,i,":");printf "%s:%s\n",i[2],k[2];exit}}' a.txt|awk -F: '{print $2}'|sed 's/ *//g'|sed 's/^\.//'`

	#	namely 'deployment' often leads to errors
	#	as does vm.name
	#	as does not specifying IP info
	log="/tmp/ovftool-$$.log"
	prop="--X:logFile=$log --X:logLevel=trivia --acceptAllEulas --allowExtraConfig --datastore=\"$GOVC_DATASTORE\" --diskMode=thin --noSSLVerify $allExtraConfig"
	c=1
	for n in $networkl
	do
		if [ $c -gt 1 ]
		then
			vet="network${c}"
			z=`grep -i ${vet}-${y} $defaults|awk '{print $1}'`
			#eval ${vet}=$z
			if [ Z"$z" = Z"" ]
			then
				missing="$missing\t${vet}-${y}\n"
			fi
			prop="$prop --net:\"$n\"=\"$z\"";
		else 
			prop="$prop --net:\"$n\"=\"$network\"";
		fi
		((c+=1))
	done
	z=`grep -i deployment-${y} $defaults|awk '{print $1}'`
	if [ Z"$z" != Z"" ]
	then
		prop="$prop --deploymentOption=$z"
	fi
	for xx in $properties
	do
		hg=""
		jg=""
		getpass=0
		getshared=0
		dofind=0
		yy=`awk -vs1="$xx" 'BEGIN{ print tolower(s1)}'`
		case $yy in 
			*ipv6*)
				dofind=1
				;;
			*ceip*)
				jg=$ceip
				;;
			*ip*)
				jg=$ip
				;;
			*dns*)
				jg=$dns
				;;
			*gateway*)
				jg=$gw
				;;
			*netmask*)
				jg=$netmask
				;;
			*ntp*)
				jg=$ntp
				;;
			*hostname*)
				jg=$hostname
				;;
			*domain*)
				jg=$domain
				;;
			*ssh*)
				jg=$ssh
				;;
			*searchpath*)
				jg=$searchpath
				;;
			*syslog*)
				jg=$syslog
				;;
			*shared*)
				getshared=1
				;;
			*password*)
				getpass=1
				;;
			*passwd*)
				getpass=1
				;;
			*pwd*)
				getpass=1
				;;
			*)
				dofind=1
				;;
		esac
		if [ $dofind -eq 1 ]
		then
			z=`grep -i ${xx}-${y} $defaults|awk '{print $1}'`
			if [ Z"$z" != Z"" ]
			then
				jg=$z
			else
				missing="$missing\tmissing ${xx}-${y}\n"
			fi
		fi

		#case $xx in 
		#	vami*)
		#		hg=".${vaminame}"
		#		;;
		#esac
		# now for passwords
		spass=""
		pass=""
		if [ $getpass -eq 1 ]
		then
			pass=`grep -i password-${y} $defaults|awk '{print $1}'`
			if [ Z"$pass" = Z"" ]
			then
				if [ Z"$gpassword" != "" ]
				then
					pass=$gpassword
				else
					if [ $dryrun -eq 0 ]
					then
						echo -n "Enter $y Root Password: "
						read -s pass
					else
						pass="DRYRUN"
					fi
				fi
			fi
			jg="'$pass'"
		fi
		shared=""
		if [ $getshared -eq 1 ]
		then
			if [ $dryrun -eq 0 ]
			then
				echo -n "Enter $y Shared Secret: "
				read -s shared
			else
				shared="DRYRUN"
			fi
			jg="'$shared'"
		fi
		
		# for the '--prop' chain
		if [ Z"$jg" != Z"" ]
		then
			prop="$prop --prop:'${xx}${hg}'='$jg'"
		fi
	done
	#fi
	if [ Z"$vservice" != Z"" ]
	then
		#z=`grep -i extension-${y} $defaults|awk '{print $1}'`
		#if [ Z"$z" = Z"" ]
		#then
		#	missing="$missing\textension-${y}\n"
		#fi
		prop="$prop --vService:installation=com.vmware.vim.vsm:extension_vservice"
	fi
	if [ Z"$missing" != Z"" ]
	then
        	echo "	Missing or Overridden Definition Information:"
        	echo -e $missing
	else
		echo ""
	fi
	#eprop=`echo "--name=\"$name\" $prop"|sed 's/%20/ /g'|sed 's/(/\\\\(/'|sed 's/)/\\\\)/'`
	eprop=`echo "--name=\"$name\" $prop"|sed 's/%20/ /g'`
	if [ $precheck -eq 0 ]
	then
		if [ -Z"$GOVC_USERNAME" != Z"" ]
		then
			if [ $dryrun -eq 0 ]
			then
				eprop="$eprop $x vi://$GOVC_USERNAME:$GOVC_PASSWORD@$GOVC_URL$GOVC_RESOURCE_POOL"
			else
				eprop="$eprop $x vi://USERNAME:PASSWORD@$GOVC_URL$GOVC_RESOURCE_POOL"
			fi
		else
			eprop="$eprop $x vi://$GOVC_URL$GOVC_RESOURCE_POOL"
		fi
		if [ $dryrun -eq 0 ]
		then
			eval $ovftool $eprop
		else
			cp a.txt ${x}.a.txt
			echo "$ovftool $eprop" >> ${x}.a.txt
		fi
	fi
done

if [ $nocleanup -eq 0 ]
then
	if [ $dryrun -eq 0 ]
	then
		rm *.a.txt a.txt 2>/dev/null
	fi
fi
if [ $zipdir -eq 1 ]
then
	rm $zfiles
fi
