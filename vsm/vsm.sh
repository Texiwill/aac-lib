#!/bin/sh
#
# Copyright (c) AstroArch Consulting, Inc.  2017,2018
# All rights reserved
#
# A Linux version of VMware Software Manager (VSM) with some added intelligence
# the intelligence is around what to download and picking up things
# available but not strictly listed, as well as bypassing packages not
# created yet
#
# Requires:
# wget python python-urllib3 libxml2 perl-XML-Twig ncurses bc
#
# vim: tabstop=4 shiftwidth=4

VERSIONID="3.7.0"

# args: stmt error
function colorecho() {
	COLOR=$PURPLE
	if [ Z"$2" = Z"1" ]
	then
		COLOR=$RED
	fi
	if [ $docolor -eq 1 ]
	then
		echo "${COLOR}${1}${NC}"
	else
		echo ${1}
	fi
}
function debugecho() {
	if [ $dodebug -eq 1 ]
	then
		echo ${1}
	fi
}
function wgeterror() {
	err=$1
	debugecho "wget: $err"
	case "$err" in
	1) 
		colorecho "Generic Error Getting $name" 1
		;;
	2)
		colorecho "Parse Error Getting $name" 1
		;;
	3)
		colorecho "File Error: $name (disk full, etc.)" 1
		;;
	4)
		colorecho "Network Error Getting $name" 1
		;;
	5)
		colorecho "SSL Error Getting $name" 1
		;;
	6)
		colorecho "Credential Error Getting $name" 1
		;;
	7)
		colorecho "Protocol Error Getting $name" 1
		;;
	8)
		colorecho "Server Error Getting $name" 1
		;;
	esac
}

function mywget() {
	ou=$1
	hr=$2
	hd=$3
	if [ Z"$ou" = "-" ]
	then
		# getting pre-url
		lurl=`wget $_PROGRESS_OPT --max-redirect 0 --load-cookies $cdir/cookies.txt --header='User-Agent: VMwareSoftwareManagerDownloadService/1.5.0.4237942.4237942 Windows/2012ServerR2' -O - $hr 2>&1 | grep Location | awk '{print $2}'`
	else
		wget $_PROGRESS_OPT $hd --load-cookies $cdir/cookies.txt --header='User-Agent: VMwareSoftwareManagerDownloadService/1.5.0.4237942.4237942 Windows/2012ServerR2' -O $ou $hr
		err=$?
	fi
	wgeterror $err
}

function addpath() {
	mchoice="$mchoice/$choice"

	# need to strip first strings from 'Choice' So split on / and remove
	mychoice=`echo "$choice" | tr '[:upper:]' '[:lower:]'`
	for x in `echo $myvmware | sed 's#/# #g'`
	do
		mychoice=`echo $mychoice | sed "s/${x}_//"`
	done
	myvmware="$myvmware/$mychoice"
	debugecho "DEBUG: MyV: $myvmware"
	debugecho "DEBUG: MC: $mchoice"
}

function getpath() {
	mchoice=`dirname "$mchoice" 2>/dev/null`
	if [ Z"$myvmware" != Z"" ]
	then
		myvmware=`dirname "$myvmware" 2>/dev/null`
	fi
	if [ Z"$myvmware" = Z"" ]
	then
		myvmware="."
	fi
	debugecho "DEBUG: $mchoice"
}

function getchoice() {
	choice=`basename $mchoice`
}


function findmissing() {
	# Fake Suites
	reget=0
	if [ Z"$myvmware" != Z"" ]
	then
		myusenurl=''
		domyvm=`echo ${myvmware}| awk -F/ '{print NF}'`
		if [ $domyvm -gt 2 ]
		then
			case "$choice" in
				Infrastructure_Operations_Management_VMware_vRealize_Configuration_Manager)
					pkgs='Infrastructure_Operations_Management_VMware_vRealize_Configuration_Manager_5_8_4'
					myusenurl='/group/vmware/details?downloadGroup=VCM-584&productId=542'
					;;
				*)
					myname=`grep "${myvmware}/" ${rcdir}/_downloads.xhtml | cut -d\" -f 2|sed 's/Software-Defined/Software_Defined/'`
					myver=`grep "${myvmware}/" ${rcdir}/_downloads.xhtml | cut -d\" -f 14`
					myver=`basename $myver`
					pkgs=`echo "${choice}_${myver}" | sed 's/[ \.]/_/g'`
					debugecho "calc pkg => $pkgs"
					;;
			esac
		fi
	fi
	tpkg=`echo $pkgs | tr '[:upper:]' '[:lower:]'`
	# Fake xhtml
	for x in `echo $myvmware | sed 's#/# #g'`
	do
		tpkg=`echo $tpkg | sed "s/${x}_//g"`
	done
	spkg=`echo $tpkg | awk '{print $1}'`
	domyvm=`echo ${myvmware}/${spkg} | sed 's:/$::' |awk -F/ '{print NF}'`
	if [ $domyvm -eq 4 ]
	then
		pmiss=`echo $tpkg | sed 's/ /|/g'`
		myvmware=`echo $myvmware | sed 's#//#/#'`
		missname=`echo $myvmware | sed 's#/#_#g'`
		debugecho "DEBUG: $myvmware => $missname"
		if [ ! -e ${rcdir}/${missname}.xhtml ] || [ $doreset -eq 1 ] && [ Z"$myusenurl" = Z"" ]
		then
			mywget ${rcdir}/${missname}.xhtml ${myvmware_root}${myvmware}/$spkg 
			grep -i "Unable to Complete Your Request" ${rcdir}/${missname}.xhtml >& /dev/null
			err=$?
		else
			err=1
		fi
		if [ $err -ne 0 ]
		then
			tver=""
			if [ -e ${rcdir}/${missname}.xhtml ]
			then
				lv=`grep LINUXVDI ${rcdir}/$missname.xhtml 2> /dev/null`
				if [ $? -eq 0 ] && [ Z"$linuxvdi" = Z"" ]
				then
					linuxvdi=`echo $lv | cut -d= -f 3 | cut -d\& -f 1`
				fi
				if [ Z"$pmiss" != Z"" ]
				then
					tver=`grep $myvmware ${rcdir}/${missname}.xhtml |awk '{print $2}' | awk -F\" '{print $2}' | sed 's#/web/vmware/info/slug##g' | sed "s#${myvmware}/##g"|egrep -v $pmiss |egrep -v hidden`
				else
					tver=`grep $myvmware ${rcdir}/${missname}.xhtml |awk '{print $2}' | awk -F\" '{print $2}' | sed 's#/web/vmware/info/slug##g' | sed "s#${myvmware}/##g" |egrep -v hidden` 
				fi
			fi
			# missing pkg entries
			if [ Z"$tver" = Z"" ]
			then
				if [ Z"$usenurl" = Z"" ]
				then
					if [ Z"$myusenurl" = Z"" ]
					then
						usenurl=`grep "Go to Downloads" ${rcdir}/${missname}.xhtml | grep -v OSS | cut -d\" -f 4`
					else
						usenurl=$myusenurl
					fi
				fi
				#debugecho "N: $usenurl"
				if [ ! -e ${rcdir}/${missname}_1.xhtml ]
				then
					mywget ${rcdir}/${missname}_1.xhtml "https://my.vmware.com${usenurl}"
				fi
				# Now we need to get the versions
				tver=`grep downloadGroupId ${rcdir}/${missname}_1.xhtml | cut -d\" -f2`
				# pkgs change completely
				pkgs=""
			fi
			if [ Z"$tver" != Z"" ]
			then
				mc=`basename $mchoice`
				debugecho "DEBUG: Missing from $mc is $tver"
				for x in $tver
				do
					pkgs="$pkgs ${mc}_$x"
				done
				pkgs=`echo $pkgs | tr ' ' '\n' | sort -rV`
				missing=`echo $tver | sed 's/ /|/g'`
			fi
		else
			colorecho "My VMware Site issue request could not be completed" 1
		fi
	fi
}

function getoutervmware() {
	debugecho "DEBUG: $myvmware $choice $missing"
	if [ Z"$usenurl" = Z"" ]
	then
		spkg=`echo $choice | awk -F_ '{print $NF}'`
		missname=`echo ${myvmware} | sed 's/\//_/g'`
		if [ ! -e ${rcdir}/${missname}.xhtml ] || [ $doreset -eq 1 ]
		then
			mywget ${rcdir}/${missname}.xhtml ${myvmware_root}${myvmware}
		fi
		mversions=`xmllint --html --xpath "//tr[@class=\"clickable\"]" $rcdir/${missname}.xhtml 2>/dev/null | tr '\r\n' ' '|sed 's/[[:space:]]/+/g'| sed 's/<\/tr>/\n/g' |grep -v buttoncol | sed 's/[<>]/ /g' | awk '{print $11}'| sed 's/+/_/g'`
		f=`basename $mchoice`
		pkgs=""
		if [ Z"$mversions" != Z"" ]
		then
			for x in $mversions
			do
				echo $x | egrep -iv "_UWP|_Android|_IOS|Windows_Store" >& /dev/null
				if [ $? -eq 0 ]
				then
					#a=`echo ${f}_${x} | sed "s/_\(.\)/_\u\1/g" | sed "s/^\(.\)/\u\1/g"`
					pkgs="$pkgs ${f}_${x}"
				fi
			done
		else
			grep 'class="midProductColumn"' $rcdir/${missname}.xhtml >& /dev/null
			if [ $? -eq 0 ]
			then
				if [ Z"$usenurl" = Z"" ]
				then
					usenurl=`grep "Go to Downloads" ${rcdir}/${missname}.xhtml | grep -v OSS | cut -d\" -f 4`
				fi
				midprod=1
			fi
		fi
	fi
}

