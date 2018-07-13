#!/bin/bash
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

VERSIONID="4.7.5"

# args: stmt error
function colorecho() {
	COLOR=$PURPLE
	if [ Z"$2" = Z"1" ]
	then
		COLOR=$RED
	fi
	if [ $debugv -ne 2 ]
	then
		if [ $docolor -eq 1 ]
		then
			echo "${COLOR}${1}${NC}"
		else
			echo ${1}
		fi
	fi
}
function debugecho() {
	if [ $dodebug -eq 1 ]
	then
		echo ${1}
	fi
}
function shaecho() {
	if [ $doshacheck -eq 1 ] && [ Z"$shafail" != Z"" ]
	then
		colorecho "Following $sha Check Sums Failed
	${shafail}" 1
	elif [ $doshacheck -eq 1 ] && [ $shadownload -eq 1 ]
	then
		colorecho "All $sha Check Sums Passed"
	fi
	shadownload=0
	shafail=''
}

function getvdat() {
	vdat=`pwd`/vsm.data
	if [ ! -e $vdat ]
	then
		vdat=$cdir/vsm.data
		mywget $vdat https://raw.githubusercontent.com/Texiwill/aac-lib/master/vsm/vsm.data >& /dev/null
		if [ $err -ne 0 ]
		then
			rm -rf $vdat
		fi
	fi
	if [ ! -e $vdat ]
	then
		colorecho "VSM cannot run without its data file." 1
		exit
	fi
}

