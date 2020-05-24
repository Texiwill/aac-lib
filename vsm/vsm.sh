#!/bin/bash
# vim: set tabstop=4 shiftwidth=4:
#
# Copyright (c) AstroArch Consulting, Inc.  2017-2020
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

VERSIONID="6.3.2"

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
			echo "${1}"
		fi
	fi
}
function debugecho() {
	if [ $dodebug -eq 1 ]
	then
		echo "${1}"
	fi
}
function debugvecho() {
	if [ $debugv -eq 1 ]
	then
		echo "${1}"
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

credfile=.credstore
credname="My VMware"
function handlecredstore ()
{
	# if we say to no store then remove!
	if [ $nostore -eq 1 ] || [ $cleanall -eq 1 ]
	then
		if [ -e $credfile ]
		then
			rm $credfile
		fi
		if [ -e $HOME/.vsm/.key ]
		then
			rm $HOME/.vsm/.key
		fi
	fi

	if [ ! -d $HOME/.vsm ]
	then
		mkdir $HOME/.vsm
	fi
	chmod 700 $HOME/.vsm

	if [ $cleanall -ne 1 ]
	then
		pbkdf2=''
		openssl enc --help 2>&1 | grep pbkdf2 >& /dev/null
		if [ $? -eq 0 ]
		then
			pbkdf2='-pbkdf2 -iter 1000'
		fi
		if [ ! -e $HOME/.vsm/.key ]
		then
        	openssl rand -base64 64 | tr '\n' ':' > $HOME/.vsm/.key
        	k=`cat $HOME/.vsm/.key`
			if [ -e $credfile ]
			then
        		# 1st time so recreate credstore
				auth=`cat $credfile`
        		echo -n $auth | openssl enc $pbkdf2 -aes-256-cbc -k "$k" -a -salt -base64 > $cdir/$credfile
			fi
		fi
		if [ -e $cdir/$credfile ]
		then
			chmod 600 $cdir/$credfile
		fi
		chmod 600 $HOME/.vsm/.key
		k=`cat $HOME/.vsm/.key`

		if [ ! -e $cdir/$credfile ] || [ $nostore -eq 1 ]
		then
			if [ Z"$username" = Z"" ]
			then
				echo -n "Enter $credname Username: "
				read username
			fi
			if [ Z"$password" = Z"" ]
			then
				echo -n "Enter $credname Password: "
				read -s password
			fi
		
			auth=`echo -n "${username}:${password}" |base64`
			if [ $nostore -eq 0 ]
			then
				# handle storing 'Basic Auth' for reuse
        		echo -n $auth | openssl enc $pbkdf2 -aes-256-cbc -k $k -a -salt -base64 > $cdir/$credfile
				chmod 600 $cdir/$credfile
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
			auth=`openssl enc $pbkdf2 -aes-256-cbc -d -in $cdir/$credfile -base64 -salt -k $k`
		fi
	fi
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
				if ((count > 2))
				then
					flag=true
				fi
			fi
		fi
	done
}

function wgeterror() {
	err=$1
	fname=$2
	debugecho "wget: $err"
	case "$err" in
	1) 
		if [ $debugv -eq 1 ]
		then
			echo ""
		fi
		colorecho "Generic Error Getting $fname" 1
		if [ $debugv -eq 1 ]
		then
			colorecho "$addHref"
			colorecho "wget $_PROGRESS_OPT $hd --load-cookies $cdir/$ck --header="User-Agent: $ua" $ou $hr"
		fi
		;;
	2)
		colorecho "Parse Error Getting $fname" 1
		;;
	3)
		colorecho "File Error: $fname (disk full, etc.)" 1
		;;
	4)
		colorecho "Network Error Getting $fname" 1
		;;
	5)
		colorecho "SSL Error Getting $fname" 1
		;;
	6)
		colorecho "Credential Error Getting $fname" 1
		;;
	7)
		colorecho "Protocol Error Getting $fname" 1
		;;
	8)
		colorecho "Server Error Getting $fname" 1
		;;
	esac
}

function findCk()
{
	ua='User-Agent: VMwareSoftwareManagerDownloadService/1.5.0.4237942.4237942 Windows/2012ServerR2'
	ck='cookies.txt'
	if [ -e $cdir/ocookies.txt ] && [ $myoauth -eq 1 ]
	then
		debugecho "Ocookies"
		ua=$oaua
		ck='ocookies.txt'
	fi
	if [ -e $cdir/pcookies.txt ] && [ $myoauth -eq 1 ]
	then
		debugecho "Pcookies"
		ua=$oaua
		ck='pcookies.txt'
	fi
}

function getJSON()
{
	if [ ! -e $rcdir/newlocs.json ] || [ $rebuild -eq 1 ]
	then
		mywget $rcdir/newlocs.json https://raw.githubusercontent.com/Texiwill/aac-lib/master/vsm/newlocs.json >& /dev/null
	fi
}