function getinnervmware() {
	# need to set $dlg here
	debugecho "IV: $choice $missname $mversions"
	if [ Z"$usenurl" != Z"" ]
	then
		#debugecho "N: $usenurl"
		ver=`echo $choice | sed 's/\.//g'| sed 's/.*_\([0-9]\+\)$/\1/'`
		if [ Z"$ver" != Z"$choice" ]
		then
		#	if [ ${#ver} -lt 3 ]
		#	then
				gld=`echo $usenurl | cut -d= -f 2 |cut -d\& -f1`
				missname="_dlg_${gld}"
				nurl=$usenurl
				pkgs="${gld}"
		#	else
		#		# version is not correct so get from usenurl
		#		gld=`echo $usenurl | sed 's/.*downloadGroup=\([a-Z]\+\).*/\1/'`
		#		nurl=`echo $usenurl | sed "s/${gld}-[0-9]\+\&/${gld}-${ver}\&/"`
		#		debugecho "N: $gld $ver"
		#		missname="_dlg_${gld}_${ver}"
		#		pkgs="${gld}_${ver}"
		#	fi
			if [ ! -e ${rcdir}/${missname}.xhtml ]
			then
				mywget ${rcdir}/${missname}.xhtml "https://my.vmware.com${nurl}"
			fi
			vsmnpkgs 1
		fi
	else
		#if [ $myfav -eq 1 ]
		#then
		#	wh=${favorite}
		#	ph=${mfavorite}
		#	mversions=`xmllint --html --xpath "//tr[@class=\"clickable\"]" $rcdir/${missname}.xhtml 2>/dev/null | tr '\r\n' ' '|sed 's/[[:space:]]/+/g'| sed 's/<\/tr>/\n/g' |grep -v buttoncol | sed 's/[<>]/ /g' | awk '{print $11}'| sed 's/+/_/g'`
		#else
			wh=`basename $mchoice`
			ph=`echo $mchoice | awk -F\/ '{a=NF-1; print $a}'`
		#fi
		wh=`echo $wh | sed "s/$ph//" | sed 's/_/ /g'|sed 's/^ //'`
		#debugecho "wh => :$wh:"
		what="midProductColumn\">$wh"
		swh=`echo $wh | sed 's/ /_/g'`
		wend=`echo $mversions | sed "s/.*$swh //"|awk '{print $1}'|sed 's/_/ /g'`
		if [ Z"$wend" = Z"" ] || [ Z"$wend" = Z"$wh" ]
		then
			wend="section"
		fi
		mv=`echo $mversions | sed 's/ /|/g'|sed 's/_/ /g'`
		debugecho "wend => $wend mv => $mv"
		if [ $dolatest -eq 1 ]
		then
			# finds what is on filesystem there now including latest
			pkgs=`egrep "downloadGroup|$mv" $rcdir/${missname}.xhtml | awk "/$what/,/$wend/"| egrep -v "$wh|buttoncol|$wend" |awk -F= '{print $3}'|awk -F\& '{print $1}'|sed 's/^/dlg_/'|sed 's/-/_/g'|sed 's/\(dlg_[a-Z_]\+[0-9][0-9]\).*$/\1/' | sort -u`
			vsmnpkgs
		else
			# lists what should be there ignoring filesystem
			pkgs=`egrep "downloadGroup|$mv" $rcdir/${missname}.xhtml | awk "/$what/,/$wend/"| egrep -v "$wh|buttoncol|$wend" |awk -F= '{print $3}'|awk -F\& '{print $1}'|sed 's/-/_/g'| sort -u`
			vsmnpkgs 1
		fi
	fi
	dlg=1
	myinnervm=1
	debugecho "DEBUG: $myvmware $vers $prod"
}

function getvmware() {
	if [ $domyvmware -eq 1 ]
	then
		debugecho "DEBUG: FM: ${missing} ${mversions}"
		if [ Z"$missing" = Z"" ]
		then
			myinnervm=0
			# Get missing suite versons
			debugecho "DEBUG: do FM"
			findmissing
		else
			if [ Z"$mversions" = Z"" ] && [ Z"$usenurl" = Z"" ] && [ $midprod -eq 0 ]
			then
				myinnervm=0
				# Get versions of suites
				debugecho "DEBUG: do OV"
				getoutervmware
				if [ $midprod -eq 1 ]
				then
					getinnervmware
				fi
			else
				# associate packages
				debugecho "DEBUG: do IV"
				getinnervmware
			fi
		fi
	fi
}
function backvmware() {
	if [ $domyvmware -eq 1 ]
	then
		mversions=""
		if [ $dlg -ne 2 ] || [ Z"$usenurl" != Z"" ]
		then
			mversions=""
			missing=""
			usenurl=""
			midprod=0
		fi
	fi
}

function vmwaremenu2() {
	ach=$choice
	mname=$missname
	if [ Z"$1" != Z"" ]
	then
		ach=$1
		mname="_dlg_$currchoice"
	fi
	debugecho "vmwaremenu2: $domyvmware $ach $mname"
	if [ $domyvmware -eq 1 ] && [ ! -e ${rcdir}/dlg_${ach}.xhtml ]
	then
		pkgs=''
		vsme=`echo $ach | sed 's/_/[-_]/g'`
		debugecho "DEBUG: vsme => $vsme"
		# will not work for dooss so need to know we are doing this
		vurl=`egrep "$vsme" ${rcdir}/${mname}.xhtml 2>/dev/null |grep -v OSS | head -1 | cut -d \" -f 2`
		debugecho "DEBUG: vurl => $vurl"
		if [ ! -e ${rcdir}/_dlg_${ach}.xhtml ] || [ $doreset -eq 1 ]
		then
			if [ Z"$vurl" != Z"" ]
			then
				mywget ${rcdir}/_dlg_${ach}.xhtml "https://my.vmware.com${vurl}"
			fi
		fi
		menu2files=1
		getvsmcnt $ach
		cnt=$?
		debugecho "DEBUG: menu2files => $menu2files"
		x=1
		while [ $x -le $cnt ]
		do
			getvsmdata $ach $x
			if [ Z"$pkgs" = Z"" ]
			then
				pkgs=$name
			else
				pkgs="$pkgs $name"
			fi
			$((x++)) 2> /dev/null
		done
		getouterrndir $ach
	fi
}

function getvsmcnt() {
	cchoice=$1
	if [ $menu2files -eq 0 ] || [ $domts -eq 1 ]
	then
		cnt=`xml_grep --html --pretty_print --cond '//*/[@class="depot-content"]' dlg_${cchoice}.xhtml 2>/dev/null  |grep display-order | wc -l`
	else
		cnt=`xmllint --html --xpath "//td[@class=\"filename\"]" _dlg_${cchoice}.xhtml 2> /dev/null | grep strong | wc -l`
	fi
	debugecho "DEBUG: getvsmcnt => $cnt"
	#let cnt=$cnt+1
	return $cnt
}

function getproddata() {
	if [ $myinnervm -eq 1 ]
	then
		vers=`grep selected $rcdir/${missname}.xhtml | awk -F\> '{print $2}'|awk -F\< '{print $1}'`
		prod=`grep '<title>' $rcdir/${missname}.xhtml|cut -d '>' -f 2|cut -d '<' -f 1 | sed 's/Download //' | sed 's/ [0-9]\+$//'`
	else
		prod=`xml_grep --html --text_only '*[@title="prod"]' ${prevchoice}.xhtml 2>/dev/null`
		vers=`xml_grep --html --text_only '*[@title="version"]' ${prevchoice}.xhtml 2>/dev/null`
	fi
	#debugecho "DEBUG: vers => $vers ; prod => $prod"
	eprod=`python -c "import urllib, sys; print urllib.quote(sys.argv[1])" "$prod" 2>/dev/null`
	prod=$eprod
	debugecho "DEBUG: vers => $vers ; prod => $prod"
}