findfavpaths()
{
	pchoice=$1
	# find paths
	vc=`echo $pchoice | sed 's/[a-Z_]\+\([0-9]_[0-9]\|[0-9]\+\).*/\1/'`
	tc=`echo $pchoice | tr '[:upper:]' '[:lower:]'|sed 's/\([0-9]\)_\([a-z_]\+\)/\1 \2/'|sed 's/_/./g'`
	dc=`echo $tc | cut -d' ' -f1`
	dc="${dc%?}?"
	ec=`echo $tc | cut -d' ' -f2 | sed 's/\./_/g'`
	# rebuild myvmware path
	fv=`egrep "$dc" ${rcdir}/_downloads.xhtml | sort -V | tail -1`
	dvc=''
	if [ ${#fv} -eq 0 ]
	then
		debugecho "DC: Finding Alternative"
		dvc=`echo $vc | sed 's/_/./g'`
		dc=`echo $tc | cut -d' ' -f1 | sed "s/\.$dvc//"`
		ec=`echo $tc | cut -d' ' -f2 | sed 's/\./_/g'`
		# rebuild myvmware path
		fv=`egrep "$dc" ${rcdir}/_downloads.xhtml | sort -V | tail -1`
		if [ ${#fv} -eq 0 ]
		then
			debugecho "dc => $dc"
			colorecho "No Downloads Reference Found for $mydlg" 1
			rm -f ${cdir}/$vpat
			exit
		fi
	fi
	mfchoice='root'
	myfm=`echo $fv | cut -d\" -f14 | sed 's#./info/slug##'`
	vf=`dirname $myfm`
	myfm="$vf/$vc"
	myfvmware="${myfm}/${ec}"
	tf=`echo $fv | cut -d\" -f2 | sed 's/ /_/g'`
	# rebuild mchoice path
	li=`xml_grep --text_only '//*/a' ${rcdir}/root.xhtml`
	for x in $li Infrastructure_Operations_Management Desktop_End_User_Computing Networking_Security
	do
		t=`echo $pchoice | sed "s#${x}_##"`
		#echo "$x => $t"
		if [ Z"$t" != Z"${pchoice}" ]
		then
			mfchoice="$mfchoice/${x}/${x}_${tf}"
			t=`echo $pchoice | sed "s#${x}_${tf}##" | tr '[:upper:]' '[:lower:]'|sed "s/_$ec//g"|sed 's/^_//'`
			mfchoice="$mfchoice/${x}_${tf}_${t}/$pchoice"
			break
		fi
	done
}

progressfilt ()
{
	local flag=false c count cr=$'\r' nl=$'\n'
	if [ Z"$_PROGRESS_OPT" != Z"" ]
	then
		flag=true
	fi
	while IFS='' read -d '' -rn 1 c
	do
		if $flag
		then
			printf '%c' "$c" | tr '\342\200\230\231' ' '
		else
			if [[ $c != $cr && $c != $nl ]]
			then
				count=0
			else
				((count++))
				if ((count > 1))
				then
					flag=true
				fi
			fi
		fi
	done
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
	err=0
	wgprogress=$doprogress
	if [ Z"$1" != Z" " ]
	then
		ou="-nd -O $1"
	fi
	if [ Z"$4" != Z"" ]
	then
		wgprogress=$4
	else
		if [ $doquiet -eq 1 ]
		then
			wgprogress=0
		fi
	fi
	if [ Z"$1" = "-" ]
	then
		# getting pre-url
		lurl=`wget --max-redirect 0 --load-cookies $cdir/cookies.txt --header='User-Agent: VMwareSoftwareManagerDownloadService/1.5.0.4237942.4237942 Windows/2012ServerR2' -O - $hr 2>&1 | grep Location | awk '{print $2}'`
		err=${PIPESTATUS[0]}
	else
		debugecho "doquiet => $doquiet : $doprogress : $indomenu2 : $wgprogress"
		if [ $doquiet -eq 1 ]
		then
			if [ $doprogress -eq 1 ] && [ $indomenu2 -eq 1 ]
			then
				echo -n "+"
			fi
			if [ $wgprogress -eq 1 ]
			then
				wget $_PROGRESS_OPT --progress=bar:force $hd --load-cookies $cdir/cookies.txt --header='User-Agent: VMwareSoftwareManagerDownloadService/1.5.0.4237942.4237942 Windows/2012ServerR2' $ou $hr 2>&1 | progressfilt 
				err=${PIPESTATUS[0]}
			else
				wget $_PROGRESS_OPT $hd --load-cookies $cdir/cookies.txt --header='User-Agent: VMwareSoftwareManagerDownloadService/1.5.0.4237942.4237942 Windows/2012ServerR2' $ou $hr >& /dev/null
				err=${PIPESTATUS[0]}
			fi
			if [ $doprogress -eq 1 ] && [ $indomenu2 -eq 1 ]
			then
				echo -n "+"
			fi
		else
			wget $_PROGRESS_OPT $hd --progress=bar:force --load-cookies $cdir/cookies.txt --header='User-Agent: VMwareSoftwareManagerDownloadService/1.5.0.4237942.4237942 Windows/2012ServerR2' $ou $hr # 2>&1 | progressfilt
			err=${PIPESTATUS[0]}
		fi
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
					myname=`egrep "${myvmware}[/\"]" ${rcdir}/_downloads.xhtml | cut -d\" -f 2|sed 's/Software-Defined/Software_Defined/'`
					myver=`egrep "${myvmware}[/\"]" ${rcdir}/_downloads.xhtml | cut -d\" -f 14`
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
				echo $missname | grep vmware_vrealize_network_insight >& /dev/null
				pli=$?
				if [ $nbeta1 -eq 1 ] && [ $pli -eq 1 ]
				then
					tver=`grep $myvmware ${rcdir}/${missname}.xhtml |awk '{print $2}' | awk -F\" '{print $2}' | sed 's#/web/vmware/info/slug##g' | sed "s#${myvmware}/##g" |egrep -v hidden | sort -u` 
				else
					if [ Z"$pmiss" != Z"" ]
					then
						tver=`grep $myvmware ${rcdir}/${missname}.xhtml |awk '{print $2}' | awk -F\" '{print $2}' | sed 's#/web/vmware/info/slug##g' | sed "s#${myvmware}/##g"|egrep -v $pmiss |egrep -v hidden | sort -u`
					elif [ $nbeta1 -ne 1 ]
					then
						tver=`grep $myvmware ${rcdir}/${missname}.xhtml |awk '{print $2}' | awk -F\" '{print $2}' | sed 's#/web/vmware/info/slug##g' | sed "s#${myvmware}/##g" |egrep -v hidden | sort -u` 
					fi
				fi
			fi
			# missing pkg entries
			if [ Z"$tver" = Z"" ]
			then
				if [ Z"$usenurl" = Z"" ]
				then
					if [ Z"$myusenurl" = Z"" ]
					then
						usenurl=`grep "Go to Downloads" ${rcdir}/${missname}.xhtml | sed 's/href=/\nhref=/g' | grep href | grep -v OSS | cut -d\" -f 2 | head -1`
					else
						usenurl=$myusenurl
					fi
				fi
				#debugecho "N: $usenurl"
				if [ ! -e ${rcdir}/${missname}_1.xhtml ] || [ $doreset -eq 1 ]
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
		if [ $nbeta1 -eq 1 ]
		then
			mversions=`xmllint --html --xpath "//tr[@class=\"clickable\"]" $rcdir/${missname}.xhtml 2>/dev/null | tr '\r\n' ' '|sed 's/[[:space:]]/+/g'| sed 's/<\/tr>/\n/g' |grep -v buttoncol | sed 's/[<>]/ /g' | awk '{print $11}'| sed 's/+/_/g' | sed 's/\&amp;/\&/g'`
		else
			mversions=`xmllint --html --xpath "//tr[@class=\"clickable\"]" $rcdir/${missname}.xhtml 2>/dev/null | tr '\r\n' ' '|sed 's/[[:space:]]/+/g'| sed 's/<\/tr>/\n/g' |grep -v buttoncol | sed 's/[<>]/ /g' | awk '{print $11}'| sed 's/+/_/g'`
		fi
		#mc=`echo $mversions | wc -w`
		#debugecho "mc => $mc"
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
					usenurl=`grep "Go to Downloads" ${rcdir}/${missname}.xhtml | grep -v OSS | cut -d\" -f 4 | head -1`
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
		# not a good test :(
		if [ Z"$ver" != Z"$choice" ]
		then
		#	if [ ${#ver} -lt 3 ]
		#	then
				gld=`echo $usenurl | cut -d= -f 2 |cut -d\& -f1|sed 's/-/_/g'`
				pld=`echo $gld | sed 's/\([A-Z]\+\)_[0-9]\+/\1/'`
				gver=`echo $gld | sed 's/.*_\([0-9]\+\)$/\1/'`
				# Need to substitute versions if necessary
				# This may catch appropriate items
				debugecho "PLD => $pld"
				if [ Z"$gver" != Z"$ver" ] && [ Z"$pld" = Z"VRNI" ]
				then
					gld=`echo $gld | sed "s/$gver/$ver/"`
					usenurl=`echo $usenurl | sed "s/$gver/$ver/"`
				fi
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
			if [ ! -e ${rcdir}/${missname}.xhtml ] || [ $doreset -eq 1 ]
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
		debugecho "what => $what wend => $wend mv => $mv"
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

function vmwarecv() {
	debugecho "CV: $choice $missname $mversions"
	prodlist=`grep downloadGroupId $rcdir/_dlg_${choice}.xhtml | cut -d\" -f6`
	if [ Z"$prodlist" != Z"" ]
	then
		npkg=""
		for x in $prodlist
		do
			# dirs use _ not -
			y=`echo $x|sed 's/-/_/g'`
			if [ ! -e "${repo}/dlg_${y}" ]
			then
				if [ Z"$npkg" = Z"" ]
				then
					npkg="${BOLD}${TEAL}${x}${NB}${NC}"	
				else
					npkg="$npkg ${BOLD}${TEAL}${x}${NB}${NC}"
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
		debugecho "CV: $choice $missname $mversions"
		# Select a different $ach by new $vurl
		export COLUMNS=10
		select choice in $npkg Back Exit
		do
			if [ Z"$choice" != Z"" ]
			then
				stripcolor
				if [ $choice = "Exit" ]
				then
					rm -f ${cdir}/$vpat
					exit
				fi
				break
			else
				echo -n "Please enter a valid numeric number:"
			fi
		done
		if [ Z"$choice" != Z"Back" ]
		then
			# reset as we may have some old ones hanging about
			pkgs=''
			vurl="/web/vmware/details?productId=${productId}&rPId=${rPId}&downloadGroup=${choice}"
			choice=`echo $choice |sed 's/-/_/g'`
			vmwaremi $choice $vurl
			# reset currchoice as well
			currchoice=$choice
			# reset asso's as well
			oemlist=''
			dtslist=''
			osslist=''
			getasso
			# reset path for 'back' to work
			getpath
			addpath
		fi
	fi
}

function vmwaremi()
{
	ich=$1
	iurl=$2
	debugecho "DEBUG: $ich vurl => $vurl"
	if [ ! -e ${rcdir}/_dlg_${ich}.xhtml ] || [ $doreset -eq 1 ]
	then
		if [ Z"$iurl" != Z"" ]
		then
			mywget ${rcdir}/_dlg_${ich}.xhtml "https://my.vmware.com${iurl}"
		fi
	fi

	# parse data
	menu2files=1
	getvsmcnt $ich
	cnt=$?
	debugecho "DEBUG: menu2files => $menu2files"
	x=1
	while [ $x -le $cnt ]
	do
		getvsmdata $ich $x
		if [ Z"$pkgs" = Z"" ]
		then
			pkgs=$name
		else
			pkgs="$pkgs $name"
		fi
		$((x++)) 2> /dev/null
	done
	getouterrndir $ich
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
	if [ $domyvmware -eq 1 ] #&& [ ! -e ${rcdir}/dlg_${ach}.xhtml ]
	then
		pkgs=''
		vsme=`echo $ach | sed 's/_/[-_]/g'`
		debugecho "DEBUG: vsme => $vsme"
		# will not work for dooss so need to know we are doing this
		vurl=`egrep "$vsme" ${rcdir}/${mname}.xhtml 2>/dev/null |grep -v OSS | head -1 | sed 's/<a href/\n<a href/' | grep href | cut -d \" -f 2 | sed 's#https://my\.vmware\.com##'`
		debugecho "DEBUG: vurl => $vurl"
		if [ $historical -eq 1 ]
		then
			# ordering problem, so put here
			rPId=`echo $vurl  | cut -d\& -f3 | cut -d= -f2`
			productId=`echo $vurl  | cut -d\& -f2 | cut -d= -f2`
			if [ Z"$rPId" = Z"#x2f;" ]
			then
				# first convert
				vurl=`echo $vurl | sed 's/&#x3a;/:/g' | sed 's/&#x2f;/\//g' | sed 's/&#x2e;/./g' | sed 's/&#x3f;/?/'|sed 's/&#x3d;/=/g'|sed 's/&#x26;/\&/g'`
				vurl=`echo $vurl | sed "s/$ach/$vsme/"`
				rPId=`echo $vurl  | cut -d\& -f3 | cut -d= -f2`
				productId=`echo $vurl  | cut -d\& -f2 | cut -d= -f2`
			fi
			vmwaremi $ach $vurl
		else
			if [ ! -e ${rcdir}/_dlg_${ach}.xhtml ] || [ $doreset -eq 1 ]
			then
				if [ Z"$vurl" != Z"" ]
				then
					mywget ${rcdir}/_dlg_${ach}.xhtml "https://my.vmware.com${vurl}"
				fi
			fi

			# parse data
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
	fi
}

function getvsmcnt() {
	cchoice=$1
	if [ $menu2files -eq 0 ] || [ $domts -eq 1 ]
	then
		cnt=`xml_grep --html --pretty_print --cond '//*/[@class="depot-content"]' $rcdir/dlg_${cchoice}.xhtml 2>/dev/null  |grep display-order | wc -l`
	else
		cnt=`xmllint --html --xpath "//td[@class=\"filename\"]" ${rcdir}/_dlg_${cchoice}.xhtml 2> /dev/null | grep fileNameHolder | wc -l`
	fi
	debugecho "DEBUG: getvsmcnt => $cnt"
	#let cnt=$cnt+1
	return $cnt
}

function getproddata() {
	if [ $myinnervm -eq 1 ]
	then
		prod=`grep '<title>' $rcdir/${missname}.xhtml|cut -d '>' -f 2|cut -d '<' -f 1 | sed 's/Download //' | sed 's/ [0-9]\+$//'`
		vers=`grep selected $rcdir/${missname}.xhtml | awk -F\> '{print $2}'|awk -F\< '{print $1}' | sed 's/[[:space:]]\+$//'|sed 's/ /+/g'`
		#dref=`grep downloadFilesURL $rcdir/${missname}.xhtml|sed 's/value=/\n/'|grep https|cut -d\" -f2`
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
	ornlin=`uudecode $vdat | openssl enc -aes-256-ctr -d -a -salt -pass file:${cdir}/$vpat -md md5 2>/dev/null | grep "$lchoice|" |sort -V|tail -1`
 	orndir=`echo $ornlin | cut -d\| -f 2`
 	orndll="`echo $ornlin | cut -d\| -f 3`.vmware.com"
	if [ Z"$orndir" = Z"" ]
	then
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
			VCOPS*)
				rndir='vcops'
				;;
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
			VROVA*)
				rndir="vi"
				;;
			VDP*)
				rndir="vdp/${v:0:2}"
				;;
			APPHA*)
				rndir="APPHA_${v}"
				if [ $v -lt 111 ]
				then
					rndir="vin/570"
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
			NSX_V*)
				rndir="nsx-V-610"
				;;
			VSPP_VCD*)
				rndir="vcd"
				;;
			CX*)
				rndir="vcandr"
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
			VROPS*)
				m="${lchoice//[^[:digit:]]/}"
				rndir="vrops${m}"
				;;
			VC55*)
				rndir="vi/55"
				;;
			VC65*)
				n=`echo $lchoice | sed 's/VC[0-9][0-9]//' | tr [:upper:] [:lower:]`
				m=`echo $lchoice | sed 's/VC//' | sed "s/$n//i"`
				rndir="vc/$m/$n"
				;;
			VC67*)
				rndir="vc/67"
				;;
			VC60*)
				rndir="vi/60"
				;;
			VC*)
				rndir="vi"
				;;
			HCS*)
				rndir="AppVolumes"
				;;
			VR[0123456789]*)
				rndir="vr50"
				;;
			ZONES10*)
				rndir="vi"
				;;
			SRM_SRA81*)
				rndir="srm810"
				;;
			SRM*)
				rndir="srm50"
				;;
			ESXI*)
				if [ $v -lt 60 ]
				then
					rndir="esx/${v:0:2}"
				else
					rndir="vi/${v:0:2}"
				fi
				;;
			OEM*)
				rndir="vi"
				;;
			DT*)
				rndll="download3.vmware.com"
				;;
			VIC*)
				m="${lchoice//[^[:digit:]]/}"
				m=`echo $m | sed -e 's/\(.\)/\1\./g' |sed 's/\.$//'`
				rndir="vic${m}"
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
			VIDM*)
				rndir="VIDM_ONPREM_${v:0:2}"
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
			VRNI*)
				rndir="vrni"
				;;
			VRLI*)
				if [ $v -eq 450 ]
				then
					rndir='strata1'
				else
					rndir='strata'
				fi
				;;
			UAG*)
				if [ $v -eq 300 ]
				then
					rndir="view"
				elif [ $v -eq 0 ] || [ $v -lt 321 ]
				then
					rndir="UAG_${v:0:2}"
				else
					rndir="UAG_${v}"
				fi
				;;
			*"OSS")
				rndir="opensource"
				;;
		esac
	fi
	debugecho "orndir => $orndir"
	debugecho "orndll => $orndll"
}

