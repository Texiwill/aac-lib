#!/bin/bash
#
# Copyright (c) 2017-2018 AstroArch Consulting, Inc. All rights reserved
#
VERSION="2.1"

function setup_qry() {
	m=$1
	if [ $usev1 -eq 0 ]
	then
		echo "clientcert: $m" > t.yaml
	fi
}

function oqry() {
	m=$1
	f=$2
	#rc=`grep -i "${m}::${f}:" $defaults|cut -d: -f 4|sed 's/^[ \t]\+//'`
	if [ $usev1 -eq 0 ]
	then
		echo -n "hiera -c $defaults -y t.yaml $f 2>/dev/null"
		rc=`hiera -c $defaults -y t.yaml $f 2>/dev/null`
		echo " ... $rc"
		if [ Z"$rc" = Z"nil" ]
		then
			rc=""
		fi
	else
		rc=`grep -i " ${f}-${m}$" $defaults|awk '{print $1}'`
	fi
}

rc=""
precheck=0
dryrun=0
nocleanup=0
ovaovf=""
usev1=0
dosetup=0
while [[ $# -gt 0 ]]
do
	key="$1"
	case $key in 
		--setup)
			dosetup=1
			;;
		-v1)
			usev1=1
			;;
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
		-y|--name)
			yz=$2; 
			shift;
			;;
		-h|--help)
			echo "Usage: $0 [[-p|--precheck]|[-d|--dryrun]|[-n|--nocleanup]|[-h|--help]] [-v1] [--setup] [-y name ] [ova/ovf file]"
			echo "  -y specifies alternative name to use for lookups in $HOME/.ov-imports"
			echo "  --dryrun implies --nocleanup"
			echo "	-v1 implies do not use hiera"
			echo "	--setup implies convert to hiera format"
			exit;
			;;
		-*)
			echo "Usage: $0 [[-p|--precheck]|[-d|--dryrun]|[-n|--nocleanup]|[-h|--help]] [-v1] [--setup] [-y name] [ova/ovf file]"
			echo "  -y specifies alternative name to use for lookups in $HOME/.ov-imports"
			echo "  --dryrun implies --nocleanup"
			echo "	-v1 implies do not use hiera"
			echo "	--setup implies convert to hiera format"
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
	echo "ERROR: We need ovftool somewhere in your path or /usr/local/bin"
	if [ $precheck -eq 0 ]
	then
		exit
	fi
fi
fuseiso=`which fuseiso`
if [ $? != 0 ]
then
	echo "INFO: We need fuseiso somewhere in your path for ISO images"
fi
fusermount=`which fusermount`
if [ $? != 0 ]
then
	echo "INFO: We need fusermount somewhere in your path for ISO images"
fi
hiera=`which hiera`
if [ $? != 0 ]
then
	echo "ERROR: We need hiera somewhere in your path for OV Facts"
	exit
fi

defdir=`dirname $0`
defaults=""
olddef=0
if [ -e $HOME/.ov-imports ] && [ $usev1 -eq 0 ]
then
	defaults=$HOME/.ov-imports/ov-defaults
elif [ -e $defdir/.ov-imports ] && [ $usev1 -eq 0 ]
then
	defaults=$defdir/.ov-imports/ov-defaults
elif [ -e .ov-imports ] && [ $usev1 -eq 0 ]
then
	defaults=`pwd`/.ov-imports/ov-defaults
else
	if [ -e $HOME/.ov-defaults ]
	then
		defaults="$HOME/.ov-defaults"
		olddef=1
		d=$HOME
	else
		if [ -e $defdir/.ov-defaults ]
		then
			defaults="$defdir/.ov-defaults"
			olddef=1
			d=$defdir
		elif [ -e .ov-defaults ]
		then
			defaults=".ov-defaults"
			olddef=1
			d=`pwd`
		fi
	fi