function getouterrndir() {
	lchoice=$1
	rndll=''
	rndir=''
	like=''
	likeforlike=''
	rndll='download2.vmware.com'
	echo $lchoice  | egrep '_[0-9]|-[0-9]' >& /dev/null
	if [ $? -eq 0 ]
	then
		v=`echo ${lchoice} | sed 's/[0-9A-Z]\+[-_]\([0-9]\+\).*$/\1/' 2>/dev/null | awk -F_ '{print $NF}'`
	else
		v=`echo ${lchoice} | sed 's/[A-Z]\+\([0-9]\+\).*$/\1/' 2>/dev/null | awk -F_ '{print $NF}'`
	fi
	if [ Z"$v" = Z"$lchoice" ]
	then
		v=0
	fi
	debugecho "DEBUG: v => $v"
	case "$lchoice" in
		VRSLCM*)
			# special case VIC, VROPS, VC
			# Note VRSLCM_?? => VRSLCM10
			rndir='VRSLCM10'
			;;
		VS_PERL_SDK*)
			e=`echo $lchoice | sed "s/VS_PERL_SDK${v}//" | tr [:upper:] [:lower:]`
			if [ Z"$e" != Z"" ]
			then
				rndir="vsphere${v}/perlsdk/${v}${e}"
			else
				rndir="vsphere${v}/perlsdk"
			fi
			;;
		VDDK*)
			if [ $v -ge 652 ]
			then
				e=`echo $lchoice | awk -F_ '{print $NF}'`
				rndir="VDDK/$v/$e"
			else
				rndir="VDDK"
			fi
			;;
		VMTOOLS*)
			if [ $v -gt 1017 ]
			then
				rndir="vmtools/${v}"
			else
				rndir="vmtools"
			fi
			;;
		NSX_V_*_TOOLS)
			if [ $v -gt 612 ]
			then
				rndir="nsx-V-${v}"
			else
				rndir="nsx-V-610"
			fi
			;;
		VIO*)
			if [ $v -ge 400 ]
			then
				rndir='VIO'
			else
				rndir='VIO_3'
			fi
			;;
		LINUXVDI*)
			if [ $v -ge 740 ]
			then
				rntmp=`echo $lchoice | sed 's/LINUXVDI/HZ/g'`
				rndir="view/${rntmp}"
			elif [ $v -ge 730 ]
			then
				rndir='view/HZ18FQ4'
			else
				rndir='view'
			fi
			;;
		VVD*)
			if [ ${v} -gt 200 ]
			then
				rndir="vvd/${v}"
			else
				rndir="vvd"
			fi
			;;
		CART*|VIEWCLIENT*)
			rndll='download3.vmware.com'
			rntmp=`echo $lchoice | cut -d_ -f 1`
			rndir="view/viewclients/${rntmp}"
			;;
		HZNWS*)
			rndir='HZNWS20'
			;;
		VIEWCRT*)
			#rndll='download3.vmware.com'
			rndir="view/viewclients"
			;;
		VIEWLINUX*)
			rndir='view'
			;;
		VIEW*)
			if [ $v -ge 740 ]
			then
				rntmp=`echo $linuxvdi | sed 's/LINUXVDI/HZ/g'`
				rndir="view/${rntmp}"
			elif [ $v -ge 730 ]
			then
				rndir="view/HZ18FQ4"
			elif [ $v -eq 625 ]
			then
				rndir="view624"
			else
				rndir="view"
			fi
			;;
		HVRO*)
			rndir='HvCOplugin'
			;;
		THIN*)
			rns=`echo $lchoice | sed 's/THIN_//'`
			rntmp=`echo $lchoice | sed 's/THIN_//' | sed 's/\([0-9]0[1-9]\).*$/\1/'|sed 's/\([0-9][1-9]\).*$/\1/'`
			if [ $rns -gt 520 ]
			then
				rntmp="${rntmp}/$rns"
			fi
			rndir="thin/${rntmp}"
			;;
		UEM*)
			rndir='UEM'
			;;
		MIRAGE*)
			if [ $v -gt 540 ]
			then
				rntmp=`echo $lchoice | sed 's/MIRAGE_//'|sed 's/_TOOLS//'`
				rndir="mirage/${rntmp}"
			else
				rndir="mirage"
			fi
			;;
		AV_*)
			if [ $v -ge 2132 ]
			then
				rndir="AppVolumes/${v}"
			else
				rndir='AppVolumes'
			fi
			;;
		V4H*)
			if [ $v -gt 650 ]
			then
				rntmp=`echo $lchoice | sed 's/_GA//g' | tr [:upper:] [:lower:]`
				rndir="vcops/${rntmp}"
			else
				rndir="vcops"
			fi
			;;
		V4PA*)
			if [ $v -gt 650 ]
			then
				rntmp=`echo $lchoice | sed 's/_GA//g' | tr [:upper:] [:lower:]`
				rndir="v4pa/${rntmp}"
			else
				rndir="v4pa"
			fi
			;;
		FUS*)
			rndll='download3.vmware.com'
			rndir='fusion/file'
			;;
		WKST*)
			rndll='download3.vmware.com'
			rndir='wkst/file'
			;;
		VIDM_ONPREM*)
			rntmp=`echo $lchoice | sed 's/[0-9]//g'`
			rndir="${rntmp}${pver}"
			;;
		VRLI*)
			if [ $v -gt 450 ]
			then
				rndir='strata1'
			else
				rndir='strata'
			fi
			;;
		*)
			echo $lchoice | grep VCENTER >& /dev/null
			lvcenter=$?
			echo $lchoice | grep U >& /dev/null
			uvcenter=$?
			if [ $uvcenter -eq 0 ]
			then
				likeforhead=`echo $lchoice | sed 's/\([a-Z_]\+[0-9][0-9]\).*$/\1/'`
				likefortail=`echo $lchoice | sed "s/${likeforhead}//" | sed 's/\([0-9U]\).*/\1/' | sed 's/[0-9]/[0-9]/' | sed 's/U$//'`
				likeforlike="$likeforhead$likefortail"
			else
				likeforlike=`echo $lchoice | sed 's/\([a-Z_]\+[0-9][0-9]\).*$/\1/' | sed 's/[0-9]/[0-9]/g' | sed 's/U$//'`
			fi
			debugecho "DEBUG: likeforlike => $likeforlike"
			if [ $lvcenter -eq 0 ]
			then
				like=`ls dlg_${likeforlike}*VCENTER.xhtml 2>/dev/null | grep -v OSS | sort -uV | tail -1`
			else
				like=`ls dlg_${likeforlike}*.xhtml 2>/dev/null | grep -v OSS | sort -uV | tail -1`
			fi
			if [ Z"$like" != Z"" ]
			then
				ename=`grep download_url $like | head -1 | sed 's/<li/\n<li/g' | grep download_url |sed 's/[<>]/ /g' | cut -d' ' -f4`
				rndll=`echo $ename | cut -d\/ -f3`
				rndir=`dirname $ename | sed 's/https:\/\/download[23].vmware.com\/software\///'`
				debugecho "DEBUG: ename => $ename"
				debugecho "DEBUG: rndll => $rndll"
				debugecho "DEBUG: rndir => $rndir"
			fi
			;;
	esac
}

function getinnerrndir() {
	if [ $domyvmware -eq 1 ]
	then
		lchoice=$1
		dnlike="$lchoice"
		# sometimes name is not in the same directory! 
		# So go for most recent versions location
		ename=`echo $name | sed 's/[0-9]/[0-9]/g'`
		debugecho "DEBUG: ename => $ename"
		debugecho "DEBUG: lforl => $likeforlike"
		echo $lchoice | grep VCENTER >& /dev/null
		lvcenter=$?
		if [ Z"$likeforlike" != Z"" ]
		then
			if [ $lvcenter -eq 0 ]
			then
				nlike=`grep -l $ename ${rcdir}/dlg_${likeforlike}*VCENTER.xhtml 2>/dev/null| grep -v OSS | sort -uV | tail -1| sed 's/.*\/dlg_//' | sed 's/\.xhtml//'`
			else
				nlike=`grep -l $ename ${rcdir}/dlg_${likeforlike}*.xhtml 2>/dev/null| grep -v OSS | sort -uV | tail -1 | sed 's/.*\/dlg_//' | sed 's/\.xhtml//'`
			fi
			# no per file so go older method
			debugecho "DEBUG: like => $like; nlike => $nlike"
			if [ Z"$nlike" != Z"" ] && [ Z"dlg_${nlike}.xhtml" != Z"$like" ]
			then
				ename=`egrep $ename ${rcdir}/dlg_${nlike}.xhtml | sed 's/<li/\n<li/g' | grep download_url |sed 's/[<>]/ /g' | cut -d' ' -f4`
				dnlike=$nlike
				debugecho "DEBUG: ename => $ename"
				if [ Z"$ename" != Z"" ]
				then
					rndll=`echo $ename | cut -d\/ -f3`
					rndir=`dirname $ename | sed 's/https:\/\/download[23].vmware.com\/software\///'`
				fi
			fi
			debugecho "DEBUG: rndir => $rndir"
		fi
		case "$dnlike" in
			VIDM*)
				case "$name" in
					clients*)
						rntmp=`echo $name | sed 's/.*-\([0-9]\.[0-9]\).*$/\1/'`
						rndir="VIDM_ONPREM_${rntmp}"
						;;
					VMware-Identity-*-Desktop-*)
						rntmp=`echo $name | sed 's/.*-\([0-9]\.[0-9]\).*$/\1/'`
						rndir="VIDM_ONPREM_${rntmp}"
						;;
					euc-unified-access-*-3.0.0*)
						rndir="view"
						;;
					euc-unified-access-*)
						rntmp=`echo $name | sed 's/.*-\([0-9]\.[0-9]\).*$/\1/' | sed 's/\.//'`
						rndir="UAG_${rntmp}"
						;;
				esac
				;;	
			VIEW_62*)
				case "$name" in
					VMware-Horizon-View-Extras*|VMware-viewagent-linux*)
						rndir="view"
						;;
				esac
				;;
			LINUXVDI*|VIEW*)
				case "$name" in
					euc-unified-access-*-3.0.0*)
						rndir="view"
						;;
					euc-unified-access-*)
						rntmp=`echo $name | sed 's/.*-\([0-9]\.[0-9]\).*$/\1/' | sed 's/\.//'`
						rndir="UAG_${rntmp}"
						;;
				esac
				;;
			V4H*|V4PA*)
				case "$name" in
					vRealize[_-]Operations*)
						m=`echo $name | sed 's/\.//g'|sed 's/.*[_-]\([0-9][0-9][0-9]\).*$/\1/'`
						if [ $m -eq 601 ]
						then
							m=600
						fi
						rndir="vrops${m}"
						;;
				esac
				;;
			VROPS*)	
				m="${dnlike//[^[:digit:]]/}"
				rndir="vrops${m}"
				;;
			VC55*)
				case "$name" in
					VMware-VIMSetup-all-*update03*)
						rndir="vi2/55"
						;;
					VMware-vCenter-*30700*)
						rndir="vi2/55"
						;;
				esac
				;;
			VC65*)	
				case "$name" in 
					VMware-VIM*)
						dnlike="$lchoice";
						;;
				esac
				# Do the std if we are not using nlike
				if [ Z"$dnlike" = Z"$lchoice" ]
				then
					n=`echo $dnlike | sed 's/VC[0-9][0-9]//' | tr [:upper:] [:lower:]`
					m=`echo $dnlike | sed 's/VC//' | sed "s/$n//i"`
					rndir="vc/$m/$n"
				fi
				;;
			VIC*)	
				m="${dnlike//[^[:digit:]]/}"
				m=`echo $m | sed -e 's/\(.\)/\1\./g' |sed 's/\.$//'`
				rndir="vic${m}"
				;;
		esac
	
		if [ Z"$rndir" = Z"" ]
		then
			if [ -e _dlg_${lchoice}.xhtml ]
			then
				rndir=`grep "Release Notes" _dlg_${lchoice}.xhtml| cut -d\" -f2| cut -d/ -f6,7`
			fi
		fi
		if [ Z"$rndir" != Z"" ]
		then
			debugecho "DEBUG: like => $like"
			debugecho "DEBUG: rndll => $rndll" 
			debugecho "DEBUG: rndir => $rndir"
		fi
	fi
}