function getinnerrndir() {
	if [ $domyvmware -eq 1 ]
	then
		if [ Z"$orndir" = Z"" ]
		then
			#lchoice=$1
			#dnlike="$lchoice"
			# sometimes name is not in the same directory! 
			# So go for most recent versions location
			#ename=`echo $name | sed 's/\./\\./g'| sed 's/\[/./g' |sed 's/\]/./g'`
			#debugecho "DEBUG: ename => $ename"
			rnlin=`uudecode $vdat | openssl enc -aes-256-ctr -d -a -salt -pass file:${cdir}/$vpat -md md5 2>/dev/null| fgrep $name | sort -k6 -V|tail -1`
			if [ ${#rnlin} -ne 0 ]
			then
				rndir=`echo $rnlin| cut -d' ' -f 5`
				rndll="`echo $rnlin| cut -d' ' -f 4`.vmware.com"
			fi
			if [ Z"$rndir" = Z"" ]
			then
				if [ -e _dlg_${lchoice}.xhtml ]
				then
					rndir=`grep "Release Notes" _dlg_${lchoice}.xhtml| cut -d\" -f2| cut -d/ -f6,7`
				fi
			fi
		else
			rndir=$orndir
			rndll=$orndll
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
		data=`xmllint --html --xpath "(//*/li[@class=\"depot-content\"])[$xx]" dlg_${cchoice}.xhtml 2>/dev/null`
		name=`echo $data|xml_grep --html --text_only '//*/a' 2>/dev/null`
	else
		pver=`grep selected=\"selected\" _dlg_${cchoice}.xhtml 2> /dev/null | head -1 | cut -d\" -f2 | sed 's/[[:space:]]\+$//'| sed 's/ /+/g'`
		if [ ${PIPESTATUS[0]} -ne 0 ]
		then
			pver=`xmllint --html --xpath "//tr" _dlg_${cchoice}.xhtml  2> /dev/null  | tr '\n' ' ' |sed 's/<\/tr>/<\/tr>\n/' |head -1 |sed 's/<t[hd]>//g' |sed 's/<\/t[hd]>//g' |awk '{print $3}'| sed 's/[[:space:]]\+$//'| sed 's/ /+/g'`
		fi
		if [ Z"$pver" = Z"" ]
		then
			pver=$vers
		fi
		data=`xmllint --html --xpath "(//td[@class=\"filename\"])[$xx]" _dlg_${cchoice}.xhtml 2> /dev/null`
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
	sc=$choice
	if [ $# -eq 1 ]
	then
		# this overrides all defaults
		sc=$1
		oemlist=''
		dtslist=''
		osslist=''
	else
		if [ $domyvmware -eq 1 ] #&& [ ! -e dlg_${choice}.xhtml ]
		then
			vmwaremenu2
		fi
	fi
	if [ -e _dlg_${sc}.xhtml ]
	then
		assomiss=1
		# Get ASSO from my vmware bits
		asso=`xmllint --html --xpath "//div[@class=\"activitiesLog\"]" _dlg_${sc}.xhtml 2>/dev/null |grep secondary | cut -d= -f3 | cut -d\& -f 1 | sed 's/-/_/g'`
		moreasso="_dlg"
	elif [ -e dlg_${sc}.xhtml ]
	then
		asso=`xml_grep --html --text_only '*[@title="associated-channels"]' dlg_${sc}.xhtml  2>/dev/null| sed 's/,//g'|sed 's/dlg_//g'`
		moreasso="dlg"
	fi
	debugecho "DEBUG: moreasso => $moreasso"
	if [ Z"$moreasso" != Z"" ]
	then
		# sometimes things exist that are not in asso lists
		# sometimes they use similar version numbers
		rchoice=`echo $sc | sed 's/U/*U/'` 
		for x in `ls ${moreasso}*${rchoice}_*.xhtml 2>/dev/null | grep -v ${moreasso}_${sc}.xhtml | grep -v VCENTER`
		do
			y=`echo $x | sed 's/\.xhtml//'|sed "s/${moreasso}_//"`
			# only list all asso if dodlg != 1
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
		if [ $dodlg -eq 1 ] && [ Z"$x" != Z"$mypkg" ]
		then
			continue
		fi
		# debugecho "$sc: $x"
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
	debugecho "DEBUG: $sc => $mypkg"
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
			#if [ -e dlg_${x}.xhtml ] && [ -d ${repo}/dlg_${xy} ]
			#then
			#	a=$x
			#elif [ -e dlg_${x}.xhtml ] && [ ! -d ${repo}/dlg_${xy} ]
			#then
			#	a="${BOLD}${x}${NC}"
			if [ $dodlg -eq 1 ] && [ Z"$choice" != Z"$xy" ]
			then
				continue
			fi
			a=${xy}
			if [ ! -e _dlg_${xy}.xhtml ] && [ -d "${repo}/dlg_${xy}" ]
			then
				a="${TEAL}${x}${NC}"
			elif [ ! -d ${repo}/dlg_${xy} ]
			then
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
		pkgs=`echo $pkgs|xargs -n1 | sort | xargs`
	elif [ $choice = "Networking_Security" ]
	then
		pkgs="Networking_Security_VMware_NSX_Data_Center_for_vSphere Networking_Security_VMware_NSX_T_Data_Center"
	else
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
			pkgs="$pkgs Datacenter_Cloud_Infrastructure_VMware_Validated_Design_for_Software_Defined_Data_Center Datacenter_Cloud_Infrastructure_VMware_vCloud_Suite Datacenter_Cloud_Infrastructure_VMware_vSphere_with_Operations_Management"
			if [ $dovex -eq 1 ]
			then
				pkgs="$pkgs Datacenter_Cloud_Infrastructure_VMware_vCloud_Director"
			fi
			pkgs=`echo $pkgs|xargs -n1 | sort | xargs`
			mversions=''
		elif [ $choice = "Infrastructure_Operations_Management" ]
		then
			pkgs="Infrastructure_Operations_Management_VMware_vRealize_Automation Infrastructure_Operations_Management_VMware_vRealize_Network_Insight Infrastructure_Operations_Management_VMware_vRealize_Suite"
			if [ $dovex -eq 1 ]
			then
				pkgs="$pkgs Infrastructure_Operations_Management_VMware_Integrated_OpenStack Infrastructure_Operations_Management_VMware_Site_Recovery_Manager"
				# Infrastructure_Operations_Management_VMware_vRealize_Operations"
				# Infrastructure_Operations_Management_VMware_vRealize_Configuration_Manager
				pkgs=`echo $pkgs|xargs -n1 | sort | xargs`
			fi
			mversions=''
		fi
	fi
	debugecho "DEBUG vsmpkgs: $pkgs"
}

function load_vsmrc() {
	if [ -e $HOME/.vsmrc ]
	then
		vsmrc="$HOME/.vsmrc"
		. $HOME/.vsmrc
	elif [ -e "$repo/.vsmrc" ]
	then
		vsmrc="$repo/.vsmrc"
		. $repo/.vsmrc
	elif [ -e "$cdir/.vsmrc" ]
	then
		vsmrc="$cdir/.vsmrc"
		. $cdir/.vsmrc
	else
		# nothing there default
		vsmrc="$HOME/.vsmrc"
	fi
	# if we already use .vsmrc then continue to do so
	if [ Z"$repo" != Z"" ]
	then
		dosave=1
	fi
}

function save_vsmrc() {
	if [ Z"$vsmrc" != Z"" ]
	then
		if [ $noheader -eq 0 ]
		then
			colorecho "Saving to $vsmrc"
		fi
		echo -n '' > $vsmrc
		if [ $domyvmware -eq 1 ] && [ Z"$mchoice" != Z"" ]
		then
			if [ ! -e ${rcdir}/${favorite}.xhtml ]
			then
				favorite=${favorite}
			fi
		fi
		if [ Z"$mchoice" = Z"root" ]
		then
			echo "mfchoice='$mfchoice'" >> $vsmrc
			echo "myfvmware='$myfvmware'" >> $vsmrc
		else
			echo "mfchoice='$mchoice'" >> $vsmrc
			echo "myfvmware='$myvmware'" >> $vsmrc
		fi
		echo "favorite='$favorite'" >> $vsmrc
		if [ $dosave -eq 1 ]
		then
			echo "repo='$repo'" >> $vsmrc
			echo "cdir='$cdir'" >> $vsmrc
			echo "myoem=$myoem" >> $vsmrc
			echo "mydts=$mydts" >> $vsmrc
			echo "myoss=$myoss" >> $vsmrc
			echo "myquiet=$doquiet" >> $vsmrc
			echo "myprogress=$doprogress" >> $vsmrc
			echo "doshacheck=$doshacheck" >> $vsmrc
			echo "dovex=$dovex" >> $vsmrc
			echo "historical=$historical" >> $vsmrc
			echo "compress=$compress" >> $vsmrc
			echo "symlink=$symlink" >> $vsmrc
			echo "domyvmware=$domyvmware" >> $vsmrc
		fi
	fi
}

function stripcolor() {
	sc=$choice
	if [ $# -eq 1 ]
	then
		sc=$1
	fi
	debugecho "SC: $sc"
	echo $sc | fgrep '[' >& /dev/null
	if [ $? -eq 0 ]
	then
		choice=`echo $sc | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g" | sed -r "s/\x1B\(B//g"|sed -r "s/[[:cntrl:]]//g"`
	fi
	debugecho "SC: $sc"
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
		doprogress=0
		vsmpkgs $file
		if [ Z"$choice" = Z"root" ] && [ $domyvmware -eq 1 ] 
		then
			echo $pkgs |grep Infrastructure_Operations_Management >& /dev/null
			if [ $? -eq 1 ]
			then
				pkgs="$pkgs Infrastructure_Operations_Management"
			fi
			if [ $dovex -eq 1 ]
			then
				pkgs="$pkgs Desktop_End_User_Computing Networking_Security"
			fi
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
	if [ $nbeta1 -eq 1 ]
	then
		domyvm=`echo ${myvmware}| awk -F/ '{print NF}'`
		if [ $domyvm -eq 3 ]
		then
			pkgs=`echo $pkgs | sed 's/[ $]/\n/g' |sort -uVr | tr '\n' ' '| sed 's/ $//'`
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
				rm -f ${cdir}/$vpat
				exit
			fi
			if [ $choice = "Mark" ]
			then
				favorite=$prevchoice
				colorecho "Favorite: $favorite"
				save_vsmrc
			else
				# not for root or next layer
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
	if [ $myprogress -eq 1 ] && [ $dodebug -eq 0 ]
	then
		doprogress=1
	fi
}

function menu2() {
	mval=$1
	all=""
	#doprogress=0
	debugecho "MENU2: $mval"
	if [ Z"$2" = Z"OpenSource" ]
	then
		all="All_Plus_OpenSource"
	fi
	#if [ -e $1 ]
	#then
	#	pkgs=`xml_grep --text_only '//*/a' $1 2>/dev/null`
	#else
		vmwaremenu2
		# Put find 'sub-versions' of releases
		if [ $historical -eq 1 ]
		then
			vmwarecv
			mval="_dlg_${choice}.xhtml"
		fi
	#fi
	if [ $choice != "Back" ]
	then
		npkg=""
		f=`echo $mval |sed 's/\.xhtml//' | sed 's/-/_/g' | sed 's/^_//'`
		for x in $pkgs
		do
			if [ ! -e "${repo}/${f}/${x}" ] && [ ! -e "${repo}/${f}/${x}.gz" ]
			then
				if [ Z"$npkg" = Z"" ]
				then
					npkg="${BOLD}${x}${NB}${NC}"	
				else
					npkg="$npkg ${BOLD}${x}${NB}${NC}"
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
		debugecho "MENU2: $mval $2 $3 $4"
		export COLUMNS=30
		select choice in All Minimum_Required $all $npkg $2 $3 $4 Back Exit
		do
			if [ Z"$choice" != Z"" ]
			then
				stripcolor
				if [ $choice = "Exit" ]
				then
					rm -f ${cdir}/$vpat
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
		if [ $myprogress -eq 1 ] && [ $dodebug -eq 0 ]
		then
			doprogress=1
		fi
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
		# some older files have more than one 'file size'
		tn=`echo $data | sed 's/<br>/\n/g' |sed 's/<\/span>/\n/g'| grep -n 'File size' | cut -d: -f 1 | head -1`
		let tn=$tn+1
		tsize=`echo $data | sed 's/<br>/\n/g' |sed 's/<\/span>/\n/g'| sed -n "${tn}p" | sed 's/^: //'`
		sha="sha256sum"
		tn=`echo $data | sed 's/<br>/\n/g' |sed 's/<\/span>/\n/g'| grep -n 'SHA256SUM' | cut -d: -f 1 | head -1`
		if [ Z"$tn" = Z"" ]
		then
			# no 256 so revert to sha1
			tn=`echo $data | sed 's/<br>/\n/g' |sed 's/<\/span>/\n/g'| grep -n 'SHA1SUM' | cut -d: -f 1 | head -1`
			sha="sha1sum"
		fi
		let tn=$tn+1
		sha256=`echo $data | sed 's/<br>/\n/g' |sed 's/<\/span>/\n/g'| sed -n "${tn}p" | cut -d' ' -f2`
		units=`echo $tsize | sed 's/.*[ 0-9]\([A-Z]\+\)/\1/'`
		if [ Z"$units" != Z"" ]
		then
			size=`echo $tsize | cut -d ' ' -f 1| sed "s/$units//"`
		else
			size=`echo $tsize | cut -d ' ' -f 1`
		fi
		#units=`echo $tsize | cut -d ' ' -f 2`
		debugecho "DEBUG: size => $size ; units => $units"
		fdata=`echo $data | sed 's/<\/a>/\n/g'| sed 's/<\/span/\n/g'|grep "button primary"`
		#echo $fdata |grep -v CART17Q1_HCI_WIN_100|egrep "CART|viewclients" >& /dev/null
		#href=`echo $fdata | sed 's/href/\nhref/' |grep href | cut -d\" -f2 | sed 's/amp;//g'`
		echo $fdata |grep 'download.\.vmware\.com' >& /dev/null
		if [ $? -eq 0 ]
		then
			drparams="CART"
			href=`echo $fdata | sed 's/href/\nhref/' |grep href | cut -d\" -f2`
			durl=''
		else
			#ndata=`echo $fdata | cut -d\" -f 6 | sed 's/amp;//g'| sed 's/[\&\?=]/ /g'`
			ndata=`echo $fdata | cut -d\" -f 6 | sed 's/amp;//g'| sed 's/[\&\?]/ /g'`
			#debugecho "DEBUG: ndata => $ndata"
			if [ Z"$size" != Z"" ]
			then
				size=`echo "$size *1024"|bc` # KB
				if [ Z"$units" = Z"MB" ] || [ Z"$units" = Z"GB" ] || [ Z"$units" = Z"G" ] || [ Z"$units" = Z"M" ]
				then # GB
					size=`echo "$size *1024"|bc`
				fi
				if [ Z"$units" = Z"GB" ] || [ Z"$units" = Z"G" ]
				then # GB
					size=`echo "$size *1000"|bc`
				fi
				size=`printf '%d\n' "$size" 2>/dev/null`
			fi
			for nx in `echo $ndata | sed 's/^\.//' | sed 's#/group/vmware/details##'`; do t=`echo $nx| cut -d= -f1`; s=`echo $nx|cut -d= -f2`; eval "$t=$s"; done
			dlgcode=$downloadGroup
			#dlgcode=`echo $ndata | cut -d' ' -f3`
			#productID=`echo $ndata | cut -d' ' -f5`
			#fileID=`echo $ndata | cut -d' ' -f9`
			#tagID=''
			#hashkey=`echo $ndata | cut -d' ' -f11`
			#downloaduuid=`echo $ndata | cut -d ' ' -f13`
			downloaduuid=$uuId
			#if [ Z"$vers" = Z"" ]
			#then
			#	vers=$pver
			#fi
			if [ Z"$dlgcode" = Z"VRLI-451-VCENTER" ]
			then
				dlgcode="VRLI-451"
			fi
			# what type of download again?
			dtcode=`echo $dlgcode | sed 's/DT_//'`
			dlgtype="Product+Binaries"
			if [ Z"$dtcode" != Z"$dlgcode" ]
			then
				dlgtype="Drivers+Tools"
			fi
			dtr="{\"sourcefilesize\":\"$size\",\"dlgcode\":\"$dlgcode\",\"languagecode\":\"en\",\"source\":\"DOWNLOADS\",\"downloadtype\":\"manual\",\"eula\":\"Y\",\"downloaduuid\":\"$downloaduuid\",\"purchased\":\"Y\",\"dlgtype\":\"$dlgtype\",\"productversion\":\"$pver\"}"
			debugecho "DEBUG: drparams => $dtr"
			drparams=`python -c "import urllib, sys; print urllib.quote(sys.argv[1])" $dtr`
			debugecho "DEBUG: drparams => $drparams"
			href="https://depot.vmware.com/getAuthUrl"
			if [ Z"${rndir}" = Z"/" ]
			then
				durl="https://${rndll}/software/${fname}"
			else
				durl="https://${rndll}/software/${rndir}/${fname}"
			fi
		fi
		debugecho "DEBUG: durl => $durl"
		#durl=`python -c "import urllib, sys; print urllib.quote(sys.argv[1])" $sdu`
	fi
}

function getvsm() {
	lchoice=$1
	additional=$2
	tchoice=$lchoice
	dotdir=0
	if [ Z"$3" != Z"" ]
	then
		tchoice=$3
		if [ $symlink -eq 1 ]
		then
			tdir=`echo $tchoice | sed 's/-/_/g'`
			dotdir=1
		fi
	fi
	ldir=`echo $lchoice | sed 's/-/_/g'`

	# this gets the repo items
	# check if file or file.gz
	# does not exist
	cd "$repo"
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
	if [ $symlink -eq 1 ]
	then
		rdir=`pwd`
	fi
	if [ $symlink -eq 1 ] && [ $dotdir -eq 1 ]
	then
		cd "$repo"
		if [ ! -e dlg_$tdir ]
		then
			mkdir -p $additional/dlg_$tdir
		fi
		cd $additional/dlg_$tdir
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
		# Ugh, special cases!
		echo $drparams | grep 'NSX-T' >& /dev/null
		if [ $? -eq 0 ]
		then
			vers=$pver
			prod="VMware+NSX"
		fi
		echo $drparams | grep -- '-NSX' >& /dev/null
		if [ $? -eq 0 ]
		then
			drparams=`echo $drparams | sed 's/-NSX//'`
			vers=$pver
			prod="VMware+vSphere"
		fi
		url="$href?params=$drparams&downloadurl=$durl&familyversion=$vers&productfamily=$prod"
	fi
	debugecho "DEBUG: url => $url"
	rnnot=0
	if [ Z"$rndll" = Z"" ] || [ Z"$rndir" = Z"" ] || [ Z"$rndir" = Z"$name" ]
	then
		if [ $debugv -ge 1 ]
		then
			echo ""
			echo "DEBUGV: name => $name" 
			echo "DEBUGV: dt => $prevchoice $currchoice $tchoice" 
			echo "DEBUGV: url => $url" 
			rnnot=1
		fi
	fi
	if [ $debugv -ge 2 ]
	then
		echo ""
		echo "$prevchoice $currchoice $tchoice $rndll $rndir $name" | sed 's/\.vmware\.com//'
		echo ""
	fi
	if [ $dovsmit -eq 1 ]
	then
		if [ $fixsymlink -eq 1 ] && [ $dotdir -eq 1 ]
		then
			if [ -f ${rdir}/${name} ]
			then
				rname=${rdir}/${name}
			fi
			if [ -f ${rdir}/${name}.gz ]
			then
				rname=${rdir}/${name}.gz
			fi
			# Move or Remove regular file if exists
			if [ ! -L ${rname} ]
			then
				if [ ! -e $name ] && [ ! -e ${name}.gz ]
				then
					mv ${rname} .
				else
					rm ${rname}
				fi
			fi
		fi
		if  ([ ! -e ${name} ] && [ ! -e ${name}.gz ]) || [ $doforce -eq 1 ]
		then 
			if [ Z"$drparams" = Z"CART" ]
			then
				lurl=$url
			else
				lurl=`wget --max-redirect 0 --load-cookies $cdir/cookies.txt --header='User-Agent: VMwareSoftwareManagerDownloadService/1.5.0.4237942.4237942 Windows/2012ServerR2' $url 2>&1 | grep Location | awk '{print $2}'`
			fi
			debugecho "DEBUG: lurl => $lurl"
			echo $lurl|grep -i blocked >& /dev/null
			if [ $? -ne 0 ]
			then
				if [ Z"$lurl" != Z"" ]
				then
					eurl=`python -c "import urllib, sys; print urllib.unquote(sys.argv[1])" $lurl`
					debugecho "DEBUG: eurl => $eurl"
					if [ $debugv -ge 1 ]
					then
						echo ""
						echo "$prevchoice $currchoice $tchoice $rndll $rndir $name" | sed 's/\.vmware\.com//'
						echo ""
					fi
					diddownload=0
					if [ $dryrun -eq 0 ]
					then
						mywget $name $eurl "--progress=bar:force" 1
					else
						mywget $name $eurl "--spider --progress=bar:force" 1
					fi
					# echo if error remove file
					if [ $err -ne 0 ]
					then
						if [ $dryrun -eq 0 ]
						then
							rm $name
						fi
						if [ $debugv -eq 1 ] && [ $rnnot -ne 1 ]
						then
							echo ""
							echo "DEBUGV: name => $name" 
							echo "DEBUGV: dt => $prevchoice $currchoice $tchoice" 
							echo "DEBUGV: url => $url" 
						fi
					else
						if [ $doshacheck -eq 1 ]
						then
							shadownload=1
							echo -n "$name: check "
							if [ Z"$sha" = Z"sha256sum" ]
							then
								sc=`sha256sum $name|cut -d' ' -f 1`
							else
								sc=`sha1sum $name|cut -d' ' -f 1`
							fi
							if [ Z"$sc" != Z"$sha256" ]
							then
								shafail="${shafail}
	${name}"
								colorecho "failed" 1
							else
								echo "passed"
							fi
						fi
						diddownload=1
					fi
				else
					if [ $doprogress -eq 1 ] || [ $debugv -eq 1 ]
					then
						echo -n "E"
						if [ $debugv -eq 1 ]
						then
							echo ""
							echo "DEBUGV: url => $url" 
						fi
					else
						colorecho "No Redirect Error Getting $name" 1
					fi
				fi
			else
				if [ $doprogress -eq 1 ] || [ $debugv -eq 1 ]
				then
					echo -n "B"
					else
					colorecho "Blocked Redirect Error Getting $name" 1
				fi
			fi
		fi
		if [ $compress -eq 1 ]
		then
			e=${name##*.}
			if [ Z"$e" != Z"zip" ] && [ Z"$e" != Z"gz" ] || [ Z"$e" == Z"$name" ]
			then
				if [ ! -e ${name}.gz ] && [ -e ${name} ]
				then
					echo -n "$name: gzip "
					gzip $name
					echo " ... done "
				fi
				name=${name}.gz
			fi
		fi
		if [ $symlink -eq 1 ]
		then
			# now create as symlink if it does not already exist
			if  [ ! -e ${rdir}/${name} ] && [ -e $name ]
			then 
				echo -n "$name: symlink "
				ln -s ../../$additional/dlg_$tdir/$name $rdir
				echo " ... done "
			fi
		fi
	fi
	cd ${cdir}/depot.vmware.com/PROD/channel
}

function version() {
	getvdat
	echo "LinuxVSM Version:"
	echo "	OS:        $theos"
	echo "	`basename $0`:    $VERSIONID"
	echo "	data file: `grep vsm.data $vdat|cut -d' ' -f 3|sed 's/vsm.data.//'`"
	exit
}

function usage() {
	echo "LinuxVSM Help"
	echo "$0 [-c|--check] [--dlg search] [--dlgl search] [-d|--dryrun] [-f|--force] [--fav favorite] [--favorite] [--fixsymlink] [-e|--exit] [-h|--help] [--historical] [-l|--latest] [-m|--myvmware] [-mr] [-nh|--noheader] [--nohistorical] [--nosymlink] [-nq|--noquiet] [-ns|--nostore] [-nc|--nocolor] [--dts|--nodts] [--oem|--nooem] [--oss|--nooss] [-p|--password password] [--progress] [-q|--quiet] [-r|--reset] [--symlink] [-u|--username username] [-v|--vsmdir VSMDirectory] [-V|--version] [-y] [-z] [--debug] [--repo repopath] [--save]"
	echo "	-c|--check - do sha256 check against download"
	echo "	--dlg - download specific package by name or part of name (regex)"
	echo "	--dlgl - list all packages by name or part of name (regex)"
	echo "	-d|--dryrun - dryrun, do not download"
	echo "	-f|--force - force download of packages"
	echo "	--fav favorite - specify favorite on command line"
	echo "	--favorite - download suite marked as favorite"
	echo "	--fixsymlink - convert old repo to symlink based repo"
	echo "	-e|--exit - reset and exit"
	echo "	-h|--help - this help"
	echo "	--historical - display older versions when you select a package"
	echo "	--nohistorical - disable --historical"
	echo "	-l|--latest - substitute latest for each package instead of listed"
	echo "		Deprecated: Now the default, the argument does nothing any more."
	echo "	-m|--myvmware - get missing suite and packages from My VMware"
	echo "		Deprecated: Now the default, the argument does nothing any more."
	echo "	-mr - reset just the My VMware information, implies -m"
	echo "	-nh|--noheader - leave off the header bits"
	echo "	-nq|--noquiet - disable quiet mode"
	echo "	-ns|--nostore - do not store credential data and remove if exists"
	echo "	-nc|--nocolor - do not output with color"
	echo "	-p|--password - specify password"
	echo "	--progress - show progress for OEM, OSS, and DriverTools"
	echo "	-q|--quiet - be less verbose"
	echo "	-r|--reset - reset VSM repoi - Not as useful as it once was"
	echo "	--symlink - use space saving symlinks"
	echo "	--nosymlink - disable --symlink mode"
	echo "	-u|--username - specify username"
	echo "	-v|--vsmdir path - set VSM directory - saved to configuration file"
	echo "	-V|--version - version number"
	echo "	-y - do not ask to continue"
	echo "	-z|--compress - compress files that can be compressed"
	echo "	--dts - include DriversTools in All-style downloads"
	echo "		    saved to configuration file"
	echo "	--nodts - do not include DriversTools in All-style downloads"
	echo "		      saved to configuration file"
	echo "	--oss - include OpenSource in All-style downloads"
	echo "		    saved to configuration file"
	echo "	--nooss - do not include OpenSource in All-style downloads"
	echo "		      saved to configuration file"
	echo "	--oem - include CustomIso in All-style downloads"
	echo "		    saved to configuration file"
	echo "	--nooem - do not include CustomIso in All-style downloads"
	echo "		      saved to configuration file"
	echo "	--debug - debug mode"
	echo "	--repo path - specify path of repo"
	echo "		          saved to configuration file"
	echo "	--save - save settings to \$HOME/.vsmrc, favorite always saved on Mark"
	echo ""
	echo "	All-style downloads include: All, All_No_OpenSource, Minimum_Required"
	echo ""
	echo "To Download the latest Perl CLI use "
	echo "	(to escape the wild cards used by the internal regex):"
	echo "	./vsm.sh --dlg CLI\.\*\\.x86_64.tar.gz"
	echo ""
	echo "Use of the Mark option, marks the current product suite as the" 
	echo "favorite. There is only 1 favorite slot available. Favorites"
	echo "can be downloaded without traversing the menus."

	exit;
}

function findos() {
	if [ -e /etc/os-release ]
	then
		. /etc/os-release
		theos=`echo $ID | tr [:upper:] [:lower:]`
	elif [ -e /etc/centos-release ]
	then
		theos=`cut -d' ' -f1 < /etc/centos-release | tr [:upper:] [:lower:]`
	elif [ -e /etc/redhat-release ]
	then
		theos=`cut -d' ' -f1 < /etc/redhat-release | tr [:upper:] [:lower:]`
	elif [ -e /etc/fedora-release ]
	then
		theos=`cut -d' ' -f1 < /etc/fedora-release | tr [:upper:] [:lower:]`
	elif [ -e /etc/debian-release ]
	then
		theos=`cut -d' ' -f1 < /etc/debian-release | tr [:upper:] [:lower:]`
	else
		# Mac OS
		uname -a | grep Darwin  >& /dev/null
		if [ $? -eq 0 ]
		then
			theos="macos"
		else
			colorecho "Do not know this operating system. LinuxVSM may not work." 1
			theos="unknown"
		fi
	fi
}

function checkdep() {
	dep=$1
	if [ Z"$theos" = Z"centos" ] || [ Z"$theos" = Z"redhat" ] || [ Z"$theos" = Z"fedora" ]
	then
		rpm -q $dep > /dev/null
		if [ $? -eq 1 ]
		then
			echo "Missing Dependency $dep"
			needdep=1
		fi
	fi
	if [ Z"$theos" = Z"debian" ] || [ Z"$theos" = Z"ubuntu" ]
	then
		dpkg -s $dep >& /dev/null
		if [ $? -eq 1 ]
		then
			echo "Missing Dependency $dep"
			needdep=1
		fi
	fi
	if [ Z"$theos" = Z"macos" ]
	then
		if [ Z"$dep" = Z"xcodebuild" ]
		then
			which $dep  >& /dev/null
			if [ $? -eq 1 ]
			then
				echo "Missing Dependency Xcode"
				needdep=1
			fi
		elif [ Z"$dep" = Z"jq" ] || [ Z"$dep" = Z"wget" ] || [ Z"$dep" = Z"gnu-sed" ]
		then
			brew list | grep $dep >& /dev/null
			if [ $? -eq 1 ]
			then
				echo "Missing Dependency $dep"
				needdep=1
			fi
		elif [ Z"$dep" = Z"urllib2" ]
		then
			python -c "help('modules')" 2>/dev/null | grep $dep >& /dev/null
			if [ $? -eq 1 ]
			then
				echo "Missing Dependency $dep"
				needdep=1
			fi
		else
			which $dep  >& /dev/null
			if [ $? -eq 1 ]
			then
				echo "Missing Dependency $dep"
				needdep=1
			fi
		fi
	fi
	if [ Z"$theos" = Z"unknown" ]
	then
		colorecho "Cannot Check Dependency $dep." 1
	fi
}

# set language to English
LANG=en_US.utf8
export LANG
# check dependencies
theos=''
docolor=1
needdep=0
debugv=0
findos
if [ Z"$theos" = Z"macos" ]
then
	checkdep xcodebuild
	checkdep xml_grep
	#checkdep urllib2
	checkdep gnu-sed
	checkdep uudecode
	alias sed=gsed
	alias uudecode="`which uudecode` -p"
	alias sha256sum="`which shasum` -a 256"
	alias sha1sum="`which shasum`"
else
	checkdep python-urllib3
	checkdep libxml2
	checkdep sharutils
	alias uudecode="`which uudecode` -o -"
fi
checkdep wget
checkdep python
if [ Z"$theos" = Z"centos" ] || [ Z"$theos" = Z"redhat" ] || [ Z"$theos" = Z"fedora" ]
then
	checkdep perl-XML-Twig
	checkdep ncurses
elif [ Z"$theos" = Z"debian" ] || [ Z"$theos" = Z"ubuntu" ]
then
	checkdep xml-twig-tools
	checkdep libxml2-utils
	checkdep ncurses-base
fi
checkdep bc
checkdep jq
shopt -s expand_aliases

if [ $needdep -eq 1 ]
then
	colorecho "Install dependencies first!" 1
	exit
fi

# latest wget does things differently
wget --help | grep -q '\--show-progress' && \
   _PROGRESS_OPT="-q --show-progress" || _PROGRESS_OPT=""

#
# Default settings
rPId=''
productId=''
dodebug=0
diddownload=0
doforce=0
dolatest=0
doreset=0
nostore=0
doexit=0
dryrun=0
dosave=0
historical=0
compress=0
beta=0
symlink=0
fixsymlink=0
nbeta1=1
mydts=-1
myoss=-1
myoem=-1
domenu2=0
indomenu2=0
domyvmware=1
remyvmware=0
myyes=0
myfav=0
myinnervm=0
myquiet=0
repo="/tmp/vsm"
cdir="/tmp/vsm"
vdat="/tmp/vsm/vsm.data"
vsmrc=""
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
orndir=''
orndll=''
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
fav=""
midprod=1
doprogress=0
myprogress=0
doquiet=0
doshacheck=0
noheader=0
domre=0
myq=0
dodlglist=0
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
load_vsmrc

while [[ $# -gt 0 ]]
do
	key="$1"
	case "$key" in
		-c|--check)
			doshacheck=1
			;;
		-h|--help)
			usage
			;;
		-l|--latest)
			dolatest=0
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
		-nh|--noheader)
			noheader=1
			;;
		-d|--dryrun)
			dryrun=1
			;;
		-nc|--nocolor)
			docolor=0
			;;
		--repo)
			repo="$2"
			if [ Z"$vsmrc" = Z"" ]
			then
				load_vsmrc
			fi
			shift
			;;
		--dlg)
			mydlg=$2
			dodlg=1
			shift
			;;
		--dlgl)
			mydlg=$2
			dodlg=1
			dodlglist=1
			shift
			;;
		--vexpertx)
			dovex=1
			;;
		-v|--vsmdir)
			cdir=$2
			if [ Z"$vsmrc" = Z"" ]
			then
				load_vsmrc
			fi
			shift
			;;
		--save)
			dosave=1
			;;
		--beta)
			beta=1
			;;
		--symlink)
			symlink=1
			;;
		--nosymlink)
			symlink=0
			;;
		--fixsymlink)
			fixsymlink=1
			symlink=1
			;;
		--historical)
			historical=1
			;;
		--nohistorical)
			historical=0
			;;
		--debug)
			debugv=1
			;;
		--debug2)
			debugv=2
			;;
		--debugv)
			dodebug=1
			;;
		--mre)
			domre=1;
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
		-q|--quiet)
			doquiet=1
			;;
		-nq|--noquiet)
			doquiet=0
			myq=0
			;;
		--progress)
			myprogress=1
			;;
		--favorite)
			if [ Z"$favorite" != Z"" ]
			then
				myfav=1
			fi
			;;
		--fav)
			fav=$2
			myfav=2
			shift
			;;
		-V|--version)
			version
			;;
		-z|--compress)
			compress=1
			;;
		*)
			usage
			;;
	esac
	shift