fi
if [ $olddef -eq 1 ] && [ $usev1 -eq 0 ]
then
	a=`grep -v \# $defaults | awk -F- '{print $NF}'| sort -u`
	mkdir ${d}/.ov-imports 2>/dev/null
	for x in $a; do echo '---' > ${d}/.ov-imports/${x}.yaml; grep -v \# $defaults|grep $x| sed "s/$x//"| sed 's/-$//' | awk '{printf "%s: %s\n",$2,$1}'| sed "s/: -$/: '-'/g" >> ${d}/.ov-imports/${x}.yaml; done
	cat << EOF >> ${d}/.ov-imports/ov-defaults
---
:backends:
  - yaml
:yaml:
  :datadir: "${d}/.ov-imports/"
:hierarchy:
  - "%{clientcert}"
  - "global"
EOF
	defaults=${d}/.ov-imports/ov-defaults
fi
if [ ! -e "$defaults" ]
then
	echo "We need a .ov-imports directory and related hiera files in $HOME, the directory of the script, or the directory containing the OVA/OVFs to process"
	exit
fi

if [ $dosetup -eq 1 ]
then
	echo "Setup Finished"
	exit
fi

missing="";
if [ $usev1 -eq 1 ]
then
	for x in domain netmask dns gw network vswitch ntp ceip syslog password ssh
	do
		oqry global ${x}
		z=$rc
		eval g${x}=$z
		if [ Z"$z" = Z"" ]
		then
			missing="$missing\tglobal::${x}\n"
		fi
	done
	if [ Z"$missing" != Z"" ]
	then
		echo "Missing these global definitions in $defaults"
		echo -e $missing
	fi
fi
# if we specified single file and it exists then do not unzip
dounzip=1
domount=0
dovcsa=0
if [ Z"$ovaovf" != Z"" ]
then
	# specific files do not unzip
	dounzip=0
	# Filetype
	yy=`awk -vs1="$ovaovf" 'BEGIN{ print tolower(s1)}'`
	echo $yy | fgrep ".iso" >& /dev/null
	if [ $? -eq 0 ]
	then
		domount=1
	fi
	echo $yy | fgrep ".zip" >& /dev/null
	if [ $? -eq 0 ]
	then
		dounzip=2
	fi
	echo $yy | fgrep "vmware-vcsa" >& /dev/null
	if [ $? -eq 0 ]
	then
		dovcsa=1
	fi
fi

# handle zip files
zipdir=0
ifiles=t.$$
if [ $dounzip -eq 1 ]
then
	for z in `ls *.zip 2>/dev/null`
	do
		zfiles="$zfiles `unzip -l $z |egrep -v 'Name|----' |awk '{print $4}' | egrep -v '^$'`"
		unzip $z
	done
fi
if [ $dounzip -eq 2 ]
then
	zipdir=1
	mkdir $ifiles
	cd $ifiles
	unzip ../$ovaovf
	ovaovf="";