function getvsmdata() {
	cchoice=$1
	xx=$2
	if [ $menu2files -eq 0 ] || [ $domts -eq 1 ]
	then
		data=`xmllint --html --xpath "//*/li[@class=\"depot-content\"][$xx]" dlg_${cchoice}.xhtml 2>/dev/null`
		name=`echo $data|xml_grep --html --text_only '//*/a' 2>/dev/null`
	else
		pver=`xmllint --html --xpath "//tr" _dlg_${cchoice}.xhtml  2> /dev/null  | tr '\n' ' ' |sed 's/<\/tr>/<\/tr>\n/' |head -1 |sed 's/<t[hd]>//g' |sed 's/<\/t[hd]>//g' |awk '{print $3}'`
		if [ Z"$pver" = Z"Version" ]
		then
			pver=`grep selected _dlg_${cchoice}.xhtml |head -1 | cut -d\" -f2`
		fi
		data=`xmllint --html --xpath "//td[@class=\"filename\"][$xx]" _dlg_${cchoice}.xhtml 2> /dev/null`
		name=`echo $data|sed 's/<br>/\n/g' |sed 's/<\/span>/\n/g' | grep fileNameHolder | cut -d '>' -f 2 | sed 's/ //g'`
	fi
	debugecho "DEBUG: name => $name"
	#debugecho "DEBUG: data => $data"
}

function getasso() {
	moreasso=""
	preasso=""
	assomissing=""
	dts=""
	oss=""
	oem=""
	assomiss=0
	if [ $domyvmware -eq 1 ] && [ ! -e dlg_${choice}.xhtml ]
	then
		vmwaremenu2
	fi
	if [ -e dlg_${choice}.xhtml ]
	then
		asso=`xml_grep --html --text_only '*[@title="associated-channels"]' dlg_${choice}.xhtml  2>/dev/null| sed 's/,//g'|sed 's/dlg_//g'`
		moreasso="dlg"
	elif [ -e _dlg_${choice}.xhtml ]
	then
		assomiss=1
		# Get ASSO from my vmware bits
		asso=`xmllint --html --xpath "//div[@class=\"activitiesLog\"]" _dlg_${choice}.xhtml 2>/dev/null |grep secondary | cut -d= -f3 | cut -d\& -f 1 | sed 's/-/_/g'`
		moreasso="_dlg"
	fi
	debugecho "DEBUG: moreasso => $moreasso"
	if [ Z"$moreasso" != Z"" ]
	then
		# sometimes things exist that are not in asso lists
		# sometimes they use similar version numbers
		rchoice=`echo $choice | sed 's/U/*U/'` 
		for x in `ls ${moreasso}*${rchoice}_*.xhtml 2>/dev/null | grep -v ${moreasso}_${choice}.xhtml | grep -v VCENTER`
		do
			y=`echo $x | sed 's/\.xhtml//'|sed "s/${moreasso}_//"`
			if [ Z"$asso" = Z"" ]
			then
				asso=$y
			else
				asso="$asso $y"
			fi
		done
	fi

	# Now go through asso list and split into parts
	for x in $asso
	do
		# debugecho "$choice: $x"
		# sometimes files do not exist!
		if [ -e dlg_${x}.xhtml ]
		then
			preasso="dlg_"
		else
			if [ $assomiss -eq 1 ]
			then
				preasso="_dlg_"
				assomissing="$assomissing $x"
			else
				wouldassomiss=1
				continue
			fi
		fi
		echo $x | grep OEM > /dev/null
		if [ $? -eq 0 ]
		then
			if [ Z"$oemlist" = Z"" ]
			then
				oemlist="${preasso}$x"
			else
				oemlist="$oemlist ${preasso}$x"
			fi
			oem="CustomIso"
		else
			echo $x | egrep "OSS|OSL|OPENSOURCE" > /dev/null
			if [ $? -eq 0 ]
			then
				if [ Z"$osslist" = Z"" ]
				then
					osslist="${preasso}$x"
				else
					osslist="$osslist ${preasso}$x"
				fi
				oss="OpenSource"
			else
				if [ Z"$dtslist" = Z"" ]
				then
					dtslist="${preasso}$x"
				else
					dtslist="$dtslist ${preasso}$x"
				fi
				dts="DriversTools"
			fi
		fi
	done
	debugecho "DEBUG: dtslist => $dtslist"
	debugecho "DEBUG: osslist => $osslist"
	debugecho "DEBUG: assomissing => $assomissing"
}