done

if [ $myquiet -eq 1 ] && [ $myq -eq 0 ]
then
	doquiet=1
fi

if [ $dodebug -eq 1 ]
then
	doquiet=0
fi

# remote trailing slash
repo=$(echo "$repo" | sed 's:/*$::')

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
if [ ! -w "$repo" ]
then
	colorecho "$repo is not writable by ${xu}." 1
	exit
fi

getvdat
if [ $noheader -eq 0 ]
then
	colorecho "Using the following options:"
	echo "	Version:	$VERSIONID"
	echo "	Data Version:	`grep vsm.data $vdat|cut -d' ' -f 3|sed 's/vsm.data.//'`"
	if [ $debugv -eq 1 ]
	then
		echo "	VSM Data:	$vdat"
	fi
	if [ Z"$username" != Z"" ]
	then
		echo "	Username:		$username"
		echo "	Save Credentials:	$nostore"
	fi
	echo "	OS Mode:        $theos"
	echo "	VSM XML Dir:	$cdir"
	echo "	Repo Dir:	$repo"
	echo "	Dryrun:		$dryrun"
	echo "	Force Download:	$doforce"
	echo "	Checksum:	$doshacheck"
	echo "	Historical Mode:$historical"
	echo "	Symlink Mode:	$symlink"
	echo "	Reset XML Dir:	$doreset"
	#echo "	Get Latest:	$dolatest"
	echo "	My VMware:	$domyvmware"
	if [ $myfav -eq 1 ]
	then
		echo "	Favorite: $favorite"
	fi
	if [ $myfav -eq 2 ]
	then
		echo "	Favorite: $fav"
	fi