function mywget() {
	ou=$1
	hr=$2
	hd=$3
	err=0
	fname=$1
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
	debugecho "cookies"
	## should always try
	#if [ $myoauth -eq 1 ] || [ Z"$hd" = Z"pcookies" ] && [ $need_login -ne 0 ]
	#then
		oauth_login 0
	#fi
	dopost=0
	newck=0
	findCk # okay, cookies change with vExpert, so reset, then check
	if [ Z"$hd" = Z"pcookies" ]
	then
		debugecho "Real Pcookies"
		ua=$oaua
		ck='pcookies.txt'
		hd="--progress=bar:force --header='Referer: $mypatches_ref'" 
		newck=1
	fi
	if [ Z"$hd" = Z"vacookies" ]
	then
		debugecho "vExpert cookies"
		ua=$oaua
		ck='vacookies.txt'
		pd="dlfile=$dlfile"
		hd="--header='Referer: $vex_ref' --no-check-certificate --post-data=$pd"
		dopost=1
		newck=1
	fi
	if [ $debugv -ge 2 ]
	then
		echo "ck => $ck"
	fi
	if [ Z"$1" = "-" ]
	then
		# getting pre-url
		lurl=`wget --max-redirect 0 --load-cookies $cdir/$ck --header="User-Agent: $ua" -O - $hr 2>&1 | grep Location | awk '{print $2}'`
		err=${PIPESTATUS[0]}
	else
		debugecho "doquiet => $doquiet : $doprogress : $wgprogress"
		if [ $doquiet -eq 1 ]
		then
			#if [ $doprogress -eq 1 ]
			#then
			#	echo -n "+"
			#fi
			if [ Z"$wgprogress" = Z"1" ]
			then
				if [ ${#_PROGRESS_OPT} -eq 0 ]
				then
					wget $_PROGRESS_OPT --progress=bar:force $hd --load-cookies $cdir/$ck --header="User-Agent: $ua" $ou $hr 2>&1 | progressfilt 
					err=${PIPESTATUS[0]}
				else
					wget $_PROGRESS_OPT --progress=bar:force $hd --load-cookies $cdir/$ck --header="User-Agent: $ua" $ou $hr
					err=$?
				fi
			else
				wget $_PROGRESS_OPT $hd --load-cookies $cdir/$ck --header="User-Agent: $ua" $ou $hr >& /dev/null
				err=$?
			fi
			#if [ $doprogress -eq 1 ]
			#then
			#	echo -n "+"
			#fi
		else
			wget $_PROGRESS_OPT $hd --progress=bar:force --load-cookies $cdir/$ck --header="User-Agent: $ua" $ou $hr # 2>&1 | progressfilt
			err=$?
		fi
	fi
	if [ $newck -eq 0 ] 
	then
		wgeterror $err $fname
	fi
}

function checkForUpdate()
{
	oVer=`echo $VERSIONID | sed 's/\.//g'`
	nVer=`wget -O - https://raw.githubusercontent.com/Texiwill/aac-lib/master/vsm/vsm.sh 2>/dev/null|grep VERSIONID | head -1 | sed 's/\.//g'| sed 's/VERSIONID=//'|sed 's/\"//g'`
	if [ $nVer -gt $oVer ]
	then
		colorecho "Upgrade needed!" 1
		exit
	fi
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
		#echo '' > $vsmrc
		if [ $dosave -eq 1 ]
		then
			echo "favorite='$favorite'" > $vsmrc
			echo "repo='$repo'" >> $vsmrc
			echo "cdir='$cdir'" >> $vsmrc
			echo "myoem=$myoem" >> $vsmrc
			echo "mydts=$mydts" >> $vsmrc
			echo "myoss=$myoss" >> $vsmrc
			echo "myquiet=$doquiet" >> $vsmrc
			echo "myprogress=$doprogress" >> $vsmrc
			echo "doshacheck=$doshacheck" >> $vsmrc
			echo "dovexxi=$dovexxi" >> $vsmrc
			echo "historical=$historical" >> $vsmrc
			echo "compress=$compress" >> $vsmrc
			echo "symlink=$symlink" >> $vsmrc
			echo "olde=$olde" >> $vsmrc
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

function shacheck_file() {
	fn=$1
	if [ $doshacheck -eq 1 ]
	then
		shadownload=1
		echo -n "$fn: check "
		if [ $shavexdl -eq 1 ]
		then
			debugecho "gunzip $fn"
			# special for vExpert DL as its possibly already compressed
			if [ Z"$sha" = Z"sha256sum" ]
			then
				chk=`gunzip -c $fn | sha256sum |cut -d' ' -f 1`
			else
				chk=`gunzip -c $fn | sha1sum |cut -d' ' -f 1`
			fi
		else
			debugecho "no gunzip $fn"
			if [ Z"$sha" = Z"sha256sum" ]
			then
				chk=`sha256sum $fn|cut -d' ' -f 1`
			else
				chk=`sha1sum $fn|cut -d' ' -f 1`
			fi
		fi
		if [ Z"$chk" != Z"$sha256" ]
		then
			shafail="${shafail}
	${fn}"
			colorecho "failed" 1
		else
			echo "passed"
		fi
	fi
}

function compress_file() {
	name=$1
	if [ $compress -eq 1 ] && [ ${#name} -gt 0 ]
	then
		e=${name##*.}
		if [ Z"$e" != Z"zip" ] && [ Z"$e" != Z"ZIP" ] && [ Z"$e" != Z"gz" ] || [ Z"$e" == Z"$f" ] && [ Z"$e" != Z"tgz" ]
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
} 

function get_patch_list() {
	# do not get if not there already
	if [ ! -e $rcdir/_patches.xhtml ] || [ ! -e $cdir/pcookies.txt ]
	then
		# Patch List
		wget $_PROGRESS_OPT -O $rcdir/_patches.xhtml --load-cookies $cdir/pcookies.txt --post-data='' --header="User-Agent: $oaua" --header="Referer: $mypatches_ref" $patchUrl >& /dev/null
	fi
}

function get_patch_cookies()
{
	# force new cookies
	if [ -e $cdir/pcookies.txt ]
	then
		rm -f $cdir/pcookies.txt >& /dev/null
	fi
	# Patch Cookies - seems needed for many things
	wget -O ${rcdir}/patch.html $_PROGRESS_OPT --save-headers --cookies=on --load-cookies $cdir/acookies.txt --save-cookies $cdir/pcookies.txt --keep-session-cookies --header="User-Agent: $oaua" --header="Referer: $bmctx" $mypatches_ref >& /dev/null
	patchUrl=`grep searchPageUrl: ${rcdir}/patch.html | cut -d\' -f 2`
	if [ $dopatch -eq 1 ] && [ $dovexxi -eq 1 ] && [ $oauth_err -eq 1 ]
	then
		rm -f $rcdir/_*patch*.xhtml >& /dev/null
		get_patch_list
	fi
}

function vexpert_login() {
	if [ $dovexxi -eq 1 ]
	then
		o_credfile=$credfile
		o_credname=$credname
		o_auth=$auth
		credname="vExpert"
		credfile=.vex_credstore
		handlecredstore
		vauth=$auth

		csrf_token=`wget -O - $_PROGRESS_OPT --no-check-certificate --save-headers --cookies=on --save-cookies $cdir/vcookies.txt --keep-session-cookies --header='Cookie: JSESSIONID=' --header="User-Agent: $oaua" $vex_login 2>&1 | grep csrf_token | cut -d\" -f6`
		vex_auth=`echo $vauth | base64 --decode`
		rd=(`python -c "import urllib, sys; print urllib.quote(sys.argv[1])" "$vex_auth" 2>/dev/null|sed 's/%3A/ /'`)
		vd="csrf_token="$csrf_token"&login_email=${rd[0]}&login_password=${rd[1]}"
		wget -O $cdir/vex_auth.html $_PROGRESS_OPT --no-check-certificate --post-data="$vd" --save-headers --cookies=on --load-cookies $cdir/vcookies.txt --save-cookies $cdir/vacookies.txt --keep-session-cookies --header="User-Agent: $oaua" --header="Referer: $vex_login" $vex_login >& /dev/null #| grep AUTH-ERR >& /dev/null
		grep 'Error' $cdir/vex_auth.html >& /dev/null
       	vex_err=$?
		if [ $vex_err -eq 0 ]
		then
			colorecho "Incorrect vExpert Credentials" 0
			exit
		fi

		# now get the list of available downloads
		wget -O - $_PROGRESS_OPT --no-check-certificate --load-cookies $cdir/vacookies.txt --header="User-Agent: $oaua" --header="Referer: $vex_login" $vex_ref 2>&1 | grep data-file | cut -d\" -f6 > $rcdir/_vex_files.txt

		# reset settings for other use
		credfile=$o_credfile
		credname=$o_credname
		auth=$o_auth
	fi
}

need_login=0
function oauth_login() {
	dl=$1
	z=`date +"%s"`
	test_login=$(($z-$need_login))
	debugecho "OL: $test_login $need_login"
	if [ $test_login -ge 900 ]
	then
		need_login=$z
		# Get creds
		oauth=`echo $auth | base64 --decode`
		rd=(`python -c "import urllib, sys; print urllib.quote(sys.argv[1])" "$oauth" 2>/dev/null|sed 's/%3A/ /'`)
		#pd="vmware=login&username=${rd[0]}&password=${rd[1]}"
		pd="username=${rd[0]}&password=${rd[1]}"

		# Login
		bmctx=`wget -O - $_PROGRESS_OPT --save-headers --cookies=on --save-cookies $cdir/ocookies.txt --keep-session-cookies --header='Cookie: JSESSIONID=' --header="User-Agent: $oaua" $myvmware_login 2>&1 |grep Location| grep bmctx= | tail -1|awk '{print $2}'`
		#wget -O - $_PROGRESS_OPT --save-headers --cookies=on --save-cookies $cdir/ocookies.txt --keep-session-cookies --header="Referer: $myvmware_login" --header='Cookie: JSESSIONID=' --header="User-Agent: $oaua" $bmctx >& /dev/null
		wget -O $cdir/auth.html $_PROGRESS_OPT --post-data="$pd" --save-headers --cookies=on --load-cookies $cdir/ocookies.txt --save-cookies $cdir/acookies.txt --keep-session-cookies --header="User-Agent: $oaua" --header="Referer: $bmctx" $myvmware_oauth 2>&1 >& /dev/null #| grep AUTH-ERR >& /dev/null
		grep 'Error' $cdir/auth.html >& /dev/null
       	oauth_err=$?
		if [ $oauth_err -eq 1 ]
		then
			# Do SAML request!
			saml=`sed -n '/INPUT/,/"/p' $cdir/auth.html | sed 's/<INPUT TYPE="hidden" NAME="//' | sed 's/" VALUE//' | sed 's/\/>//'`
			s_action=`grep ACTION $cdir/auth.html | sed 's/<FORM METHOD="POST" ACTION="//' |sed 's/">//'`
			wget -O $cdir/sout.html $_PROGRESS_OPT --post-data="$saml" --save-headers --cookies=on --load-cookies $cdir/acookies.txt --save-cookies $cdir/scookies.txt --keep-session-cookies --header="User-Agent: $oaua" --header="Referer: $myvmware_oauth" $s_action >& /dev/null # now we are logged in
		fi
		get_patch_cookies # now we have the proper cookies
	fi
}

function get_product_patches() {
	ppr=`echo $missname | sed 's/\([A-Z]\+\)[0-9][0-9A-Z]\+/\1/'`
	if [ Z"$ppr" = Z"ESXI" ] || [ Z"$ppr" = Z"VC" ]
	then
		oauth_login 0
		if [ $ppr = "ESXI" ]
		then
			ppr="ESXi"
		fi
		ppv=`echo $v | sed 's/.\{1\}/&./g' | sed 's/\.$//'`
		if [ ${#ppv} -eq 3 ]
		then
			ppv="${ppv}.0"
		fi
		# patches only work for VC/ESXi
		if [ ! -e $rcdir/_${ppr}_${ppv}_patchlist.xhtml ] 
		then
			## First get index
			pin=`jq .[].prodList[].name ${rcdir}/_patches.xhtml | awk "/$ppr/{print NR-1}"`
			## Get 'productName'
			pnn=`jq ".[].prodList[${pin}].name" ${rcdir}/_patches.xhtml`
			## Get 'product'
			pvn=`jq ".[].prodList[${pin}].value" ${rcdir}/_patches.xhtml`
	
			# Get 'Details'
			pini=`jq ".[].prodList[${pin}].versions[].name" ${rcdir}/_patches.xhtml |awk "/$ppv/{print NR-1}"`
			pnam=`jq ".[].prodList[${pin}].versions[${pini}].name" ${rcdir}/_patches.xhtml`
			pinv=`jq ".[].prodList[${pin}].versions[${pini}].value" ${rcdir}/_patches.xhtml`
			prt=`jq ".[].prodList[${pin}].versions[${pini}].resultType" ${rcdir}/_patches.xhtml`

			# Patch Data per version
			pd=`echo "product=${pvn}&productName=${pnn}&version=${pinv}&versionName=${pnam}&resultType=${prt}&releasedate=YYYY-MM-DD&severity=All+Severities&category=All+Categories&classify=All+Classifications&releasenumber=Enter+Release+Name&buildnumber=Enter+Build+Number&bulletinnumber=Enter+Bulletin+Number&dependency=true" |sed 's/"//g' | sed 's/ /+/g'`
			#echo $pd
			wget -O ${rcdir}/_${ppr}_${ppv}_patchlist.xhtml --load-cookies $cdir/pcookies.txt --post-data="$pd" --header="User-Agent: $oaua" --header="Referer: $mypatches_ref" 'https://my.vmware.com/group/vmware/patch?p_p_id=PatchDownloadSearchPortlet_WAR_itofflinePatch&p_p_lifecycle=2&p_p_state=normal&p_p_mode=view&p_p_resource_id=getPatchData&p_p_cacheability=cacheLevelPage&p_p_col_id=column-6&p_p_col_pos=1&p_p_col_count=2' >& /dev/null
		fi

	else
		debugecho "Cannot get patches for $ppr"
	fi
}

function download_patches() {
	if [ $dopatch -eq 1 ] && [ $dovexxi -eq 1 ]
	then
		ppr=`echo $missname | sed 's/\([A-Z]\+\)[0-9][0-9A-Z]\+/\1/'`
		if [ Z"$ppr" = Z"ESXI" ] || [ Z"$ppr" = Z"VC" ]
		then
			dnr=1
			if [ $ppr = "ESXI" ]
			then
				ppr="ESXi"
				dnr=5
			fi
			ppv=`echo $v | sed 's/.\{1\}/&./g' | sed 's/\.$//'`
			if [ ${#ppv} -eq 3 ]
			then
				ppv="${ppv}.0"
			fi
			if [ -e $rcdir/_${ppr}_${ppv}_patchlist.xhtml ]
			then
				gotodir $missname "Patches" ${ppr}${ppv}
				
				# Download links as array
				darr=(`jq .[] ${rcdir}/_${ppr}_${ppv}_patchlist.xhtml | awk "/download/{print NR-$dnr}"`)
				downloads=(`jq .[] ${rcdir}/_${ppr}_${ppv}_patchlist.xhtml |grep download | sed 's/[,"]//g'`)
				#jq .[] ${rcdir}/${prod}_patchlist.xhtml |grep download
				d=0
				for px in ${downloads[@]}
				do
					# this causes a 'break'
					# need to restart download_patches
					oauth_login 1
					if [ $doprogress -eq 1 ] || [ $debugv -eq 1 ]
					then
						echo -n "."
					fi
					px=`echo $px | cut -d\! -f 1`
					py=`echo $px | cut -d\? -f 1`
					f=`basename $py`
					name=$f
					if  [ ! -e ${name} ] && [ ! -e ${name}.gz ] || [ $doforce -eq 1 ]
					then
						#echo `pwd` $name
						if [ $doprogress -eq 1 ] || [ $debugv -eq 1 ]
						then
							echo -n "p"
						fi
						# just in case we are not at beginning of line
						echo ""
						echo "Downloading $name to `pwd`:"
						mywget $name "$px" 'pcookies' 1
						if [ $doshacheck -eq 1 ]
						then
							sha256=`jq .[] ${rcdir}/_${ppr}_${ppv}_patchlist.xhtml | sed -n "${darr[$d]}p" | cut -d^ -f2 | sed 's/",//'`
							#echo ${darr[$d]}
							sha='sha1sum'
							shacheck_file $name
						fi
						compress_file $name
					fi
					mksymlink $name
					((d++))
					# get latest unless history set
					if [ $historical -eq 0 ]
					then
						break
					fi
				done
				if [ $doprogress -eq 1 ] || [ $debugv -eq 1 ]
				then
					echo "!"
				fi
				colorecho "Patches to $repo/dlg_${missname}/Patches"
				cd ${cdir}/depot.vmware.com/PROD/channel
			fi
		fi
	fi
}

function gotodir() {
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
	debugecho "DEBUG: tdir => $additional $tdir ($dotdir)"

	# fake symlink setup for large duplicate files
	if [ Z"$symdir" != Z"" ] && [ $symlink -eq 1 ]
	then
		dotdir=1
		additional="Additional"
		tdir="$symdir"
		debugecho "DEBUG: tdir => $additional $tdir ($dotdir)"
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
	# do not make for Additional
	if [ Z"$additional" != Z"base" ] && [ Z"$additional" != Z"Additional" ]
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
		if [ ! -e dlg_$tdir ] || [ Z"$additional" = Z"Additional" ]
		then
			mkdir -p $additional/dlg_$tdir
		fi
		cd $additional/dlg_$tdir
	fi
}

function mksymlink() {
	fn=$1
	if [ $symlink -eq 1 ]
	then
		# now create as symlink if it does not already exist
		if  [ ! -e ${rdir}/${fn} ] && [ -e $fn ]
		then 
			echo -n "$fn: symlink "
			if [ Z"$additional" = Z"Additional" ]
			then
				ln -s ../$additional/dlg_$tdir/$fn $rdir
			else
				ln -s ../../$additional/dlg_$tdir/$fn $rdir
			fi
			echo " ... done "
		fi
	fi
}

function version() {
	echo "LinuxVSM Version:"
	echo "	OS:        $theos"
	echo "	`basename $0`:    $VERSIONID"
	exit
}

function usage() {
	echo "LinuxVSM Help"
	echo "$0 [-c|--check] [--clean] [--dlg search] [--dlgl search] [-d|--dryrun] [-f|--force] [--fav favorite] [--favorite] [--fixsymlink] [-e|--exit] [-h|--help] [--historical] [-mr] [-nh|--noheader] [--nohistorical] [--nosymlink] [-nq|--noquiet] [-ns|--nostore] [-nc|--nocolor] [--dts|--nodts] [--oem|--nooem] [--oss|--nooss] [--oauth] [-p|--password password] [--progress] [-q|--quiet] [--rebuild] [--symlink] [-u|--username username] [-v|--vsmdir VSMDirectory] [-V|--version] [-y] [-z] [--debug] [--repo repopath] [--save] [--olde 12]"
	echo "	-c|--check - do sha256 check against download"
	echo "	--clean - remove all temporary files and exit"
	echo "	--dlg - download specific package by name or part of name (regex)"
	echo "	--dlgl - list all packages by name or part of name (regex)"
	echo "	-d|--dryrun - dryrun, do not download"
	echo "	-f|--force - force download of packages"
	echo "	--fav favorite - specify favorite on command line"
	echo "	--favorite - download suite marked as favorite"
	echo "	--fixsymlink - convert old repo to symlink based repo"
	echo "	-e|--exit - reset and exit"
	echo "	-h|--help - this help"
	echo "	-mr - remove temporary files"
	echo "	--historical - display older versions when you select a package"
	echo "	--nohistorical - disable --historical"
	echo "	-nh|--noheader - leave off the header bits"
	echo "	-nq|--noquiet - disable quiet mode"
	echo "	-ns|--nostore - do not store credential data and remove if exists"
	echo "	-nc|--nocolor - do not output with color"
	echo "  --olde - number of hours (default 12) before -mr enforced"
	echo "	-p|--password - specify password"
	echo "	--progress - show progress for OEM, OSS, and DriverTools"
	echo "	-q|--quiet - be less verbose"
	echo "	--rebuid - rebuild/add to JSON used by --dlgl and --dlg"
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
	#echo "	All-style downloads include: All, All_No_OpenSource, Minimum_Required"
	#echo ""
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
		if [ Z"$theos" = Z"linuxmint" ]
		then
			theos=`echo $ID_LIKE | tr [:upper:] [:lower:]`
		fi
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
	elif [ Z"$theos" = Z"debian" ] || [ Z"$theos" = Z"ubuntu" ]
	then
		dpkg -s $dep >& /dev/null
		if [ $? -eq 1 ]
		then
			echo "Missing Dependency $dep"
			needdep=1
		fi
	elif [ Z"$theos" = Z"macos" ]
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
			z=$dep
			if [ Z"$z" = Z"gnu-sed" ]
			then
				z="sed"
			fi
			which $z  >& /dev/null
			if [ $? -eq 1 ]
			then
				t="Not in PATH"
				brew list | grep $dep >& /dev/null
				if [ $? -eq 1 ]
				then
					t="Not Installed"
				fi
				echo "$t Dependency $dep"
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
	elif [ Z"$theos" = Z"unknown" ]
	then
		if [ Z"$dep" = Z"libxml2" ]
		then
			# ignore
			ignore=1
		elif [ Z"$dep" = Z"python-urllib3" ]
		then
			python -c "help('modules')" 2>/dev/null | grep urllib3 >& /dev/null
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
}

function loopdeps {
	if [ Z"$1" != Z"" ]
	then
		for item in $1 
		do 
			checkdep $item
		done
	fi
}

function finddeps {
	#Packages required by all OS
	all_checkdep="bc jq wget"
	#Packages required by MacOS
	macos_checkdep="$all_checkdep python xcodebuild xml_grep gnu-sed uudecode"
	#Packages required by all Linux Distros currently supported
	linux_checkdep="$all_checkdep libxml2 sharutils"
	#Packages required by Enterprise Linux and derivatives (including fedora)
	el_checkdep="perl-XML-Twig ncurses"
	#Packages required by Fedora 
	fedora_checkdep="$linux_checkdep $el_checkdep python2 python2-urllib3"
	#Packages required by RedHat and derivatives 
	redhat_checkdep="$linux_checkdep $el_checkdep python python-urllib3"
	#Packages required by Debian and derivatives 
	debian_checkdep="$linux_checkdep python python-urllib3 xml-twig-tools libxml2-utils ncurses-base"
	if [ Z"$theos" = Z"macos" ]
	then
		. $HOME/.bash_profile
		loopdeps "$macos_checkdep"
		alias sed=gsed
		alias uudecode="`which uudecode` -p"
		alias sha256sum="`which shasum` -a 256"
		alias sha1sum="`which shasum`"
	else
		# set language to English
		LANG=en_US.utf8
		export LANG
		loopdeps "$linux_checkdep"
		alias uudecode="`which uudecode` -o -"
	fi
	if [ Z"$theos" = Z"centos" ] || [ Z"$theos" = Z"redhat" ]
	then
		loopdeps "$redhat_checkdep"
	elif [ Z"$theos" = Z"fedora" ]
	then
		loopdeps "$fedora_checkdep"
	elif [ Z"$theos" = Z"debian" ] || [ Z"$theos" = Z"ubuntu" ]
	then
		loopdeps "$debian_checkdep"
	fi
}

function holidaybanner() {
	mon=`date +'%m'| sed 's/^0//'`
	day=`date +'%d'| sed 's/^0//'`
	if [ $mon -eq 12 ] && [ $day -gt 12 ] && [ $day -lt 26 ]
	then
		ac=$((1+RANDOM % 2))
		echo `tput setaf $ac`
		cat << "EOF"
 _   _                           _   _       _       _
| | | | __ _ _ __  _ __  _   _  | | | | ___ | (_) __| | __ _ _   _ ___ 
| |_| |/ _` | '_ \| '_ \| | | | | |_| |/ _ \| | |/ _` |/ _` | | | / __|
|  _  | (_| | |_) | |_) | |_| | |  _  | (_) | | | (_| | (_| | |_| \__ \
|_| |_|\__,_| .__/| .__/ \__, | |_| |_|\___/|_|_|\__,_|\__,_|\__, |___/
            |_|   |_|    |___/                               |___/     
EOF
		echo "$NC"
		sleep 1
	fi
	if [[ ($mon -eq 12 && $day -gt 20) || ($mon -eq 1 && $day -lt 3) ]]
	then
		echo "${TEAL}"
		cat << "EOF"
 _   _                           _   _                __   __              
| | | | __ _ _ __  _ __  _   _  | \ | | _____      __ \ \ / /__  __ _ _ __ 
| |_| |/ _` | '_ \| '_ \| | | | |  \| |/ _ \ \ /\ / /  \ V / _ \/ _` | '__|
|  _  | (_| | |_) | |_) | |_| | | |\  |  __/\ V  V /    | |  __/ (_| | |   
|_| |_|\__,_| .__/| .__/ \__, | |_| \_|\___| \_/\_/     |_|\___|\__,_|_|   
            |_|   |_|    |___/                                             
EOF
		echo "$NC"
		sleep 2
	fi
	if [ $mon -eq 2 ] && [ $day -eq 29 ]
	then
		tput clear
		echo "${PURPLE}"
		cat << "EOF"






    __                       __  __                          ____
   / /   ___  ____ _____    / / / /___ _____  ____  __  __  / __ \____ ___  __
  / /   / _ \/ __ `/ __ \  / /_/ / __ `/ __ \/ __ \/ / / / / / / / __ `/ / / /
 / /___/  __/ /_/ / /_/ / / __  / /_/ / /_/ / /_/ / /_/ / / /_/ / /_/ / /_/ / 
/_____/\___/\__,_/ .___/ /_/ /_/\__,_/ .___/ .___/\__, / /_____/\__,_/\__, /  
                 /_/                /_/   /_/    /____/              /____/   
EOF
		sleep 1
		tput clear
		cat << "EOF"
          __                    
         / /   ___  ____ _____  
        / /   / _ \/ __ `/ __ \
       / /___/  __/ /_/ / /_/ /
      /_____/\___/\__,_/ .___/ 
    __  __            /_/                                      ____
   / / / /___ _____  ____  __  __                             / __ \____ ___  __
  / /_/ / __ `/ __ \/ __ \/ / / /                            / / / / __ `/ / / /
 / __  / /_/ / /_/ / /_/ / /_/ /                            / /_/ / /_/ / /_/ / 
/_/ /_/\__,_/ .___/ .___/\__, /                            /_____/\__,_/\__, /  
           /_/   /_/    /____/                                         /____/   
EOF
		sleep 1
		tput clear
		cat << "EOF"






    __  __                           __                        ____             
   / / / /___ _____  ____  __  __   / /   ___  ____ _____     / __ \____ ___  __
  / /_/ / __ `/ __ \/ __ \/ / / /  / /   / _ \/ __ `/ __ \   / / / / __ `/ / / /
 / __  / /_/ / /_/ / /_/ / /_/ /  / /___/  __/ /_/ / /_/ /  / /_/ / /_/ / /_/ / 
/_/ /_/\__,_/ .___/ .___/\__, /  /_____/\___/\__,_/ .___/  /_____/\__,_/\__, /  
           /_/   /_/    /____/                   /_/                   /____/   
EOF
		echo "$NC"
		sleep 2
	fi
	if [ $mon -eq 4 ] && [ $day -eq 1 ]
	then
		ac=$((RANDOM % 8))
		echo `tput setaf $ac`
		cat << "EOF"
                              _          _        
                  /\ ._ ._o| |__  _ | _ | \ _.  | 
                 /--\|_)| || |(_)(_)|_> |_/(_|\/o 
                     |                        /   
EOF
		echo "$NC"
		sleep 2
	fi
	if [ $mon -eq 3 ] && [ $day -eq 14 ]
	then
		ac=$((RANDOM % 8))
		echo `tput setaf $ac`
		cat << "EOF"
#     #                                  3.141592    ######               
#     #   ##   #####  #####  #   #      653589793    #     #   ##   #   # 
#     #  #  #  #    # #    #  # #      23    84      #     #  #  #   # #  
####### #    # #    # #    #   #      6 2    64      #     # #    #   #   
#     # ###### #####  #####    #        3    38      #     # ######   #   
#     # #    # #      #        #        3    27      #     # #    #   #   
#     # #    # #      #        #        9    50 2    ######  #    #   #   
                                      8 8    4197                         
                                       16     93
EOF
	fi
}

# onscreen colors
RED=`tput setaf 1`
PURPLE=`tput setaf 5`
NC=`tput sgr0`
BOLD=`tput smso`
NB=`tput rmso`
TEAL=`tput setaf 6`
GRAY=`tput setaf 7`
holidaybanner
# check dependencies
theos=''
docolor=1
needdep=0
debugv=0
findos
finddeps
shopt -s expand_aliases

if [ $needdep -eq 1 ]
then
	colorecho "Install dependencies first!" 1
	exit
fi

# latest wget does things differently
wget --help | grep -q -- '--show-progress' && \
   _PROGRESS_OPT="-q --show-progress" || _PROGRESS_OPT=""

#
# Default settings
productId=''
dodebug=0
diddownload=0
doforce=0
dolatest=0
doreset=0
nostore=0
cleanall=0
doexit=0
dryrun=0
dosave=0
historical=0
compress=0
symlink=0
symdir=''
fixsymlink=0
mydts=-1
myoss=-1
myoem=-1
remyvmware=0
myyes=0
myfav=0
myquiet=0
repo="/tmp/vsm.${USER}"
cdir="/tmp/vsm.${USER}"
vsmrc=""
mypkg=""
mydlg=""
dodlg=0
dovexxi=0
dopatch=0
oauthonly=0
myoauth=1
patcnt=0
# general
pver=''
name=''
data=''
err=0
# Used by myvmware
missname=""
mversions=""
longReply=0
fav=""
doprogress=0
myprogress=0
doquiet=0
doshacheck=0
noheader=0
myq=0
dodlglist=0
doignore=0
rebuild=0
dlgroup=''
allmissing=0
olde=12
mycolumns=`tput cols`

xu=`id -un`

if [ Z"$xu" = Z"root" ]
then
	colorecho "VSM cannot run as root." 1
	exit
fi

checkForUpdate

# import values from .vsmrc
load_vsmrc

while [[ $# -gt 0 ]]; do key="$1"; case "$key" in --allmissing) $allmissing=1; shift;; --dlgroup) dlgroup=$2; shift;; -c|--check) doshacheck=1 ;; -h|--help) usage ;; -i|--ignore) doignore=1 ;; -l|--latest) dolatest=0 ;; -r|--reset) doreset=1 ;; -f|--force) doforce=1 ;; -e|--exit) doreset=1; doexit=1 ;; -y) myyes=1 ;; -u|--username) username=$2; shift ;; -p|--password) password=$2; shift ;; -ns|--nostore) nostore=1 ;; -nh|--noheader) noheader=1 ;; -d|--dryrun) dryrun=1 ;; -nc|--nocolor) docolor=0 ;; --repo) repo="$2"; if [ Z"$vsmrc" = Z"" ]; then load_vsmrc; fi; shift ;; --dlg) mydlg=$2; dodlg=1; shift ;; --dlgl) mydlg=$2; dodlglist=1; shift ;; --vexpertx) dovexxi=1 ;; --patches) if [ $dovexxi -eq 1 ]; then dopatch=1; fi ;; -v|--vsmdir) cdir=$2; if [ Z"$vsmrc" = Z"" ]; then load_vsmrc; fi; shift ;; --save) dosave=1 ;; --symlink) symlink=1 ;; --nosymlink) symlink=0 ;; --fixsymlink) fixsymlink=1; symlink=1 ;; --historical) historical=1 ;; --nohistorical) historical=0 ;; --debug) debugv=1 ;; --debugv) dodebug=1 ;; --clean) cleanall=1; doreset=1; remyvmware=1;; --dts) mydts=1 ;; --oem) myoem=1 ;; --oss) myoss=1 ;; --nodts) mydts=0 ;; --nooem) myoem=0 ;; --nooss) myoss=0 ;; -mr) remyvmware=1;; -q|--quiet) doquiet=1 ;; -nq|--noquiet) doquiet=0 myq=0 ;; --progress) myprogress=1 ;; --favorite) if [ Z"$favorite" != Z"" ]; then myfav=1; fi ;; --fav) fav=$2; myfav=2; shift ;; -V|--version) version ;; -z|--compress) compress=1 ;; --rebuild) rebuild=1 ;; --olde) olde=$2; shift;; *) usage ;; esac; shift; done

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

if [ $noheader -eq 0 ]
then
	colorecho "Using the following options:"
	echo "	Version:	$VERSIONID"
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
if [ ! -e $rcdir ]
then
	mkdir -p $rcdir
fi

# Cleanup old data if any
rm -f cookies.txt index.html.* 2>/dev/null

# Get Olde Time and remove temp files if time limited reached, default 12 hours
if [ -e ${rcdir}/_downloads.xhtml ]
then
	mrt=$((olde*3600))
	ot=$((($(date +%s) - $(stat -c %Y -- ${rcdir}/_downloads.xhtml)) - $mrt))
	debugvecho "	Cache Timeout: 	$ot" 
	if [ $ot -gt 0 ]
	then
		remyvmware=1
	fi
fi

# Delete all My VMware files! So we can start new
if [ $remyvmware -eq 1 ]
then
	rm -rf ${rcdir}/_*
fi

if [ $doreset -eq 1 ]
then
	rm -rf ${rcdir}/*
fi

handlecredstore

# remove all and clean up
if [ $cleanall -eq 1 ]
then
	# vExpert handled a bit later
	if [ -e $cdir/.vex_credstore ]
	then
		rm $cdir/.vex_credstore
	fi
	colorecho "Removed all Temporary Files"
	exit
fi

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

if [ ! -e ${cdir}/depot.vmware.com ]
then
	doreset=1
fi

if [ $myprogress -eq 1 ] && [ $dodebug -eq 0 ]
then
	doprogress=1
fi

# Clear any cached elements
rm -f ${cdir}/*.{txt,html} 2>/dev/null

# no need to login for this option, list what is in the file
if [ $dodlglist -eq 1 ]
then
	if [ ! -e $rcdir/newlocs.json ]
	then
		getJSON
	fi
	if [ -e $rcdir/newlocs.json ]
	then
		jq --arg s "$mydlg" '.dlgList[] | select(.name | test($s)).name' $rcdir/newlocs.json | sed 's/"//g'
	fi
	exit
fi

# Present the list
cd depot.vmware.com/PROD/channel

# Patches
oauth_err=0
mydl_ref='https://my.vmware.com/group/vmware/downloads#tab1'
mypatches_ref='https://my.vmware.com/group/vmware/patch'
myvmware_login='https://my.vmware.com/web/vmware/login'
#myvmware_oauth='https://my.vmware.com/oam/server/auth_cred_submit'
myvmware_oauth='https://auth.vmware.com/oam/server/auth_cred_submit?Auth-AppID=WMVMWR'
vex_login='https://vexpert.vmware.com/login'
vex_ref='https://vexpert.vmware.com/my/downloads/'
oaua='Mozilla/5.0 (X11; Fedora; Linux x86_64; rv:60.0) Gecko/20100101 Firefox/60.0'
ppr=''
ppv=''

# Authenticate
if [ $noheader -eq 0 ]; then colorecho "	Authenticating... "; fi
oauth_login 0
if [ $oauth_err -eq 1 ]
then
	if [ $noheader -eq 0 ]; then colorecho "	Oauth:		1"; fi
else
	colorecho "	Oauth:		Error" 1
	dopatch=0
	exit
fi
if [ $dopatch -eq 1 ] && [ $dovexxi -eq 1 ]
then
	# force patch oauth
	get_patch_list
	if [ $noheader -eq 0 ]; then colorecho "	Patches:	1"; fi
fi

findCk
if [ ! -e ${rcdir}/_downloads.xhtml ] || [ $doreset -eq 1 ]
then
	# Get JSON
	mywget ${rcdir}/_h_downloads.html https://my.vmware.com/group/vmware/downloads
	#mywget ${rcdir}/_h_downloads.html https://my.vmware.com/en/web/vmware/downloads
	tab2url=`grep allProducts ${rcdir}/_h_downloads.html | cut -d\" -f4`

	grep "Temporary Maintenance" ${rcdir}/_h_downloads.html >& /dev/null
	if [ $? -eq 0 ]
	then
		colorecho "Error: My VMware Temporary Maintenance" 1
		exit;
	fi

	mywget ${rcdir}/_j_downloads.xhtml $tab2url "--post-data=''"

	if [ ! -e ${rcdir}/_j_downloads.xhtml ]
	then
		colorecho "Error: Could not get My VMware Downloads File" 1
		exit;
	fi

	# Parse JSON
	cat ${rcdir}/_j_downloads.xhtml | jq '.[][].proList[]|.name,.actions[]'| tr '\n' ' ' | sed 's/} {/}\n{/g' | sed 's/} "/}\n"/g' | sed 's/" {/"\n{/g' |egrep '^"|Download'|tr '\n' ' '|sed 's/} "/}\n"/g' > ${rcdir}/_downloads.xhtml

	if [ $err -ne 0 ]
	then
		exit $err
	fi
fi


# save a copy of the .vsmrc and continue
save_vsmrc

# Login to vexpert.vmware.com
vexpert_login

# start of history
myvmware_root="https://my.vmware.com/group/vmware/"
myvmware_ref="https://my.vmware.com/group/vmware/downloads#tab1"
choice="root"
name=""
sha256=""
sha="sha256sum"
shafail=""
shadownload=0

layer=('productCategoryList[]' 'name')
function removeLayer()
{
	debugvecho "DEBUG rl: ${layer[@]}"
	arr=()
	skipfive=0
	if [ ${#layer[@]} -eq 5 ] && [ ${layer[3]} = ${layer[4]} ]
	then
		skipfive=1 # this is a skip
	fi
	if [ ${layer[2]} = "name" ]
	then
		layer=('productCategoryList[]' 'name') # layer 1
	elif [ ${layer[2]} = "actions" ]
	then
		layer=(${layer[0]}) # layer 2
		layer+=('proList[]')
		layer+=('name')
	elif [ ${#layer[@]} -eq 4 ] || [ $skipfive -eq 1 ]
	then
		choice=${layer[2]}
		arr=(${layer[0]}) # layer 3
		arr+=(${layer[1]})
		arr+=('actions')
		layer=(${arr[@]})
	else
		sz=${#layer[@]}
		nsz=$(($sz-1))
		rsz=$(($sz-2))
		i=0
		choice=${layer[$nsz]}
		for x in ${layer[@]:0:$nsz}
		do
			# need to conver the last [$lr] to []
			if [ $i -eq $rsz ]
			then
				x=`echo $x | sed 's/\[.*\]/[]/'`
			fi
			arr+=($x)
			i=$(($i+1))
		done
		layer=(${arr[@]})
		##
		# longReply may be wrong here!
		missname=$specMissname
	fi
	debugvecho "DEBUG rl: ${layer[@]}"
}

function createLayer()
{
	if [ $choice = "Back" ]
	then
		removeLayer
	else
		lr=$(($longReply-1))
		if [ Z"${layer[1]}" = Z"name" ]
		then
			layer=("productCategoryList[$lr]")
			layer+=('proList[]')
			layer+=('name')
		elif [ ${layer[2]} = "name" ]
		then
			layer=(${layer[0]})
			layer+=("proList[$lr]")
			layer+=('actions')
		elif [ ${layer[2]} = "actions" ]
		then
			pl=${layer[1]}
			layer=(${layer[0]})
			layer+=("$pl")
			layer+=("$missname") # solution
			layer+=("$choice") # version
		else
			layer+=("$choice") # element
		fi
	fi
}

function getVersionList()
{
	# get the versions
	tver=`xmllint --html --xpath "//div[@class=\"versionList\"]" ${rcdir}/_$missname.xhtml 2>/dev/null |grep option |cut -d'>' -f 2|cut -d'<' -f1|sed 's/\./_/g'|sort -rV`
	# no options, just 1 version
	if [ Z"$tver" = Z"" ]
	then
		tver=`xmllint --html --xpath "//div[@class=\"versionList\"]" ${rcdir}/_$missname.xhtml 2>/dev/null |tr -d '\n\t' |cut -d'>' -f 2|cut -d'<' -f1|sed 's/\./_/g'|sort -rV`
		if [ Z"$tver" = Z"" ]
		then
			tver=`xmllint --html --xpath "//select[@id=\"versionList\"]" ${rcdir}/_$missname.xhtml 2>/dev/null | sed 's/ /\n/g' |grep downloadgroupid |cut -d\" -f2 | sed 's/-/_/g'`
		fi
	fi
}

function getMyVersions()
{
	# we need to go to My VMware now
	action=`jq "${layers}[]" $rcdir/_j_downloads.xhtml | tr '\n' ' ' | sed 's/} {/}\n{/g' | sed 's/} "/}\n"/g' | sed 's/" {/"\n{/g' |egrep '^"|Download'|tr '\n' ' '|sed 's/} "/}\n"/g'|cut -d\" -f12 |sed 's#\./##'`
	missname=$choice
	if [ ! -e ${rcdir}/_${missname}.xhtml ] || [ $doreset -eq 1 ]
	then
		mywget ${rcdir}/_${missname}.xhtml ${myvmware_root}${action}
	fi
	getVersionList
	pkgs=''
	for x in $tver
	do
		pkgs="$pkgs ${missname}_${x}"
	done
}

function getMySuites()
{
	# deal with version. If 1 then its the same file
	nnr=$(($nr-1))
	missname=${layer[$nnr]}
	nnr=$(($nnr-1))
	ver=`echo $missname | sed "s/${layer[$nnr]}_//"`
	over=`basename $action`
	naction=`echo $action | sed "s/$over/$ver/"`
	if [ ! -e ${rcdir}/_${missname}.xhtml ] || [ $doreset -eq 1 ]
	then
		mywget ${rcdir}/_${missname}.xhtml ${myvmware_root}${naction}
	fi
	mversions=`xmllint --html --xpath "(//div[@class=\"tabContent\"])[1]" $rcdir/_${missname}.xhtml 2>/dev/null | grep longProductColumn |cut -d'>' -f3|cut -d'<' -f1 | sed 's/[ -]/_/g'`
	pkgs=''
	for x in $mversions
	do
		pkgs="$pkgs ${missname}_${x}"
	done
	if [ ${#mversions} -eq 0 ]
	then
		choice=$missname
	fi
}

doColor=1
function colorMyPkgsFound()
{
	if [ $useDlg -eq 1 ]
	then
		fName="dlg_${x}"
	else
		fName="dlg_${whatever}/${x}"
	fi
	if [ ! -e "${repo}/$fName" ] && [ ! -e "${repo}/${fName}.gz" ]
	then
		if [ ${#npkg[@]} -eq 0 ]
		then
			npkg=("${BOLD}${TEAL}${x}${NB}${NC}")
		else
			npkg+=("${BOLD}${TEAL}${x}${NB}${NC}")
		fi
	else
		if [ ${#npkg[@]} -eq 0 ]
		then
			npkg=("$x")
		else
			npkg+=("$x")
		fi
	fi
}
function colorMyPkgs()
{
	arr=$1
	npkg=()
	useDlg=1
	i=0
	if [ Z"$2" != Z"" ]
	then
		useDlg=$2
	fi
	if [ $doColor -eq 1 ]
	then
		for x in $arr 
		do
			y=${tdls[$i]}
			if [ ${#y} -lt 5 ] && [ $useDlg -eq 0 ]
			then
				vexit=0
				if [ $dovexxi -eq 1 ]
				then
					grep ${x} $rcdir/_vex_files.txt >& /dev/null
					if [ $? -eq 0 ]
					then
						vexit=1
					fi
				fi
				if [ $vexit -eq 0 ]
				then
					if [ ${#npkg[@]} -eq 0 ]
					then
						npkg=("${GRAY}${x}${NB}${NC}")
					else
						npkg+=("${GRAY}${x}${NB}${NC}")
					fi
				else
					# really should check for existence 
					colorMyPkgsFound
				fi
			else
				colorMyPkgsFound
			fi
			i=$(($i+1))
		done
	else
		npkg=(${arr[@]})
	fi
}

function getMyDlgs()
{
	nnr=$(($nr-1))
	missname=${layer[$nnr]}
	nnr=$(($nr-2))
	specname=${layer[$nnr]}
	if [ $nr -gt $prevNr ] #forward
	then
		specReply=$longReply
	fi
	# use longReply as this is groups by more-details
	xpkgs=`xmllint --html --xpath "(//div[@class=\"tabContent\"])[1]" $rcdir/_${specname}.xhtml 2>/dev/null | xmllint --html --xpath "(//tr[contains(@class,\"more-details\")])[$specReply]" - 2>/dev/null | grep downloadGroup | grep -v OSS  | cut -d\? -f 2 | cut -d \& -f 1 | cut -d= -f 2 | sed 's/-/_/g'`
	# need to swing through xpkgs for exist vs not
	colorMyPkgs "$xpkgs"
	if [ ${#xpkgs} -gt 2 ]
	then
		mark="Mark"
	fi
	pkgs="All ${npkg[@]}"
}

function getMyDlgVersions()
{
	sc=$1
	if [ $sc -eq 0 ]
	then
		nnr=$(($nr-1))
		missname=${layer[$nnr]}
	fi
	iname=`echo $missname | sed 's/_/[_-]/g'`
	vurl=`xmllint --html --xpath "(//div[@class=\"tabContent\"])[1]" $rcdir/_${specname}.xhtml 2>/dev/null | xmllint --html --xpath "(//tr[contains(@class,\"more-details\")])[$specReply]" - 2>/dev/null | grep downloadGroup | grep $iname | sed 's/\"buttoncol\"//' | cut -d\" -f2 | sed 's/amp;//g'`
	if [ ! -e ${rcdir}/_${missname}.xhtml ] || [ $doreset -eq 1 ]
	then
		mywget ${rcdir}/_${missname}.xhtml https://my.vmware.com${vurl}
	fi
	if [ $sc -eq 0 ]
	then
		getVersionList
		colorMyPkgs "$tver"
		pkgs=${npkg[@]}
	fi
}

function getTabcOne()
{
	whatever=$1
	xdata=`xmllint --html --xpath "(//div[@class=\"tabContent\"])[1]" $rcdir/_${whatever}.xhtml 2>/dev/null`
	xpkgs=`echo $xdata | xmllint --html --xpath '//span[@class="fileNameHolder"]/text()' - 2>/dev/null`
	if [ ${#xpkgs} -eq 0 ]
	then
		echo $xdata | fgrep 'There are no binaries available for this product.' >& /dev/null
		if [ $? -eq 0 ]
		then
			colorecho "No Primary Downloads Available for this Product" 1
		else
			fgrep 'Unable to Complete Your Request' $rcdir/_${whatever}.xhtml >& /dev/null
			if [ $? -eq 0 ]
			then
				if [ $doprogress -eq 1 ] || [ $debugv -eq 1 ]
				then
					echo -n "M"
				else
					colorecho "My VMware down for maintenance"
				fi
			fi
		fi
	fi
	tdls=(`echo $xdata | xmllint --html --xpath '//a[@class="md"]' - 2>/dev/null | sed 's/<a/\n<a/g' | grep md | sed 's/<a//' | sed 's/class="md"//' | sed 's/ //g' | cut -d\" -f2- | cut -d\> -f1|sed "s/''/#/g"`)
	#sed 's/<a/\n<a/g' | grep md | sed 's/ //g' | cut -d\" -f4- | cut -d\> -f1|sed "s/''/#/g"`)
}

function getMyPatches()
{
	patcnt=0
	if [ $dopatch -eq 1 ]
	then
		echo $missname | egrep '_[0-9]|-[0-9]' >& /dev/null
		if [ $? -eq 0 ]
		then
			v=`echo ${missname} | sed 's/[0-9A-Z]\+[-_]\([0-9]\+\).*$/\1/' 2>/dev/null | awk -F_ '{print $NF}'`
		else
			v=`echo ${missname} | sed 's/[A-Z]\+\([0-9]\+\).*$/\1/' 2>/dev/null | awk -F_ '{print $NF}'`
		fi
		if [ Z"$v" = Z"$missname" ]
		then
			v=0
		fi
		get_product_patches
		if [ -e $rcdir/_${ppr}_${ppv}_patchlist.xhtml ]
		then
			patcnt=`jq .[] ${rcdir}/_${ppr}_${ppv}_patchlist.xhtml |grep download | sed 's/[,"]//g'|wc -l`
		fi
	fi
}

function wgetMyVersion()
{
	if [ ! -e ${rcdir}/_${choice}.xhtml ] || [ $doreset -eq 1 ]
	then
		debugvecho "DEBUG wMV: ${layer[@]}"
		nnr=$(($nr-2))
		iname=${layer[$nnr]}
		ichoice=$choice
		echo $vurl | sed 's/\&/\n/g' | sed 's/?/\n/' |grep downloadGroup| cut -d= -f2 | grep - '-' >& /dev/null
		if [ $? -eq 0 ]
		then
			iname=`echo ${layer[$nnr]} | sed 's/_/-/g'`
			ichoice=`echo $choice | sed 's/_/-/g'`
		fi
		vurl=`echo $vurl | sed "s/$iname/$ichoice/"`
		mywget ${rcdir}/_${choice}.xhtml https://my.vmware.com${vurl}
		missname=$choice
	fi
}

function getMyFiles()
{
	sc=$1
	# get the files
	getTabcOne $choice
	# need to swing through xpkgs for exist vs not
	pkgs="$xpkgs"
	writeJSON
	if [ $sc -eq 0 ]
	then
		colorMyPkgs "$xpkgs" 0
		pkgs="All ${npkg[@]}"
	fi

	##
	# OEM/DTS/Patches - only perform if options set
	if [ $mydts -eq 1 ]
	then
		dtslist=(`xmllint --html --xpath "(//div[@class=\"tabContent\"])[2]" $rcdir/_${choice}.xhtml 2>/dev/null | grep downloadGroup | grep -v OSS  | cut -d\? -f 2 | cut -d \& -f 1 | cut -d= -f 2 | sed 's/-/_/g'`)
		if [ ${#dtslist[@]} -gt 0 ] && [ $sc -eq 0 ]
		then
			pkgs="$pkgs DriversTools"
		fi
	fi
	if [ $myoem -eq 1 ]
	then
		oemlist=(`xmllint --html --xpath "(//div[@class=\"tabContent\"])[4]" $rcdir/_${choice}.xhtml 2>/dev/null | grep downloadGroup | grep -v OSS  | cut -d\? -f 2 | cut -d \& -f 1 | cut -d= -f 2 | sed 's/-/_/g'`)
		if [ ${#oemlist[@]} -gt 0 ] && [ $sc -eq 0 ]
		then
			pkgs="$pkgs CustomIso"
		fi
	fi
	getMyPatches
	if [ $patcnt -gt 0 ]
	then
		pkgs="$pkgs Patches"
	fi
}

specNnr=0
specMissname=''
prevNr=0
function getLayerPkgs()
{
	dojq=0
	infiles=0
	layers=''
	mark=''
	if [ $debugv -eq 1 ]
	then
		echo "DEBUG gLP: ${layer[@]} $prevNr"
	fi
	prevNr=$nr
	nr=${#layer[@]}
	if [ $nr -lt 4 ]
	then
		dojq=1
		for x in ${layer[@]}
		do
			if [ Z"$x" = Z"actions" ]
			then
				dojq=2
			fi
			layers="${layers}.${x}"
		done
	else
		dojq=3
	fi
	if [ $dojq -eq 1 ]
	then
		pkgs=`jq "${layers}" $rcdir/_j_downloads.xhtml | sed 's/ /_/g'|sed 's/"//g'`
	elif [ $dojq -eq 2 ]
	then
		getMyVersions
	elif [ $dojq -eq 3 ]
	then
		if [ $nr -eq 4 ]
		then
			getMySuites
		elif [ $nr -eq 5 ]
		then
			if [ $nr -lt $prevNr ] # backwards
			then
				specReply=$specNnr
			fi
			debugecho "DEBUG: $nr $prevNr $specNnr"
			getMyDlgs
			specNnr=$specReply
		elif [ $nr -eq 6 ]
		then
				debugecho "DEBUG: $nr $prevNr $specNnr"
				getMyDlgVersions 0
				# no versions or not historical
				if [ Z"$tver" = Z"" ] || [ $historical -ne 1 ]
				then
					infiles=1
					getMyFiles 0
				fi
		elif [ $nr -eq 7 ]
		then
			# File missing, so get data, went down then back up
			if [ $historical -eq 1 ]
			then
				wgetMyVersion
			fi
			infiles=1
			getMyFiles 0
		fi
	fi
}

pName=''
function createMenu()
{
	##
	# TODO:
	# if grey nothing is selectable just viewable active buttons are Exit/Back
	##
	if [ ${#pkgs} -ne 0 ]
	then
		if [ Z"$pkgs" = Z"All " ]; then pkgs=''; fi # Nothing so Drop the All!
		old_lr=$longReply
		if [ Z"$choice" != Z"Back" ] || [ Z"$choice" != Z"Mark" ] || [ Z"$choice" != Z"All" ]
		then
			old_choice=$choice
		fi
		debugvecho "DEBUG cM: ${layer[@]}"
		back=""
		if [ ${#layer[@]} -gt 2 ]
		then
			back="Back"
		fi
		export COLUMNS=8
		select choice in $pkgs $mark $back Exit
		do
			longReply=$REPLY
			if [ Z"$choice" != Z"" ]
			then
				## needed if we allow
				stripcolor
				if [ $choice = "Exit" ]
				then
					exit
				elif [ $choice = "Mark" ]
				then
					favorite="${pName}_${layer[4]}"
					colorecho "Favorite: $favorite"
					save_vsmrc
					continue
				fi
				if [ $nr -eq 2 ]
				then
					pName=`echo $choice|sed 's/&_//g'`
				fi
				break
			else
				echo -n "Please enter a valid numeric number:"
			fi
		done
	else
		longReply=1 # use this value for follow on elements
	fi
}

function processCode() 
{
	##
	# This extracts the 'parameters' we can use to perform a download
	theHref=${tdls[$xloc]}
	isdlurl=0
	#echo "PC: $theHref"
	code=(`echo $theHref | sed 's/"/\n/g' | egrep 'getDownload|checkEulaAndPerform' | head -1 | cut -d\( -f 2 | cut -d\) -f 1 | sed "s/'//g" | sed 's/,/ /g' | sed 's/  / /g'`)
	if [ ${#code[@]} -ne 0 ]
	then
		downloadGroup=${code[0]}
		fileId=${code[1]}
		vmware='downloadBinary'
		baseStr=${code[2]}
		secureParam=${code[3]}
		if [ ${#code[@]} -eq 7 ]
		then
			# checkEulaAccepted
			isEulaA='true'
			tagId=${code[4]}
			productId=${code[5]}
			uuId=${code[6]}
		else
			# getDownload
			isEulaA=${code[4]}
			tagId=${code[5]}
			productId=${code[6]}
			uuId=${code[7]}
		fi
	else
		# expand URL 
		echo $theHref | grep ^http >& /dev/null
		if [ $? -eq 0 ]
		then
			isdlurl=1
			theHref=`echo "$theHref" | sed 's/"/" /' | sed 's/^/url="/'`
		fi
		if [ Z"$theHref" != Z"#\"" ]
		then
			for nx in `echo $theHref | sed 's/^\.//' | sed 's#/group/vmware/details##'`; do t=`echo $nx| cut -d= -f1`; s=`echo $nx| cut -d= -f2-`; eval "$t=$s"; done
		fi
	fi
	# createURL
	dlURL=`grep downloadFilesURL $rcdir/_${missname}.xhtml|cut -d\" -f6`
	if [ Z"$dlURL" != Z"" ] && [ Z"$theHref" != Z"#\"" ] && [ $isdlurl -eq 0 ]
	then
		url="$dlURL&downloadGroupCode=${downloadGroup}&downloadFileId=${fileId}&uuId=${uuId}&hashKey=${secureParam}&productId=${productId}"
	fi
	debugecho "DEBUG: $theHref"
	debugecho "DEBUG: $url"
}

function getSHAData()
{
	# granted md5sum is not supported
	sha256=`echo $data | sed 's/<br>/\n/g' |sed 's/<span>/\n/g'| grep SHA256SUM | cut -d: -f2 | cut -d' ' -f2`
	if [ Z"$sha256" = Z"" ]
	then
		sha256=`echo $data | sed 's/<br>/\n/g' |sed 's/<span>/\n/g'| grep SHA1SUM | cut -d: -f2 | cut -d' ' -f2`
		if [ Z"$sha256" = Z"" ]
		then
			sha256=`echo $data | sed 's/<br>/\n/g' |sed 's/<span>/\n/g'| grep MD5SUM\< | cut -d: -f2 | cut -d' ' -f2`
			if [ Z"$sha256" != Z"" ]
			then
				sha='md5sum'
			fi
		else
			sha='sha1sum'
		fi
	else
		sha='sha256sum'
	fi
}

function getVSMData()
{
	url=''
	if [ Z"$dlgroup" = Z"" ]
	then
		lr=$(($longReply-1))
		data=`xmllint --html --xpath "(//td[@class=\"filename\"])[$lr]" $rcdir/_${missname}.xhtml 2>/dev/null`
		name=`echo $data | xmllint --html --xpath '//span[@class="fileNameHolder"]/text()' - | sed 's/ //g'`
	fi
	debugecho "DEBUG: $lr $name ${xpkgs[$lr]}"
}

function doFixSymlinks()
{
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
				if [ -e $rname ]
				then
					rm ${rname}
				fi
			fi
		fi
	fi
}

function writeJSON()
{
	if [ $rebuild -eq 1 ]
	then
		if [ -e $rcdir/newlocs.json ]
		then
			newlocs=`cat $rcdir/newlocs.json`
		else
			newlocs='{"dlgList":[]}' # just in case download failed
		fi
		#echo $newlocs
		par=${layer[6]}
		if [ Z"${layer[6]}" = Z"" ]
		then
			par=${layer[5]}
		fi
		for x in $xpkgs
		do
			newlocs=`echo $newlocs|jq --arg n $x --arg t "${pName}_${layer[4]}" --arg v "$missname" --arg p "${par}" '.dlgList += [{"name": $n, "target": $t, "dlg": $v, "parent": $p}]'`
			newlocs=`echo $newlocs | jq -M '.dlgList |= unique_by(.name)'`
		done
		#echo $newlocs
		echo $newlocs > $rcdir/newlocs.json
	fi
}

function getPreUrl()
{
	xurl=$1
	# sometimes there is no preUrl
	if [ $isdlurl -eq 0 ]
	then
		lurl=`wget -O - --load-cookies $cdir/$ck --header="User-Agent: $ua" $xurl 2>&1 | grep downloadUrl | cut -d\" -f4`
	else
		lurl=$xurl
	fi
}

shavexdl=0
function downloadFile()
{
	# simplified getvsm
	dlfile=''
	shavexdl=0
	getVSMData
	if [ ${#name} -ne 0 ]
	then
		doFixSymlinks
		if [ $doprogress -eq 1 ] || [ $debugv -eq 1 ] && [ $dodlg -ne 1 ]
		then
			echo -n "."
		fi
		# move below if test fails
		getSHAData
		processCode
		if [ ! -e ${name} ] && [ ! -e ${name}.gz ] || [ $doforce -eq 1 ]
		then 
			if [ Z"$dlURL" != Z"" ]
			then
				getPreUrl $url
				if [ ${#lurl} -gt 0 ]
				then
					if [ $dryrun -eq 1 ]
					then
						echo "mywget $name $lurl '--progress=bar:force' 1"
					else
						echo "Downloading $name to `pwd`:"
						mywget $name $lurl '--progress=bar:force' 1
						if [ $err -eq 0 ]
						then
							if [ $doshacheck -eq 1 ]
							then
								shadownload=1
								shacheck_file $name
							fi
						fi
					fi
					diddownload=1
				else
					if [ $dovexxi -eq 1 ]
					then
						dlfile=`grep ${name} $rcdir/_vex_files.txt | head -1`
						if [ Z"$dlfile" != Z"" ]
						then
							vname=`basename $dlfile`
							echo "Downloading $name to `pwd`:"
							mywget $vname $vex_ref 'vacookies' 1
							# error here
							if [ $doshacheck -eq 1 ]
							then
								shadownload=1
								if [ Z"$name" != Z"$vname" ]
								then
									shavexdl=1
								fi
								shacheck_file $name
							fi
							diddownload=1
						fi
					fi
				fi
			fi
		fi
		if [ -e $name ] || [ -e ${name}.gz ] || [ $doforce -eq 1 ]
		then
			compress_file $name
			mksymlink $name
		fi
	fi
}

function getAdditionalDlg()
{
	osc=$1
	gotodir $omissname $osc $missname
	debugecho "gotodir => `pwd`"
	# may be _ or -
	x=`echo $missname | sed 's/_/[_-]/g'`
	addHref=`egrep "=${x}&" $rcdir/_${omissname}.xhtml | grep href | sed 's/"buttoncol"//'|cut -d\" -f2 | grep -v OSS`
	if [ ! -e ${rcdir}/_${missname}.xhtml ] || [ $doreset -eq 1 ]
	then
		if [ $doprogress -eq 1 ] || [ $debugv -eq 1 ] && [ $dodlg -ne 1 ]
		then
			echo -n "-"
		fi
		mywget ${rcdir}/_${missname}.xhtml https://my.vmware.com${addHref}
	fi
	getTabcOne $missname
	longReply=2
	xloc=0
	writeJSON
}

function getAdditional()
{
	sc=$2
	debugecho "DEBUG: missname=>$missname"
	debugecho "DEBUG: add=>$additionalFiles"
	if [ ${#additionalFiles} -ne 0 ]
	then
		omissname=$missname
		olongReply=$longReply
		doLurl=0
		for missname in $additionalFiles
		do
			getAdditionalDlg $sc
			for y in $xpkgs
			do
				choice=$y
				downloadFile
				if [ $doLurl -eq 0 ]
				then
					getPreUrl $url
					preUrl=$lurl
					doLurl=1
				fi
				longReply=$(($longReply+1))
				xloc=$(($xloc+1))
			done
		done
		missname=$omissname
		longReply=$olongReply
	fi
}

function uag_test() {
	if [ $_v -eq 300 ]
	then
		symdir="view"
	elif [ $_v -eq 0 ] || [ $_v -lt 321 ]
	then
		symdir="UAG_${_v:0:2}"
	else
		symdir="UAG_${_v}"
	fi
}

function getSymdir()
{
	# used for fake symlinks, mostly UAG
	symdir=''
	_v=`echo $choice | sed 's/[a-z-]\+-\([0-9]\.[0-9]\.[0-9]\).*/\1/' | sed 's/\.0$//' |sed 's/\.//g'`
	case "$choice" in
		euc-access-point*)
			uag_test $_v
			;;
		euc-unified-access*)
			uag_test $_v
			;;
		uagdeploy*)
			uag_test $_v
			;;
	esac
}

function endOfDownload()
{
	if [ $doprogress -eq 1 ] || [ $debugv -eq 1 ] && [ $dodlg -ne 1 ]
	then
		echo "!"
	fi
	eou=''
	if [ Z"$additional" != Z"base" ]
	then
		eou="/$additional"
	fi
	iou="Existing"
	if [ $diddownload -eq 1 ]
	then
		iou="New"
	fi
	colorecho "$iou $missname in $repo/dlg_${missname}${eou}"
}

function getFile()
{
	if [ Z"$choice" = Z"Patches" ]
	then
		download_patches
		endOfDownload
	elif [ Z"$choice" = Z"CustomIso" ]
	then
		additionalFiles="${oemlist[@]}"
		getAdditional $missname "CustomIso"
		nr=${#layer[@]}
		nr=$(($nr-1))
		choice=${layer[$nr]}
		endOfDownload
	elif [ Z"$choice" = Z"DriversTools" ]
	then
		additionalFiles="${dtslist[@]}"
		getAdditional $missname "DriversTools"
		nr=${#layer[@]}
		nr=$(($nr-1))
		choice=${layer[$nr]}
		endOfDownload
	else
		getSymdir
		gotodir $missname "base"
		downloadFile
		nr=${#layer[@]}
		nr=$(($nr-1))
		choice=${layer[$nr]}
		symdir=''
	fi
}

function getAllChoice()
{
	mpkgs=$xpkgs
	#if [ $dovexxi -eq 1 ]
	#then
	#	if [ ${#dtslist[@]} -gt 0 ]
	#	then
	#		diddownload=0
	#		additionalFiles="${dtslist[@]}"
	#		getAdditional $missname "DriversTools"
	#		endOfDownload
	#	fi
	#fi
	additional='base'
	diddownload=0
	longReply=2
	xloc=0
	for x in $mpkgs
	do
		choice=$x
		getFile
		longReply=$(($longReply+1))
		xloc=$(($xloc+1))
	done
	endOfDownload
	if [ ${#oemlist[@]} -gt 0 ]
	then
		diddownload=0
		additionalFiles="${oemlist[@]}"
		getAdditional $missname "CustomIso"
		endOfDownload
	fi
	#if [ $dovexxi -eq 0 ]
	#then
		if [ ${#dtslist[@]} -gt 0 ]
		then
			diddownload=0
			additionalFiles="${dtslist[@]}"
			getAdditional $missname "DriversTools"
			endOfDownload
		fi
	#fi
	getMyPatches
	if [ $patcnt -gt 0 ]
	then
		diddownload=0
		download_patches
	fi
}

function getAll()
{
	old_sr=$specReply
	old_lr=$longReply
	# This depends on where we are
	if [ $nr -ge 6 ]
	then
		getAllChoice
		longReply=$old_lr
	elif [ $nr -eq 5 ]
	then
		tpkgs="$xpkgs"
		#specReply=$longReply # packages always listed here
		for x in $tpkgs
		do
			tdls=()
			choice=$x
			missname=$x
			getMyDlgVersions 1
			getMyFiles 1
			getAllChoice
		done
		longReply=$old_sr
	fi
	choice=$old_choice
	specReply=$old_sr
}

function getFavPaths()
{
	# path version Grouping
	favpaths=(`echo $favorite | sed 's/\([a-z_]\+\)_\([0-9]\+_[0-9x]\+\|[0-9]\+\)_\(.*\)/\1 \2 \3/i'`)
	# Get First Path Entry (productCategory)
	pc=-1
	for x in `jq ".productCategoryList[].name" _j_downloads.xhtml|sed 's/ /_/g'`
	do
		# reverse grep
		pc=$(($pc+1))
		y=`echo $x|sed 's/_&_/.*/g'|sed 's/[_-]/./g'|sed 's/"//g'`
		z=`echo ${favpaths[0]}|egrep -in $y 2>/dev/null`
		if [ $? -eq 0 ]
		then
			prodCat=(`echo $z | sed 's/:/ /'`)
			pName=`echo ${y}|sed 's/\.\*/_/g'|sed 's/\./_/g'|sed 's/_\+/_/g'`
			break
		fi
	done
	if [ $pc -ge 0 ]
	then
		#pc=$(($pc-1))
		shortPro=`echo ${prodCat[1]}|sed "s/${y}_//" |sed 's/[_-]/./g'`
		# Get Second path entry (proList)
		proList=(`jq ".productCategoryList[$pc].proList[].name" _j_downloads.xhtml | grep -in "${shortPro}\"" | sed 's/:/ /'`)
		lr=${proList[0]}
		# build up front layers
		if [ $lr -gt 0 ]
		then
			lr=$(($lr-1))
			layer=("productCategoryList[$pc]")
			layer+=("proList[$lr]")
			layer+=("actions")
			missname=`echo $shortPro | sed 's/\./_/g'`
			choice=$missname
			getLayerPkgs
			layer=("productCategoryList[$pc]")
			layer+=("proList[$lr]")
			layer+=("$missname")
			choice=${missname}_${favpaths[1]}
			layer+=("$choice")
			longReply=`echo $tver|sed 's/ /\n/g'|grep -in ${favpaths[1]} |cut -d: -f1`
			longReply=$(($longReply-1))
			getLayerPkgs
			t_mversions=("$mversions")
			longReply=`echo $mversions|sed 's/ /\n/g'| grep -in ${favpaths[2]} |head -1|cut -d: -f1`
			if [ ${#t_mversions[@]} -gt 1 ]
			then
				longReply=$(($longReply-1))
			fi
			choice=${missname}_${favpaths[2]}
			layer+=("$choice")
			getLayerPkgs
			longReply=0
		fi
	fi
}

function getDlgFile()
{
	longReply=`echo $xpkgs | sed 's/ /\n/g' |grep -n ${dlgInfo[0]}|cut -d: -f1`
	choice="${dlgInfo[0]}" # filename to get
	xloc=$(($longReply-1))
	longReply=$(($longReply+1))
	downloadFile
}

function getDlg()
{
	doColor=0
	mydts=1
	myoem=1
	# Get first item into array
	dlgInfo=(`jq --arg s "$mydlg" '[.dlgList[] | select(.name | test($s))][0]|.name,.target,.dlg,.parent' $rcdir/newlocs.json | sed 's/"//g'`)
	favorite=${dlgInfo[1]}
	getFavPaths
	pkg=`echo ${dlgInfo[3]}|awk -F[0-9] '{print $1}'`
	lchoice=(`echo $pkgs |sed 's/ /\n/g' | egrep -n "^${pkg}"|sed 's/:/ /'`)
	missname=${lchoice[1]}
	choice=$missname
	longreply=${lchoice[0]}
	getMyDlgVersions 1
	getMyFiles 1
	createLayer
	nr=${#layer[@]}
	# now is it in this layer or 'additional'
	if [ $choice != ${dlgInfo[3]} ]
	then
		choice=${dlgInfo[3]}
		createLayer
		nr=${#layer[@]}
		missname=${choice}
		wgetMyVersion
		getMyFiles 1
	fi
	if [[ "$xpkgs" == *"${dlgInfo[0]}"* ]]
	then
		getDlgFile
	elif [[ ${dtslist[@]} == *"${dlgInfo[2]}"* ]] 
	then
		omissname=$missname
		missname=${dlgInfo[2]}
		getAdditionalDlg DriversTools
		getDlgFile
	elif [[ ${oemlist[@]} == *"${dlgInfo[2]}"* ]]
	then
		omissname=$missname
		missname=${dlgInfo[2]}
		getAdditionalDlg CustomIso
		getDlgFile
	fi
}

function getTheFiles()
{
	xloc=$(($longReply-2))
	getFile
}

# handle favorite case
if [ $myfav -ge 1 ]
then
	if [ $myfav -eq 2 ]
	then
		favorite=$fav
	fi
	rebuild=0
	getFavPaths
	getAll
	exit
fi

if [ $dodlg -eq 1 ]
then
	if [ ! -e $rcdir/newlocs.json ]
	then
		getJSON
	fi
	if [ -e $rcdir/newlocs.json ]
	then
		rebuild=0
		getDlg
		endOfDownload
		# needed for aac-base scripts
		echo "Local:$repo/dlg_${dlgInfo[3]}${eou}/$name"
	fi
	exit
fi

if [ Z"$dlgroup" != Z"" ] && [ $dovexxi -eq 1 ]
then
	# limited to JUST the download group, no Additional/CustomISO, etc.
	choice=$dlgroup
	mywget ${rcdir}/_${choice}.xhtml https://my.vmware.com/group/vmware/get-download?downloadGroup=$choice
	missname=${choice}
	getSymdir
	gotodir ${choice} "base"
	xpkgs=`grep textBlack ${rcdir}/_${choice}.xhtml | xmllint --html --xpath 'string(//strong)' - 2>/dev/null| awk '{print $1}'`
	count=1
	for x in $xpkgs
	do
		((count++))
		data=`xmllint --html --xpath "//div[@id=\"content_21\"]//tr[$count]" ${rcdir}/_${choice}.xhtml 2>/dev/null`
		infoText=`echo "$data" | xmllint --html --xpath '//td[@class="info_Text"]/text()' - 2>/dev/null`
		if [ Z"$infoText" != Z"" ]
		then
			name=$x
			xloc=0
			tdls=(`echo "$data" | xmllint --html --xpath '//a[@class="md"]' - 2>/dev/null | sed 's/<a/\n<a/g' | grep md | sed 's/<a//' | sed 's/class="md"//' | sed 's/ //g' | cut -d\" -f2- | cut -d\> -f1|sed "s/''/#/g"`)
			downloadFile
		fi
	done
	exit
fi

doColor=1
infiles=0
# standard loop
while [ 1 ]
do
	getLayerPkgs
	createMenu
	if [ Z"$choice" = Z"All" ]
	then
		longReply=$(($longReply+1)) # All is #1 but -1 is used else where
		getAll	# special case, All is 'several' places
	elif [ Z"$choice" = Z"Back" ]
	then
		removeLayer
	elif [ Z"$choice" = Z"DriversTools" ] || [ Z"$choice" = Z"CustomIso" ] || [ Z"$choice" = Z"Patches" ]
	then
		getTheFiles
	elif [[ $nr -eq 6 && ( $historical -eq 0 ||  $infiles -eq 1 ) ]]
	then 
		getTheFiles
	elif [ $nr -eq 7 ] 
	then
		getTheFiles
	else
		createLayer
	fi
done