function vsmnpkgs() {
	dim=0
	if [ Z"$1" != Z"" ]
	then
		dim=$1
	fi
	npkg=""
	for x in $pkgs
	do
		l=${#x}
		$((l++)) 2> /dev/null
		e=$((l+1))
		# ignore VCENTER is a special case
		if [ $dim -eq 0 ]
		then
			# find latest
			a=`ls ${x}* 2>/dev/null| grep -v 'OSS' | sed 's/\.xhtml//' | sed 's/U/0U/' | sort -rn -k1.${l},1.${e} | sort -n | sed 's/0U/U/' | egrep -v 'VCENTER|PLUGIN|SDK|OSL' | tail -1 | sed 's/dlg_//'`
		else
			# find available
			xy=`echo $x | sed 's/-/_/g'`
			if [ -e dlg_${x}.xhtml ] && [ -d ${repo}/dlg_${xy} ]
			then
				a=$x
			elif [ -e dlg_${x}.xhtml ] && [ ! -d ${repo}/dlg_${xy} ]
			then
				a="${BOLD}${x}${NC}"
			elif [ ! -e dlg_${x}.xhtml ] && [ -d ${repo}/dlg_${xy} ]
			then
				a="${TEAL}${x}${NC}"
			else
				a="${BOLD}${TEAL}${x}${NC}"
			fi
		fi
		if [ Z"$npkg" = Z"" ]
		then
			npkg=$a
		else
			npkg="${npkg} ${a}"
		fi
	done
	pkgs=$npkg
}

function vsmpkgs() {
	file=$1
	pkgs=""
	if [ $choice = "Desktop_End_User_Computing" ]
	then
		# need to get this
		pkgs="Desktop_End_User_Computing_VMware_Horizon Desktop_End_User_Computing_VMware_Horizon_Clients Desktop_End_User_Computing_VMware_Fusion Desktop_End_User_Computing_VMware_Workstation_Pro"
		##
		# Fusion is part of Horizon and has an issue
		#  Desktop_End_User_Computing_VMware_Fusion
		##
	else
		if [ $dlg -gt 0 ]
		then
			if [ $dolatest -eq 1 ]
			then
				pkgs=`xml_grep --text_only '//*/a' $file  2>/dev/null| sed 's/\(dlg_[a-Z_]\+[0-9][0-9]\).*$/\1/' | sort -u`
				vsmnpkgs
			fi
		fi
		if [ Z"$pkgs" = Z"" ]
		then
			if [ -e $file ]
			then
				pkgs=`xml_grep --text_only '//*/a' $file  2>/dev/null| sed 's/dlg_//' | sed 's/\.xhtml//' | sed 's/,//g' `
			fi
			getvmware 
		fi
		if [ $choice = "Datacenter_Cloud_Infrastructure" ]
		then
			pkgs="$pkgs Datacenter_Cloud_Infrastructure_VMware_Validated_Design_for_Software_Defined_Data_Center"
			mversions=''
		elif [ $choice = "Infrastructure_Operations_Management" ]
		then
			if [ $dovex -eq 1 ]
			then
				pkgs="$pkgs Infrastructure_Operations_Management_VMware_Integrated_OpenStack"
				# Infrastructure_Operations_Management_VMware_vRealize_Configuration_Manager
			fi
			mversions=''
		fi
	fi
	debugecho "DEBUG vsmpkgs: $pkgs"
}

function save_vsmrc() {
	colorecho "Saving to $HOME/.vsmrc"
	echo -n '' > $HOME/.vsmrc
	if [ $domyvmware -eq 1 ] && [ Z"$mchoice" != Z"" ]
	then
		if [ ! -e ${rcdir}/${favorite}.xhtml ]
		then
			favorite=${favorite}
		fi
	fi
	if [ Z"$mchoice" = Z"root" ]
	then
		echo "mfchoice='$mfchoice'" >> $HOME/.vsmrc
		echo "myfvmware='$myfvmware'" >> $HOME/.vsmrc
	else
		echo "mfchoice='$mchoice'" >> $HOME/.vsmrc
		echo "myfvmware='$myvmware'" >> $HOME/.vsmrc
	fi
	echo "favorite='$favorite'" >> $HOME/.vsmrc
	if [ $dosave -eq 1 ]
	then
		echo "repo='$repo'" >> $HOME/.vsmrc
		echo "cdir='$cdir'" >> $HOME/.vsmrc
		echo "myoem=$myoem" >> $HOME/.vsmrc
		echo "mydts=$mydts" >> $HOME/.vsmrc
		echo "myoss=$myoss" >> $HOME/.vsmrc
	fi
}

function stripcolor() {
	debugecho "SC: $choice"
	echo $choice | fgrep '[' >& /dev/null
	if [ $? -eq 0 ]
	then
		choice=`echo $choice | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g" | sed -r "s/\x1B\(B//g"`
	fi
	debugecho "SC: $choice"
}

function menu() {
	all=""
	alln=""
	allm=""
	file=$1
	mark=""
	if [ Z"$1" = Z"All" ]
	then
		all=$1
		file=$2
		#if [ $myinnervm -eq 0 ]
		#then
			mark="Mark"
		#fi
		if [ Z"$3" = Z"All_Plus_OpenSource" ]
		then
			allm=$2
			alln=$3
			file=$4
		fi
	fi
	back="Back"
	if [ Z"$choice" = Z"root" ]
	then
		usenurl=""
		linuxvdi=""
		myvmware=""
		midprod=0
		menu2files=0
		missing=""
		missname=""
		mversions=""
		back=""
	fi
	debugecho "MENU: $file $domenu2 $dlg"
	if [ $domenu2 -eq 0 ]
	then
		vsmpkgs $file
		if [ Z"$choice" = Z"root" ] && [ $domyvmware -eq 1 ] && [ $dovex -eq 1 ]
		then
			pkgs="$pkgs Desktop_End_User_Computing"
		fi
		# need to recreate dlg=1 here due to myvmware
		if [ $domyvmware -eq 1 ] && [ $dlg -eq 1 ]
		then
			all="All"
			alln="All_Plus_OpenSource"
			allm="Minimum_Required"
			mark="Mark"
			dlg=2
			if [ Z"$prevchoice" = Z"" ]
                	then
                        	prevchoice=$choice
                	fi
		fi
	fi
	export COLUMNS=20
	select choice in $all $allm $alln $pkgs $mark $back Exit
	do
		if [ Z"$choice" != Z"" ]
		then
			## needed if we allow
			stripcolor
			## this is disallow for now
			#echo $choice | fgrep '[' >& /dev/null
			#if [ $? -eq 0 ]
			#then
			#	echo -n "Please select a NON-TEAL item:"
			#	continue
			#fi
			if [ $choice = "Exit" ]
			then
				exit
			fi
			if [ $choice = "Mark" ]
			then
				favorite=$prevchoice
				colorecho "Favorite: $favorite"
				save_vsmrc
			else
				break
			fi
		else
			echo -n "Please enter a valid numeric number:"
		fi
	done
	if [ $choice != "Back" ]
	then
		addpath
	fi
}

function menu2() {
	all=""
	debugecho "MENU2: $1"
	if [ Z"$2" = Z"OpenSource" ]
	then
		all="All_Plus_OpenSource"
	fi
	if [ -e $1 ]
	then
		pkgs=`xml_grep --text_only '//*/a' $1 2>/dev/null`
	else
		vmwaremenu2
	fi
	npkg=""
	f=`echo $1 |sed 's/\.xhtml//' | sed 's/-/_/g'`
	for x in $pkgs
	do
		if [ ! -e ${repo}/${f}/${x} ] && [ ! -e ${repo}/${f}/${x}.gz ]
		then
			if [ Z"$npkg" = Z"" ]
			then
				npkg="${BOLD}${x}${NB}"	
			else
				npkg="$npkg ${BOLD}${x}${NB}"
			fi
		else
			if [ Z"$npkg" = Z"" ]
			then
				npkg="$x"
			else
				npkg="$npkg $x"
			fi
		fi
	done
	debugecho "MENU2: $1 $2 $3 $4"
	export COLUMNS=30
	select choice in All Minimum_Required $all $npkg $2 $3 $4 Back Exit
	do
		if [ Z"$choice" != Z"" ]
		then
			stripcolor
			if [ $choice = "Exit" ]
			then
				exit
			fi
			break
		else
			echo -n "Please enter a valid numeric number:"
		fi
	done
	if [ $choice != "Back" ]
	then
		addpath
	fi
}

function getvsmparams() {
	if [ $menu2files -eq 0 ] || [ $domts -eq 1 ]
	then
		# xhtml
		href=`echo $data | xml_grep --pretty_print  --html --cond '//*/[@href]' 2>/dev/null | sed 's/ /\r\n/g' | grep href | awk -F\" '{print $2}'`
		#drparams=`echo $data|xml_grep --html --text_only '//*/[@title="drparams"]' 2>/dev/null`
		drparams=`echo $data|sed 's/drparams/\ndrparams/' | tail -1 | sed 's/[><]/ /g' | cut -d' ' -f 2`
		durl=`echo $data|sed 's/download_url/\ndownload_url/' | tail -1 | sed 's/[><]/ /g' | cut -d' ' -f 2`
	else
		# My VMware
		# nuts n bolts
		#debugecho "DEBUG: data => $data"
		fname=`echo $data | sed 's/<\/span>/<\/span>\n/g'|grep fileNameHolder|cut -d\> -f2 |cut -d' ' -f1`
		tsize=`echo $data | sed 's/<br>/\n/g' |sed 's/<\/span>/\n/g'| sed -n '3p' | sed 's/^: //'`
		size=`echo $tsize | cut -d ' ' -f 1`
		units=`echo $tsize | cut -d ' ' -f 2`
		#debugecho "DEBUG: size => $size ; units => $units"
		fdata=`echo $data | sed 's/<\/a>/\n/g'| sed 's/<\/span/\n/g'|grep "button primary"`
		echo $fdata |egrep "CART|viewclients" >& /dev/null
		if [ $? -eq 0 ]
		then
			drparams="CART"
			href=`echo $fdata | cut -d\" -f 4`
			durl=''
		else
			ndata=`echo $fdata | cut -d\" -f 6 | sed 's/amp;//g'| sed 's/[\&\?=]/ /g'`
			#debugecho "DEBUG: ndata => $ndata"
			size=`echo "$size *1024"|bc` # KB
			if [ Z"$units" = Z"MB" ] || [ Z"$units" = Z"GB" ]
			then # GB
				size=`echo "$size *1024"|bc`
			fi
			if [ Z"$units" = Z"GB" ]
			then # GB
				size=`echo "$size *1000"|bc`
			fi
			size=`printf '%d\n' "$size" 2>/dev/null`
			dlgcode=`echo $ndata | cut -d' ' -f3`
			downloaduuid=`echo $ndata | cut -d ' ' -f13`
			if [ Z"$vers" = Z"" ]
			then
				vers=$pver
			fi
			# one off
			if [ Z"$dlgcode" = Z"VRLI-451-VCENTER" ]
			then
				dlgcode="VRLI-451"
			fi
			dtr="{\"sourcefilesize\":\"$size\",\"dlgcode\":\"$dlgcode\",\"languagecode\":\"en\",\"source\":\"vswa\",\"downloadtype\":\"manual\",\"eula\":\"Y\",\"downloaduuid\":\"$downloaduuid\",\"purchased\":\"Y\",\"dlgtype\":\"Product+Binaries\",\"productversion\":\"$pver\"}"
			debugecho "DEBUG: drparams => $dtr"
			drparams=`python -c "import urllib, sys; print urllib.quote(sys.argv[1])" $dtr`
			href="https://depot.vmware.com/getAuthUrl"
			#https://download2.vmware.com/software/vcops/v4h_651/Reports_V4VAdapter-6.5.1-7363818.zip
			durl="https://${rndll}/software/${rndir}/${fname}"
		fi
		debugecho "DEBUG: durl => $durl"
		#durl=`python -c "import urllib, sys; print urllib.quote(sys.argv[1])" $sdu`
	fi
}

function getvsm() {
	lchoice=$1
	additional=$2
	tchoice=$lchoice
	if [ Z"$3" != Z"" ]
	then
		tchoice=$3
	fi
	ldir=`echo $lchoice | sed 's/-/_/g'`

	# this gets the repo items
	# check if file or file.gz
	# does not exist
	cd $repo
	if [ ! -e dlg_$ldir ]
	then
		mkdir dlg_$ldir
	fi
	cd dlg_$ldir 
	if [ Z"$additional" != Z"base" ] 
	then
		if [ ! -e $additional ]
		then
			mkdir $additional
		fi
		cd $additional
	fi
	debugecho "DEBUG: $currchoice: `pwd`"
	dovsmit=1

	# EDGE from NSX downloaded as part of 'main' not dts
	echo $tchoice | grep EDGE >& /dev/null
	if [ $? -eq 0 ]
	then
		dovsmit=0
	fi
	# open source when not selected!
	if [ $additional != "OpenSource" ]
	then
		echo $name | egrep 'ODP|open_source' >/dev/null
		if [ $? -eq 0 ]
		then
			debugecho "DEBUG: Not in OSS Mode: $name"
			dovsmit=0
		fi
	fi
	
	if [ $dovsmit -eq 1 ]
	then
		if  ([ ! -e ${name} ] && [ ! -e ${name}.gz ]) || [ $doforce -eq 1 ]
		then 
			debugecho "DEBUG: $currchoice $name"
			if [ $menu2files -eq 1 ] || [ $domts -eq 1 ]
			then
				getinnerrndir $tchoice
			fi
			#echo "Download $name to `pwd`?"
			#read c
			getvsmparams
			if [ Z"$drparams" = Z"CART" ]
			then
				url=$href
			else
				url="$href?params=$drparams&downloadurl=$durl&familyversion=$vers&productfamily=$prod"
			fi
			debugecho "DEBUG: url => $url"
			if [ $dryrun -eq 0 ]
			then
				if [ Z"$drparams" = Z"CART" ]
				then
					lurl=$url
				else
					lurl=`wget $_PROGRESS_OPT --max-redirect 0 --load-cookies $cdir/cookies.txt --header='User-Agent: VMwareSoftwareManagerDownloadService/1.5.0.4237942.4237942 Windows/2012ServerR2' $url 2>&1 | grep Location | awk '{print $2}'`
				fi
				debugecho "DEBUG: lurl => $lurl"
				echo $lurl|grep -i blocked >& /dev/null
				if [ $? -ne 0 ]
				then
					if [ Z"$lurl" != Z"" ]
					then
						eurl=`python -c "import urllib, sys; print urllib.unquote(sys.argv[1])" $lurl`
						debugecho "DEBUG: eurl => $eurl"
						mywget $name $eurl "--progress=bar:force -nd"
						diddownload=0
						# echo if error remove file
						if [ $err -ne 0 ]
						then
							rm $name
						else
							diddownload=1
						fi
					else
						colorecho "No Redirect Error Getting $name" 1
					fi
				else
						colorecho "Blocked Redirect Error Getting $name" 1
				fi
			else 
				echo "Download $name to `pwd`"
				echo "via url => $url"
			fi
		fi
	fi
	cd ${cdir}/depot.vmware.com/PROD/channel
}

function version() {
	echo "$0 version $VERSIONID"
	exit
}

function usage() {
	echo "$0 [--dlg search] [-d|--dryrun] [-f|--force] [--favorite] [-e|--exit] [-h|--help] [-l|--latest] [-m|--myvmware] [-mr] [-ns|--nostore] [-nc|--nocolor] [--dts|--nodts] [--oem|--nooem] [--oss|--nooss] [-p|--password password] [--progress] [-r|--reset] [-u|--username username] [-v|--vsmdir VSMDirectory] [-V|--version] [-y] [--debug] [--repo repopath] [--save]"
	echo "	--dlg - download specific package by name or part of name"
	echo "	-d|--dryrun - dryrun, do not download"
	echo "	-f|--force - force download of packages"
	echo "	--favorite - download suite marked as favorite"
	echo "	-e|--exit - reset and exit"
	echo "	-h|--help - this help"
	echo "	-l|--latest - substitute latest for each package instead of listed"
	echo "		Only really useful for latest distribution at moment"
	echo "	-m|--myvmware - get missing suite and packages from My VMware"
	echo "	-mr - reset just the My VMware information, implies -m"
	echo "	-ns|--nostore - do not store credential data and remove if exists"
	echo "	-nc|--nocolor - do not output with color"
	echo "	-p|--password - specify password"
	echo "	--progress - show progress for OEM, OSS, and DriverTools"
	echo "	-r|--reset - reset repos"
	echo "	-u|--username - specify username"
	echo "	-v|--vsmdir path - set VSM directory"
	echo "	-V|--version - version number"
	echo "	-y - do not ask to continue"
	echo "	--dts - include DriversTools in All-style downloads"
	echo "	--nodts - do not include DriversTools in All-style downloads"
	echo "	--oss - include OpenSource in All-style downloads"
	echo "	--nooss - do not include OpenSource in All-style downloads"
	echo "	--oem - include CustomIso in All-style downloads"
	echo "	--nooem - do not include CustomIso in All-style downloads"
	echo "	--debug - debug mode"
	echo "	--repo path - specify path of repo"
	echo "	--save - save settings to \$HOME/.vsmrc, favorite always saved on Mark"
	echo ""
	echo "	All-style downloads include: All, All_No_OpenSource, Minimum_Required"
	echo "	Requires packages:"
	echo "	wget python python-urllib3 libxml2 perl-XML-Twig ncurses bc"
	echo ""
	echo "To Download the latest Perl CLI use (to escape the wild cards):"
	echo "./vsm.sh --dlg CLI\.\*\\.x86_64.tar.gz"
	echo ""
	echo "Use of the Mark option, marks the current product suite as the" 
	echo "favorite. There is only 1 favorite slot available. Favorites"
	echo "can be downloaded without traversing the menus."

	exit;
}

function checkdep() {
	dep=$1
	rpm -q $dep > /dev/null
	if [ $? -eq 1 ]
	then
		echo "Missing Dependency $dep"
		needdep=1
	fi
}


# check dependencies
docolor=1
needdep=0
checkdep wget
checkdep python
checkdep python-urllib3
checkdep libxml2
checkdep perl-XML-Twig
checkdep ncurses
checkdep bc
checkdep jq

wget --help | grep -q '\--show-progress' && \
  _PROGRESS_OPT="-q --show-progress" || _PROGRESS_OPT=""

if [ $needdep -eq 1 ]
then
	colorecho "Install dependencies first!" 1
	exit
fi

#
# Default settings
dodebug=0
diddownload=0
doforce=0
dolatest=0
doreset=0
nostore=0
doexit=0
dryrun=0
dosave=0
mydts=-1
myoss=-1
myoem=-1
domenu2=0
domyvmware=0
remyvmware=0
myyes=0
myfav=0
myinnervm=0
repo="/tmp/vsm"
cdir="/tmp/vsm"
mypkg=""
mydlg=""
dodlg=0
dovex=0
# general
mchoice="root"
pver=''
name=''
data=''
rndir=''
rndll=''
likeforlike=''
like=''
err=0
# Used by myvmware
myvmware=""
domts=0
assomissing=""
missing=""
missname=""
mversions=""
midprod=1
doprogress=0
# onscreen colors
RED=`tput setaf 1`
PURPLE=`tput setaf 5`
NC=`tput sgr0`
BOLD=`tput smso`
NB=`tput rmso`
TEAL=`tput setaf 6`
mycolumns=`tput cols`

xu=`id -un`

if [ Z"$xu" = Z"root" ]
then
	colorecho "VSM cannot run as root." 1
	exit
fi

# import values from .vsmrc
if [ -e $HOME/.vsmrc ]
then
	. $HOME/.vsmrc
	# if we already use .vsmrc then continue to do so
	if [ Z"$repo" != Z"" ]
	then
		dosave=1
	fi
fi

while [[ $# -gt 0 ]]
do
	key="$1"
	case "$key" in
		-h|--help)
			usage
			;;
		-l|--latest)
			dolatest=1
			;;
		-r|--reset)
			doreset=1
			;;
		-f|--force)
			doforce=1
			;;
		-e|--exit)
			doreset=1
			doexit=1
			;;
		-y)
			myyes=1
			;;
		-u|--username)
			username=$2
			shift
			;;
		-p|--password)
			password=$2
			shift
			;;
		-ns|--nostore)
			nostore=1
			;;
		-d|--dryrun)
			dryrun=1
			;;
		-nc|--nocolor)
			docolor=0
			;;
		--repo)
			repo=$2
			shift
			;;
		--dlg)
			mydlg=$2
			dodlg=1
			shift
			;;
		--vexpertx)
			dovex=1
			;;
		-W)
			dodlg=2
			;;
		-v|--vsmdir)
			cdir=$2
			shift
			;;
		--save)
			dosave=1
			;;
		--debug)
			dodebug=1
			;;
		--dts)
			mydts=1
			;;
		--oem)
			myoem=1
			;;
		--oss)
			myoss=1
			;;
		--nodts)
			mydts=0
			;;
		--nooem)
			myoem=0
			;;
		--nooss)
			myoss=0
			;;
		-m|--myvmware)
			domyvmware=1
			;;
		-mr)
			remyvmware=1
			domyvmware=1
			;;
		--progress)
			doprogress=1
			;;
		--favorite)
			if [ Z"$favorite" != Z"" ]
			then
				myfav=1
			fi
			;;
		-V|--version)
			version
			;;
		*)
			usage
			;;
	esac
	shift