fi

rcdir="${cdir}/depot.vmware.com/PROD/channel"
cd $cdir

# if we say to no store then remove!
if [ $nostore -eq 1 ]
then
	if [ -e .credstore ]
	then
		rm .credstore
	fi
fi

if [ ! -e .credstore ] || [ $nostore -eq 1 ]
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
		chmod 600 .credstore
	fi
	if [ $noheader -eq 0 ]
	then
		echo "	Use credstore:	0"
	fi
else
	if [ $noheader -eq 0 ]
	then
		echo -n "	Use credstore:	"
		if [ $nostore -eq 0 ]
		then
			echo '1'
		else
			echo '0'
		fi
	fi
	auth=`cat .credstore`
fi
if [ $noheader -eq 0 ]
then
	if [ $dovex -eq 1 ]
	then
		colorecho "	vExpert Mode:   1"
	fi
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
chmod 600 cookies.txt

# Extract JSESSIONID
JS=`grep JSESSIONID index.html | awk -F\; '{print $1}' |awk -F= '{print $2}'`
TS=`grep vmware cookies.txt |awk '{print $5}'`
#echo $JS
echo ".vmware.com	TRUE	/	TRUE	$TS	JSESSIONID	$JS" >> cookies.txt

if [ ! -e ${cdir}/depot.vmware.com ]
then
	doreset=1