fi
if [ $domount -eq 1 ]
then
	mkdir $ifiles
	$fuseiso -p $ovaovf $ifiles
	if [ $dovcsa -eq 1 ]
	then
		if [ -e $ifiles/vcsa/vmware-vcsa ]
		then
			zipdir=2
			xfiles=x.$$
			mkdir $xfiles
			cd $xfiles
			tar -xf ../$ifiles/vcsa/vmware-vcsa
			ovaovf=""
		fi
		if [ -e $ifiles/vcsa/*.ova ]
		then
			zipdir=3
			ovaovf=`ls $ifiles/vcsa/*.ova`
		fi
	else
		cd $zfiles
	fi
fi
echo $ovaovf

# Handle ova/ovf files
for x in `if [ Z"$ovaovf" != Z"" ]; then if [ -e "$ovaovf" ]; then ls $ovaovf; fi; else ls *.ova *.ovf 2>/dev/null; fi`
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
	if [ Z"$yz" = Z"" ]
	then
		name=`grep ^Name: a.txt|awk -F: '{print $2}'|sed 's/^ *//;s/ *$//'`
		if [ Z"$name" = Z"" ]
		then
			name=$y
		fi
	else
		name=$yz
	fi
	name=`echo $name|sed 's/_/ /g'|sed 's/(.*)//'|sed 's/\s*$//g'`


	# fallback to OVA/OVF name if necessary
	# but we really want the software name
	if [ Z"$name" != Z"" ]
	then
		y=`echo $name|sed 's/ /_/g'`
	fi

	if [ $usev1 -eq 0 ]
	then
		setup_qry $y
	fi

	# override name from key/value pairs
	# override y as well
	oqry ${y} override-name 
	yy=$rc
	if [ Z"$yy" != Z"" ]
	then
		echo -e "Using Override Name $yy"
		name=`echo $yy|sed 's/_/ /g'`
		y=$yy
	fi

	echo -e "Working on $name\n\tfrom file $x"

	# Check to see if we can import
	oqry ${y} noimport
	z=$rc
	if [ Z"$z" != Z"" ]
	then
		echo "INFO: As requested, will not import $y."
		continue
	fi
	
	# check for allExtraConfig needed by Nested
	allExtraConfig=""
	oqry ${y} allextraconfig
	z=$rc
	if [ Z"$z" = Z"1" ]
	then
		allExtraConfig="--allowAllExtraConfig --X:enableHiddenProperties"
	fi

	# count the network segments required
	networkl=`awk '/Networks:/{A=1}/Name:/{if (A==1) { print $0 }}/Virtual Machines/{exit}' a.txt|awk -F: '{print $2}'|sed 's/^ *//;s/ *$//'|sed 's/ /%20/g'`
	networks=`echo $networkl | wc -l`


	# determine where to stop the pre-check loop
	dobreak=""
	oqry ${y} break
	z=$rc
	if [ Z"$z" != Z"" ]
	then
		dobreak=$z
	fi

	# Now get the global defaults
	missing=""
	for xx in domain network vswitch ntp ssh ip netmask dns gw hostname ceip searchpath syslog
	do
		oqry ${y} $xx
		z=$rc
		eval ${xx}=$z
		if [ $usev1 -eq 1 ]
		then
			if [ Z"$z" = Z"" ]
			then
				#missing="$missing\tusing global for ${xx}-${y}\n"
				if [ $usev1 -eq 0 ]
				then
					eval ${xx}=\$g$xx
				fi
			fi
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
				oqry ${y} ${vet}
				z=$rc
				eval ${vet}=$z
			done
		done
	fi

	# Now we process the spec and replace with elements as needed
	# lets get the spec and do something interesting with it
	#vaminame=`awk '/^Virtual Machines:/{A=1}/Name:/{if (A==1) { print $0;exit}}' a.txt|awk -F: '{print $2}'|sed 's/^ *//;s/ *$//'`
	myfs=" "
	if [ $dryrun -eq 1 ]
	then
		myfs="\n"
	fi
	properties=`awk '/Properties:/{A=1}/ClassId:/{class=$0}/Key:/{key=$0;n=split(key,k,":");nkey=k[2];for(i=3;i<=n;i++) { nkey=sprintf("%s:%s",nkey,k[n]); }}/InstanceId/{if (A==1) { split(class,c,":");split($0,id,"Id");printf "%s.%s.%s\n",c[2],nkey,id[2];class="";A=2;}}/Label:/{if (A==1) {split(class,c,":");printf "%s.%s\n",c[2],nkey;} else {A=1;}}/Deployment Options/{exit}' a.txt | sed 's/ *//g'|sed 's/^\.//'`
	vservice=`awk '/^VService Dependency:/{A=1}/ID:/{id=$0}/Name:/{if (A==1) { split($0,k,":");split(id,i,":");printf "%s:%s\n",i[2],k[2];exit}}' a.txt|awk -F: '{print $2}'|sed 's/ *//g'|sed 's/^\.//'`

	#	namely 'deployment' often leads to errors
	#	as does vm.name
	#	as does not specifying IP info
	log="/tmp/ovftool-$$.log"
	prop="--X:logFile=$log --X:injectOvfEnv --X:logLevel=trivia --acceptAllEulas --allowExtraConfig --datastore=\"$GOVC_DATASTORE\" --diskMode=thin --noSSLVerify $allExtraConfig"
	c=1
	for n in $networkl
	do
		if [ $c -gt 1 ]
		then
			vet="network${c}"
			oqry ${y} $vet
			z=$rc
			#eval ${vet}=$z
			if [ Z"$z" = Z"" ]
			then
				missing="$missing\t${y}-${vet}\n"
			fi
			prop="$prop${myfs}--net:\"$n\"=\"$z\"";
		else 
			prop="$prop${myfs}--net:\"$n\"=\"$network\"";
		fi
		((c+=1))
	done
	oqry ${y} deployment
	z=$rc
	if [ Z"$z" != Z"" ]
	then
		prop="$prop${myfs}--deploymentOption=$z"
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
			*Password*)
				getpass=1
				;;
			*passwd*)
				getpass=1
				;;
			*rootpw*)
				getpass=1
				;;
			*pwd*)
				getpass=1
				;;
			*)
				dofind=1
				;;
		esac
		oqry ${y} $xx
		z=$rc
		if [ $dofind -eq 1 ]
		then
			if [ Z"$z" != Z"" ]
			then
				jg=$z
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
			oqry ${y} password
			pass=$rc
			if [ Z"$pass" = Z"" ]
			then
				if [ Z"$gpassword" != "" ] && [ $usev1 -eq 1 ]
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
			jg="$pass"
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

		if [ Z"$z" = Z"-" ]
		then
			# if value for key is - then do not set
			jg=""
			missing="$missing\tNot Using ${y}-${xx}\n"
		elif [ Z"$z" != Z"" ]
		then
			# if value for key is set then override
			jg=$z
			missing="$missing\tOverride w/Specific ${y}-${xx}\n"
		else
			if [ Z"$jg" = Z"" ]
			then
				missing="$missing\tMissing ${y}-${xx}\n"
			fi
		fi
		
		# for the '--prop' chain
		if [ Z"$jg" != Z"" ]
		then
			prop="$prop${myfs}--prop:'${xx}${hg}'='$jg'"
		fi
	done
	#fi
	if [ Z"$vservice" != Z"" ]
	then
		#z=`grep -i "extension-${y}$" $defaults|awk '{print $1}'`
		#if [ Z"$z" = Z"" ]
		#then
		#	missing="$missing\textension-${y}\n"
		#fi
		prop="$prop${myfs}--vService:installation=com.vmware.vim.vsm:extension_vservice"
	fi
	if [ Z"$missing" != Z"" ]
	then
        	echo "	Missing or Overridden Definition Information:"
        	echo -e $missing
	else
		echo ""
	fi
	#eprop=`echo "--name=\"$name\" $prop"|sed 's/%20/ /g'|sed 's/(/\\\\(/'|sed 's/)/\\\\)/'`
	target=$GOVC_RESOURCE_POOL
	oqry ${y} target
	tgt=$rc
	if [ Z"$tgt" != Z"" ]
	then
		target=$tgt
	fi
	eprop=`echo "--name=\"$name\"${myfs}$prop"|sed 's/%20/ /g'`
	if [ $precheck -eq 0 ]
	then
		if [ -Z"$GOVC_USERNAME" != Z"" ]
		then
			if [ $dryrun -eq 0 ]
			then
				eprop="$eprop $x vi://$GOVC_USERNAME:$GOVC_PASSWORD@$GOVC_URL$target"
			else
				eprop="$eprop${myfs}$x${myfs}vi://USERNAME:PASSWORD@$GOVC_URL$target"
			fi
		else
			eprop="$eprop $x vi://$GOVC_URL$target"
		fi
		if [ $dryrun -eq 0 ]
		then
			eval $ovftool $eprop
		else
			cp a.txt ${x}.a.txt
			echo -e "$ovftool $eprop" >> ${x}.a.txt
			echo -e "$ovftool $eprop"
		fi
	fi
done

if [ $nocleanup -eq 0 ]
then
	if [ $zipdir -gt 0 ]
	then
		# we are down in the files!
		if [ $zipdir -eq 2 ]
		then
			cd ..
		fi
		if [ $zipdir -gt 1 ]
		then
			fusermount -u $ifiles
		fi
	fi
	if [ $dryrun -eq 0 ]
	then
		rm *.a.txt a.txt t.yaml 2>/dev/null
		rm -rf $ifiles $xfiles
	fi
fi