done

# remote trailing slash
repo=$(echo $repo | sed 's:/*$::')

colorecho "Using the following options:"
echo "	Version:	$VERSIONID"
if [ Z"$username" != Z"" ]
then
	echo "	Username:		$username"
	echo "	Save Credentials:	$nostore"
fi
echo "	VSM XML Dir:	$cdir"
echo "	Repo Dir:	$repo"
echo "	Dryrun:		$dryrun"
echo "	Force Download:	$doforce"
echo "	Reset XML Dir:	$doreset"
echo "	Get Latest:	$dolatest"
echo "	My VMware:	$domyvmware"
if [ $myfav -eq 1 ]
then
	echo "	Favorite: $favorite"
fi

if [ ! -e $cdir ]
then
	mkdir -p $cdir 2>/dev/null
fi

# Check Cdir
if [ ! -w $cdir ]
then
	colorecho "$cdir is not writable by ${xu}." 1
	exit
fi

# Check Repo
if [ ! -w $repo ]
then
	colorecho "$repo is not writable by ${xu}." 1
	exit
fi

rcdir="${cdir}/depot.vmware.com/PROD/channel"
cd $cdir

# if we say to no store then remove!
if [ $nostore -eq 1 ]
then
	rm .credstore
fi

if [ ! -e .credstore ]
then
	if [ Z"$username" = Z"" ]
	then
		echo -n "Enter My VMware Username: "
		read username
	fi
	if [ Z"$password" = Z"" ]
	then
		echo -n "Enter My VMware Password: "
		read -s password
	fi

	auth=`echo -n "${username}:${password}" |base64`
	if [ $nostore -eq 0 ]
	then
		# handle storing 'Basic Auth' for reuse
		echo -n $auth > .credstore
	fi
	echo "	Use credstore:	0"