fi

if [ $myprogress -eq 1 ] && [ $dodebug -eq 0 ]
then
	doprogress=1
fi

if [ $doreset -eq 1 ]
then
	colorecho "Reset Request"
	rm -rf ${cdir}/vpat*.txt
	if [ Z"$_PROGRESS_OPT" != Z"" ]
	then
		_PROGRESS_OPT=' '
	fi
	doqr=$doquiet
	if [ $doquiet -eq 1 ]
	then
		doquiet=0
	fi
	# Get index and subsequent data
	#mywget ' ' https://depot.vmware.com/PROD/index.xhtml '-rxl 1' 
	mywget ' ' https://depot.vmware.com/PROD/index.xhtml '-rxl 1 --reject-regex dlg_*' 
	if [ $err -ne 0 ]
	then
		exit $err
	fi
	if [ $doexit -eq 1 ]
	then
		exit 0
	fi
	if [ Z"$_PROGRESS_OPT" = Z" " ]
	then
		_PROGRESS_OPT=''
	fi
	doquiet=$doqr
fi

if [ $domre -eq 1 ]
then
	doreset=$domre
	rm -rf ${cdir}/vpat*.txt
fi

vpat=.vpat$$.txt
vpas=`head -1 $vdat | cut -d ' ' -f 3` 
echo "${vpas}.${VERSIONID}" > ${cdir}/${vpat}
chmod 400 ${cdir}/$vpat

uudecode $vdat | openssl enc -aes-256-ctr -d -a -salt -pass file:${cdir}/$vpat -md md5 2>/dev/null | grep AV_2121 >& /dev/null
if [ $? -ne 0 ]
then
	rm -rf ${cdir}/vpat*.txt
	colorecho "Unable to proceed:" 1
	colorecho "	LinuxVSM Datafile version mismatch" 1
	colorecho "	Please update to latest version of LinuxVSM" 1
	exit
fi
	


if [ ! -e ${rcdir}/_downloads.xhtml ] || [ $doreset -eq 1 ]
then
	# Get JSON
	mywget ${rcdir}/downloads.xhtml 'https://my.vmware.com/web/vmware/downloads?p_p_id=ProductIndexPortlet_WAR_itdownloadsportlet&p_p_lifecycle=2&p_p_state=normal&p_p_mode=view&p_p_resource_id=allProducts&p_p_cacheability=cacheLevelPage&p_p_col_id=column-3&p_p_col_count=1'

	# Parse JSON
	cat ${rcdir}/downloads.xhtml | jq '.[][].proList[]|.name,.actions[]'| tr '\n' ' ' | sed 's/} {/}\n{/g' | sed 's/} "/}\n"/g' | sed 's/" {/"\n{/g' |egrep '^"|Download Product'|tr '\n' ' '|sed 's/} "/}\n"/g' > ${rcdir}/_downloads.xhtml

	if [ $err -ne 0 ]
	then
		rm -f ${cdir}/$vpat
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
sha256=""
sha="sha256sum"
shafail=""
shadownload=0
durl=""
prevchoice=""
favorites=""
dlg=0
pkgs=""