else
	echo "	Use credstore:	1"
	auth=`cat .credstore`
fi

# save a copy of the .vsmrc and continue
save_vsmrc

# Get Data for VSM
if [ $myyes -eq 0 ]
then
	echo ""
	echo "Continue with VSM (Y/n)?"
	read c
	if [ Z"$c" = Z"n" ] || [ Z"$c" = Z"N" ]
	then
		exit
	fi
fi

# Cleanup old data if any
rm -f cookies.txt index.html.* 2>/dev/null

if [ ! -e depot.vmware.com/PROD/channel/root.xhtml ]
then
	doreset=1
fi

# Delete all My VMware files! So we can start new
if [ $remyvmware -eq 1 ]
then
	rm -rf ${rcdir}/_*
fi

debugecho "DEBUG: Auth request"
# Auth as VSM
wget $_PROGRESS_OPT --save-headers --cookies=on --save-cookies cookies.txt --keep-session-cookies --header='Cookie: JSESSIONID=' --header="Authorization: Basic $auth" --header='User-Agent: VMwareSoftwareManagerDownloadService/1.5.0.4237942.4237942 Windows/2012ServerR2' https://depot.vmware.com/PROD/ >& /dev/null
err=$?
wgeterror $err
if [ $err -ne 0 ]
then
	exit $err
fi

# Extract JSESSIONID
JS=`grep JSESSIONID index.html | awk -F\; '{print $1}' |awk -F= '{print $2}'`
TS=`grep vmware cookies.txt |awk '{print $5}'`
#echo $JS
echo ".vmware.com	TRUE	/	TRUE	$TS	JSESSIONID	$JS" >> cookies.txt

if [ ! -e ${cdir}/depot.vmware.com ]
then
	doreset=1
fi

if [ $doreset -eq 1 ]
then
	debugecho "DEBUG: Reset Request"
	# Get index and subsequent data
	wget $_PROGRESS_OPT -rxl 1 --load-cookies cookies.txt --header='User-Agent: VMwareSoftwareManagerDownloadService/1.5.0.4237942.4237942 Windows/2012ServerR2' https://depot.vmware.com/PROD/index.xhtml
	err=$?
	wgeterror $err
	if [ $err -ne 0 ]
	then
		exit $err
	fi
	if [ $doexit -eq 1 ]
	then
		exit 0
	fi
fi

if [ ! -e ${rcdir}/_downloads.xhtml ] || [ $doreset -eq 1 ]
then
	# Get JSON
	mywget ${rcdir}/downloads.xhtml 'https://my.vmware.com/web/vmware/downloads?p_p_id=ProductIndexPortlet_WAR_itdownloadsportlet&p_p_lifecycle=2&p_p_state=normal&p_p_mode=view&p_p_resource_id=allProducts&p_p_cacheability=cacheLevelPage&p_p_col_id=column-3&p_p_col_count=1'

	# Parse JSON
	cat ${rcdir}/downloads.xhtml | jq '.[][].proList[]|.name,.actions[]'| tr '\n' ' ' | sed 's/} {/}\n{/g' | sed 's/} "/}\n"/g' | sed 's/" {/"\n{/g' |egrep '^"|Download Product'|tr '\n' ' '|sed 's/} "/}\n"/g' > ${rcdir}/_downloads.xhtml

	if [ $err -ne 0 ]
	then
		exit $err
	fi
fi

# Present the list
cd depot.vmware.com/PROD/channel

# start of history
mlist=0
myvmware_root="https://my.vmware.com/web/vmware/info/slug"
usenurl=""
linuxvdi=""
myvmware_ref="https://my.vmware.com/group/vmware/downloads#tab1"
menu2files=0
choice="root"
name=""
href=""
drparams=""
durl=""
prevchoice=""
favorites=""
dlg=0
pkgs=""

if [ $dovex -eq 1 ]
then
	colorecho "###" 1
	colorecho "# Entering vExpert Mode" 1
	colorecho "###" 1
fi

if [ $dodlg -gt 0 ]
then
	choice="All"
	if [ $dodlg -eq 2 ]
	then
		#if [ $myyes -eq 0 ]
		#then
			echo ""
			cat << EOF

-W downloads everything! It will take a very, very long time
Are you sure you wish to do this?

EOF
			echo "Continue with VSM (Y/n)?"
			read c
			if [ Z"$c" != Z"Y" ] && [ Z"$c" != Z"y" ]
			then
				exit
			fi
			echo ""
			cat << EOF

-W downloads everything! It will take a very, very long time
Are you REALLY sure you wish to do this?

EOF
			echo "Continue with VSM (Y/n)?"
			read c
			if [ Z"$c" != Z"Y" ] && [ Z"$c" != Z"y" ]
			then
				exit
			fi
		#fi
		# find all files
		debugecho "DEBUG: mydlg => All of them"
		files="dlg_*"
	else
		debugecho "DEBUG: $mydlg"
		# Find the file
		files=`egrep -il "$mydlg" dlg_*.xhtml | sort -V | tail -1 | sed 's/.xhtml//'`
		mypkg=`echo $files | sed 's/dlg_//'`
		if [ Z"$files" = Z"" ]
		then
			colorecho "No file found!" 1
			exit
		fi
	fi

	tmp='/tmp/vsm/tt$$'
	for x in $files
	do
		x=`echo $x |sed 's/.xhtml//'`
		d=`grep -l $x *.xhtml | grep -v $x | grep -v '^_' | sort -V | tail -1 | sed 's/.xhtml//'`
		#echo -n "$d => "
		dd=`echo $d | sed 's/dlg_//'`
		if [ $dodlg -eq 1 ]
		then
			choice=$dd
		fi
		dp=""
		# prevchoice
		if [ Z"$dd" != Z"$d" ]
		then
			grep -l $dd *.xhtml | grep -v $dd | grep -v '^_' | sed 's/.xhtml//' >> $tmp
		fi
	done
	debugecho "DEBUG: DLG => Get List"
	# now we run through all the prevchoices
	favorites=`sort -uV $tmp | grep -v dlg_`
	debugecho "DEBUG: DLG => $favorites"
fi

while [ 1 ]
do
	all=""
	alln=""
	allm=""
	if [ $dlg -eq 1 ]
	then
		all="All"
		alln="All_Plus_OpenSource"
		allm="Minimum_Required"
		dlg=2
		if [ Z"$prevchoice" = Z"" ]
        	then
        		prevchoice=$choice
        	fi
	fi
	# set up overrides
	if [ $dodlg -gt 0 ]
	then
		# This overrides DTS incase it is selected!
		dlg=2
	elif [ $myfav -eq 1 ]
	then
		# setup auto-download of favorite
		if [ $domyvmware -eq 1 ]
		then
			favorites=$favorite
			mchoice=`dirname $mfchoice`
			myvmware=`dirname $myfvmware`
			mchoice=`dirname $mchoice`
			choice=`basename $mchoice`
			myvmware=`dirname $myvmware`
			getvmware #FM
			midprod=0
			choice=`basename $mfchoice`
			mchoice=`dirname $mfchoice`
			myvmware=`dirname $myfvmware`
			getvmware #OV
			mchoice=$mfchoice
			myvmware=$myfvmware
			getvmware #IV
		elif [ -e ${rcdir}/${favorite}.xhtml ]
		then
			favorites=$favorite
		fi
		if [ Z"$favorites" != Z"" ]
		then
			choice="All"
			dlg=2
		else
			myfav=0
		fi
	fi

	if [ $myfav -eq 0 ] && [ $dodlg -eq 0 ]
	then
		debugecho "Menu => $all $allm $alln"
		menu $all $allm $alln ${choice}.xhtml
		favorites=$prevchoice
	fi

	if [ $choice != "Back" ]
	then

		if [ $dlg -eq 0 ]
		then
			grep dlg_ ${choice}.xhtml >& /dev/null
			if [ $? -eq 0 ]
			then
				dlg=1
			fi
		fi
	
		if [ $dlg -eq 2 ]
		then
			for prevchoice in $favorites
			do
				debugecho "DEBUG: Prevchoice => $prevchoice"
				doall=0
				if [ $dodlg -eq 2 ]
				then
					choice="All"
				fi
				getproddata

				# if ALL then cycle through dlg in prevchoice
				#   set 'choices' array, then cycle through all $choices
				#   ensure 'selected' is in $choices so does this once
				if [ $choice = "All" ] || [ $choice = "All_Plus_OpenSource" ] || [ $choice = "Minimum_Required" ]
				then
					if [ $myinnervm -eq 0 ]
					then
						vsmpkgs ${prevchoice}.xhtml
					fi
					choices=$pkgs
					doall=1
					if [ $choice = "Minimum_Required" ]
					then
						doall=3
					fi
					if [ $choice = "All_Plus_OpenSource" ]
					then
						doall=2
					fi
				else
					choices=$choice
				fi
				
				domenu2=1
				while [ $domenu2 -eq 1 ]
				do
					for choice in $choices
					do
						debugecho "DEBUG: Working on $choice"
						stripcolor
						#echo $choice | fgrep '[' >& /dev/null
						#if [ $? -eq 0 ]
						#then
						#	debugecho "DEBUG: unable to download GRAy items"
						#	continue
						#fi
						# reset for associated packages list
						oem=""
						dt=""
						oss=""
						oemlist=""
						osslist=""
						dtslist=""
						asso=""
						assomissing=""
						wouldassomiss=0
						# get associated packages
						getasso

						if [ $wouldassomiss -eq 1 ] && [ $domyvmware -eq 1 ]
						then
							debugecho "Could get $choice from My VMware"
							# force getting My VMware bits?
						fi
			
						# reset for options
						dooem=0
						dooss=0
						dodts=0
						dodat=0
						myall=0
						mychoice=""
						currchoice=$choice;
						menu2files=0;
			
						# do not show if ALL, choice set above!
						if [ $doall -eq 0 ] && [ $dodlg -eq 0 ]
						then
							menu2 dlg_${choice}.xhtml $oss $oem $dts
							# menu2 requires doall be set
							#if [ Z"$choice" = Z"All" ]
							#then
							#	doall=1
							#fi
						else
							# if we do not show menu, we may still
							# require myvmware data
							vmwaremenu2
						fi
			
						case $choice in
							"All")
								dooem=1
								dodts=1
								dodat=1
								myall=1
								;;
							"Minimum_Required")
								dodat=1
								myall=1
								;;
							"All_Plus_OpenSource")
								dooss=1
								dooem=1
								dodts=1
								dodat=1
								myall=1
								;;
							"CustomIso")
								dooem=1
								;;
							"OpenSource")
								dooss=1
								;;
							"DriversTools")
								dodts=1
								;;
							"Back")
								domenu2=0
								dlg=1
								;;
							*)
								mychoice=$choice
								dodat=1
								;;
						esac
						if [ $doall -eq 1 ]
						then
							dooss=0
							dooem=1
							dodts=1
							dodat=1
							myall=1
							domenu2=0
						fi
						if [ $doall -eq 2 ]
						then
							dooss=1
							dooem=1
							dodts=1
							dodat=1
							myall=1
							domenu2=0
						fi
						if [ $doall -eq 3 ]
						then
							dooss=0
							dooem=0
							dodts=0
							dodat=1
							myall=1
							domenu2=0
						fi
						if [ $dodlg -eq 1 ]
						then
							dooss=0
							dooem=1
							dodts=1
							dodat=1
						fi
						if [ $doall -ne 0 ] || [ $myall -eq 1 ]
						then
							if [ $myoem -ne -1 ]
							then
								dooem=$myoem
							fi
							if [ $myoss -ne -1 ]
							then
								dooss=$myoss
							fi
							if [ $mydts -ne -1 ]
							then
								dodts=$mydts
							fi
						fi
						debugecho "DEBUG: $mychoice $dodat $dooem $dooss $dots"
			
						# do the regular including All/All_Plus_OpenSource
						if [ $dodat -eq 1 ]
						then
							err=0
							# do something with menu2files
							getvsmcnt $currchoice
							cnt=$?
							debugecho "DEBUG: detected $cnt $mychoice => $mypkg"
							x=1
							xignore=0
							if [ $dodlg -eq 1 ] && [ Z"$mypkg" != Z"$currchoice" ]
							then
								xignore=1
								x=$cnt
							fi
							while [ $x -le $cnt ]
							do
								getvsmdata $currchoice $x
								# only do the selected
								doit=0
								if [ $dodlg -eq 1 ]
								then
									#debugecho "DEBUG: DoDlg"
									d=`echo $name | sed "s/$mydlg//i"`
									if [ Z"$d" != Z"$name" ]
									then
										doit=1
									fi
								elif [ $myall -eq 0 ]
								then
									#debugecho "DEBUG: MyChoice"
									if [ Z"$name" = Z"$mychoice" ]
									then
										# got it so strip
										#getpath
										doit=1
									fi
								else
									#debugecho "DEBUG: DoIt"
									doit=1
								fi
								#debugecho "DEBUG: $doit"
								if [ $doit -eq 1 ]
								then
									if [ $dodlg -eq 1 ]
									then
										echo "Local:$repo/dlg_$currchoice/$name"
									fi
									debugecho "DEBUG: Getting $name"
									getvsm $currchoice "base"
								fi
								# out to dev null seems to be required
								$((x++)) 2> /dev/null
							done
							if [ $xignore -eq 0 ]
							then
								if [ $diddownload -eq 1 ]
								then
									colorecho "Downloads to $repo/dlg_$currchoice"
								else
									if [ $err -eq 0 ]
									then
										colorecho "All $currchoice already downloaded!"
									fi
								fi
							fi
						fi
			
						# Now handle OpenSource, CustomIso, DriversTools
						# these are via $asso
						for x in oem dts oss
						do
							err=0
							y="do${x}"
							l="${x}list"
							eval dom=\$$y
							eval om=\$${x}
							eval omlist=\$${l}
							if [ $dom -eq 1 ] && [ Z"$om" != Z"" ]
							then
								debugecho "DEBUG: $y"
								diddownload=0
								xignore=-1
								for o in `echo $omlist| sed 's/dlg_//g' |sed 's/\.xhtml//g'`
								do
									domts=0
									pkgs=""
									o=`echo $o|sed 's/^_//'`
									echo "$assomissing "| egrep "$o " >& /dev/null
									if [ $? -eq 0 ]
									then
										vmwaremenu2 $o
									else
										if [ -e _dlg_${o}.xhtml ]
										then
											domts=1
										fi
									fi
									if [ $doprogress -eq 1 ]
									then
										echo -n "."
									fi
									debugecho "DEBUG $y: $choice: $o => $mypkg"
									getvsmcnt $o
									cnt=$?
									x=1
									if [ $dodlg -eq 1 ] && [ Z"$mypkg" != Z"$o" ]
									then
										if [ $xignore -ne 0 ]
										then
											xignore=1
										fi
										x=$cnt
									fi
									while [ $x -le $cnt ]
									do
										getvsmdata $o $x
										doit=0
										if [ $dodlg -eq 1 ]
										then
											d=`echo $name | sed "s/$mydlg//i"`
											if [ Z"$d" != Z"$name" ]
											then
												doit=1
											fi
										else
											doit=1
										fi
										if [ $doit -eq 1 ]
										then
											# only do the selected
											xignore=0
											if [ $dodlg -eq 1 ]
											then
												echo "Local:$repo/dlg_$currchoice/$om/$name"
											fi
											getvsm $currchoice $om $o
											# out to dev null seems to be required
										fi
										let x=$x+1
									done
								done
								if [ $doprogress -eq 1 ]
								then
									echo "!"
								fi
								if [ $xignore -eq 0 ]
								then
									if [ $dodlg -eq 1 ]
									then
										mypkg=" $mypkg"
									fi
									if [ $diddownload -eq 1 ]
									then
										colorecho "Downloads $mypkg to $repo/dlg_$currchoice/$om"
									else
										if [ $err -eq 0 ]
										then
											colorecho "All $currchoice$mypkg $om already downloaded!"
										fi
									fi
								fi
							fi
							domts=0
						done
						
						diddownload=0
						#choice=$prevchoice
					done
					getpath
					getchoice
				done # domenu2
			done
			doall=0
			echo ""
			if [ $myfav -eq 1 ] || [ $dodlg -gt 0 ]
			then
				exit
			fi
		fi
	else
		# go back 2 entries as previous is current
		backvmware
		getpath
		getchoice
		if [ $domenu2 -eq 1 ]
		then
			domenu2=0
			doall=0
			dlg=1
		else
			dlg=0
		fi

		if [ $dlg -eq 2 ] 
		then
			dlg=1
			#choice=$prevchoice
		fi
		prevchoice=""
		asso=""
	fi
done