if [ $dodlg -eq 1 ]
then
	debugecho "DEBUG: $mydlg"
	# Find the file
	if [ $dodlglist -eq 0 ]
	then
		myaf=`uudecode $vdat | openssl enc -aes-256-ctr -d -a -salt -pass file:${cdir}/$vpat -md md5 2>/dev/null | egrep "$mydlg" | sed 's/VCL_VSP..._//' | cut -d' ' -f2,6  | sed 's/\(\w\)_\(.* \)/\1\2/' | sed 's/U/0U/g' | sort -u -k1 -V | sed 's/0U/U/g' | cut -d' ' -f2|tail -1`
		mytf=`uudecode $vdat | openssl enc -aes-256-ctr -d -a -salt -pass file:${cdir}/$vpat -md md5 2>/dev/null | egrep "$myaf" | tail -1` 
	else
		uudecode $vdat | openssl enc -aes-256-ctr -d -a -salt -pass file:${cdir}/$vpat -md md5 2>/dev/null | egrep "$mydlg" | sed 's/VCL_VSP..._//' | cut -d' ' -f2,6  | sed 's/\(\w\)_\(.* \)/\1\2/' | sed 's/U/0U/g' | sort -u -k1 -V | sed 's/0U/U/g'
		exit
	fi
	debugecho "mytf => $mytf"
	if [ Z"$mytf" = Z"" ]
	then
		colorecho "No file found!" 1
		rm -f ${cdir}/$vpat
		exit
	else
		files=`echo $mytf | cut -d' ' -f6`
		mypkg=`echo $mytf | cut -d' ' -f3`
		choice=`echo $mytf | cut -d' ' -f2`
		prevchoice=`echo $mytf | cut -d' ' -f1`
	fi
	echo "Working $mydlg and found $files within $mypkg..."
	findfavpaths $prevchoice

	# now we run through all the prevchoices
	favorites=$prevchoice
	debugecho "DEBUG: Choice => $choice"
	debugecho "DEBUG: mfchoice => $mfchoice"
	debugecho "DEBUG: myfvmware => $myfvmware"
	debugecho "DEBUG: DLG => $favorites"
fi

if [ $myfav -eq 2 ]
then
	favorite=$fav
	myfav=1
	findfavpaths $favorite
	debugecho "DEBUG: mfchoice => $mfchoice"
	debugecho "DEBUG: myfvmware => $myfvmware"
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
	if [ $myfav -eq 1 ] || [ $dodlg -gt 0 ]
	then
		# setup auto-download of favorite
		if [ $dodlg -gt 0 ]
		then
			# This overrides DTS incase it is selected!
			dlg=2
		fi
		ochoice="All"
		if [ $domyvmware -eq 1 ]
		then
			if [ $dodlg -eq 0 ]
			then
				favorites=$favorite
			else
				ochoice=$choice
			fi
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
			choice=$ochoice
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
						#if [ $myfav -eq 0 ]
						#then
						#	doprogress=0
						#fi
						getasso
						if [ $myprogress -eq 1 ] && [ $dodebug -eq 0 ]
						then
							doprogress=1
						fi
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
							shaecho
							menu2 _dlg_${choice}.xhtml $oss $oem $dts
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
						indomenu2=1
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
								if [ $doprogress -eq 1 ] || [ $debugv -eq 1 ] && [ $dodlg -ne 1 ]
								then
									echo -n "."
								fi
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
										echo ""
										echo "Local:$repo/dlg_$currchoice/$name"
									fi
									debugecho "DEBUG: Getting $name"
									if [ Z"$name" != Z"" ]
									then
										getvsm $currchoice "base"
									fi
									if [ $dodlg -eq 1 ]
									then
										# Just exist, got package
										rm -f ${cdir}/$vpat
										exit
									fi
								fi
								# out to dev null seems to be required
								$((x++)) 2> /dev/null
							done
							if [ $doprogress -eq 1 ] || [ $debugv -eq 1 ] && [ $dodlg -ne 1 ]
							then
								echo "!"
							fi
							if [ $xignore -eq 0 ]
							then
								if [ $diddownload -eq 1 ]
								then
									colorecho "Downloads to $repo/dlg_$currchoice"
								else
									if [ $err -eq 0 ]
									then
										colorecho "All $currchoice already downloaded!"
										if [ $dodlg -eq 1 ]
										then
											# Just exist, got package
											rm -f ${cdir}/$vpat
											exit
										fi
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
										if [ -e dlg_${o}.xhtml ]
										then
											domts=1
										fi
									fi
									if [ $doprogress -eq 1 ] || [ $debugv -eq 1 ] && [ $dodlg -ne 1 ]
									then
										echo -n "-"
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
											if [ $doprogress -eq 1 ] || [ $debugv -eq 1 ] && [ $dodlg -ne 1 ]
											then
												echo -n "."
											fi
											# only do the selected
											xignore=0
											if [ $dodlg -eq 1 ]
											then
												echo ""
												echo "Local:$repo/dlg_$currchoice/$om/$name"
											fi
											if [ Z"$name" != Z"" ]
											then
												getvsm $currchoice $om $o
											fi
											# out to dev null seems to be required
											if [ $dodlg -eq 1 ]
											then
												# package exist, exit
												rm -f ${cdir}/$vpat
												exit
											fi
										fi
										let x=$x+1
									done
								done
								if [ $doprogress -eq 1 ] || [ $debugv -eq 1 ] && [ $dodlg -ne 1 ]
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
						indomenu2=0
						diddownload=0
						#choice=$prevchoice
					done
					getpath
					getchoice
				done # domenu2
			done
			shaecho
			doall=0
			echo ""
			if [ $myfav -eq 1 ] || [ $dodlg -gt 0 ]
			then
				rm -f ${cdir}/$vpat
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
