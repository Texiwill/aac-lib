#!/bin/bash
# vim: set tabstop=4 shiftwidth=4:
#
# Copyright (c) AstroArch Consulting, Inc.  2017-2023
# All rights reserved
#
# A Linux version of VMware Software Manager (VSM) with some added intelligence
# the intelligence is around what to download and picking up things
# available but not strictly listed, as well as bypassing packages not
# created yet
#
# Requires:
# wget python python-urllib3 libxml2 ncurses bc nodejs Xvfb
#

VERSIONID="6.8.0"

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
	ua='Mozilla/5.0 (X11; Fedora; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.75 Safari/537.36'
	ck='cookies.txt'
	if [ -e $cdir/ocookies.txt ] && [ $myoauth -eq 1 ]
	then
		debugecho "Ocookies"
		ua=$oaua
		ck='ocookies.txt'
	fi
	#if [ -e $cdir/pcookies.txt ] && [ $myoauth -eq 1 ]
	#then
	#	debugecho "Pcookies"
	#	ua=$oaua
	#	ck='pcookies.txt'
	#fi
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
	#if [ Z"$hd" = Z"pcookies" ]
	#then
	#	debugecho "Real Pcookies"
	#	ua=$oaua
	#	ck='pcookies.txt'
	#	hd="--progress=bar:force --header='Referer: $mypatch_ref'" 
	#	newck=1
	#fi
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
					if [ Z"$hd" = Z"xhr" ]
					then
						wget $_PROGRESS_OPT $cc --progress=bar:force --header="Referer: $4" --load-cookies $cdir/$ck --header="User-Agent: $ua" $ou $hr 2>&1 | progressfilt 
						err=${PIPESTATUS[0]}
					else
						wget $_PROGRESS_OPT $cc --progress=bar:force $hd --load-cookies $cdir/$ck --header="User-Agent: $ua" $ou $hr 2>&1 | progressfilt 
						err=${PIPESTATUS[0]}
					fi
				else
					if [ Z"$hd" = Z"xhr" ]
					then
						wget $_PROGRESS_OPT $cc --progress=bar:force --header="Referer: $4" --save-cookies $cdir/new.txt --load-cookies $cdir/$ck --header="User-Agent: $ua" $ou $hr
						err=$?
					else
						wget $_PROGRESS_OPT $cc --progress=bar:force $hd --save-cookies $cdir/new.txt --load-cookies $cdir/$ck --header="User-Agent: $ua" $ou $hr
						err=$?
					fi
				fi
			else
				if [ Z"$hd" = Z"xhr" ]
				then
					wget $_PROGRESS_OPT $cc --header="Referer: $4" --save-cookies $cdir/new.txt --load-cookies $cdir/$ck --header="User-Agent: $ua" $ou $hr >& /dev/null
					err=$?
				else
					wget $_PROGRESS_OPT $hd $cc --save-cookies $cdir/new.txt --load-cookies $cdir/$ck --header="User-Agent: $ua" $ou $hr >& /dev/null
					err=$?
				fi
			fi
			#if [ $doprogress -eq 1 ]
			#then
			#	echo -n "+"
			#fi
		else
			if [ Z"$hd" = Z"xhr" ]
			then
				wget $_PROGRESS_OPT $cc --header="Referer: $4" --progress=bar:force --save-cookies $cdir/new.txt --load-cookies $cdir/$ck --header="User-Agent: $ua" $ou $hr # 2>&1 | progressfilt
				err=$?
			else
				wget $_PROGRESS_OPT $hd $cc --progress=bar:force --save-cookies $cdir/new.txt --load-cookies $cdir/$ck --header="User-Agent: $ua" $ou $hr # 2>&1 | progressfilt
				err=$?
			fi
		fi
		if [ $err -ne 0 ]
		then
			# for timers downloads mean clock starts over
			touch  $cdir/$ck
		fi
	fi
	if [ $newck -eq 0 ] && [ $err -ne 0 ]
	then
		wgeterror $err $fname
	fi
}

function getJSON()
{
	if [ ! -e $rcdir/newlocs.json ] || [ $rebuild -eq 1 ]
	then
		wget -O $rcdir/newlocs.json https://raw.githubusercontent.com/Texiwill/aac-lib/master/vsm/newlocs.json >& /dev/null
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
			echo "dopatch=$dopatch" >> $vsmrc
			echo "dovexxi=$dovexxi" >> $vsmrc
			echo "historical=$historical" >> $vsmrc
			echo "compress=$compress" >> $vsmrc
			echo "symlink=$symlink" >> $vsmrc
			echo "olde=$olde" >> $vsmrc
			echo "retrycount=$retrycount" >> $vsmrc
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
	if [ ! -e $rcdir/_patch_versions.xhtml ]
	then
		# Patch List
		wget $_PROGRESS_OPT -O $rcdir/_patch_versions.xhtml --cookies=on --load-cookies $cdir/ocookies.txt --keep-session-cookies --header="User-Agent: $oaua" --header="Referer: $mypatch_ref" $mypatch_versions >& /dev/null
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
		rd=(`$python -c "import urllib, sys; print urllib.quote(sys.argv[1])" "$vex_auth" 2>/dev/null|sed 's/%3A/ /'`)
		vd="csrf_token="$csrf_token"&login_email=${rd[0]}&login_password=${rd[1]}"
		wget -O $cdir/vex_auth.html $_PROGRESS_OPT --no-check-certificate --post-data="$vd" --save-headers --cookies=on --load-cookies $cdir/vcookies.txt --save-cookies $cdir/vacookies.txt --keep-session-cookies --header="User-Agent: $oaua" --header="Referer: $vex_login" $vex_login >& /dev/null #| grep AUTH-ERR >& /dev/null
		grep 'Error' $cdir/vex_auth.html >& /dev/null
       	vex_err=$?
		if [ $vex_err -eq 0 ]
		then
			colorecho "Incorrect vExpert Credentials" 0
			rm -rf ${cdir}/bm.txt >& /dev/null
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

#need_login=0
function oauth_login() {
	dl=$1
	z=`date +"%s"`
	test_login=$(($z-$need_login))
	debugecho "OL: $test_login $need_login"
	if [ $test_login -ge 900 ]
	then
		if [ $noheader -eq 0 ]; then colorecho "	Authenticating... May take up to 90s... 12-20s is normal...  "; fi
		need_login=$z
		# Get creds
		#oauth=`echo $auth | base64 --decode`
		#rd=(`$python -c "import urllib, sys; print urllib.quote(sys.argv[1])" "$oauth" 2>/dev/null|sed 's/%3A/ /'`)
		#pd="username=${rd[0]}&password=${rd[1]}"
		# does node exist?
		pushd ${cdir} >& /dev/null
		if [ $renodejs -eq 1 ]
		then
			rm -rf ${cdir}/node-bm.js ${cdir}/node_modules
		fi
		if [ ! -e ${cdir}/node_modules ]
		then
			colorecho "	Installing necessary modules"
			npm install inquirer@8.2.3 puppeteer@14.3.0 puppeteer-extra puppeteer-extra-plugin-stealth --unsafe-perm=true >& /dev/null
			if [ $? -eq 1 ]
			then
				colorecho "	Not enough space in $cdir; please add more" 1
				exit
			fi
			npm install xvfb --unsafe-perm=true >& /dev/null
			if [ $? -eq 1 ]
			then
				colorecho "	Error installing nodejs xvfb, please verify C++ compiler exists" 1
				exit
			fi
			colorecho "	Finished installing necessary modules"
		fi
		if [ ! -e ${cdir}/node-bm.js ]
		then
			cat >> $cdir/node-bm.js << EOF
const os = require('os');
const inquirer = require('inquirer');
const puppeteer = require('puppeteer-extra');
const fs = require('fs').promises;
const Xvfb = require('xvfb');
process.on('unhandledRejection', function(err) {
	console.log(err);
	process.exit(1);
});
function delay(time) {
   return new Promise(function(resolve) { 
       setTimeout(resolve, time)
   });
}
const StealthPlugin = require('puppeteer-extra-plugin-stealth');
const stealth = StealthPlugin();
puppeteer.use(stealth);
const platform=os.platform();
var data='${auth}';
let buff = new Buffer.from(data,'base64');
let text = buff.toString('ascii');
var mfa=true;
const words = text.split(':');
(async () => {
	var browser;
	if (platform != 'darwin') {
		var xvfb = new Xvfb({
			silent: true,
			xvfb_args: ["-screen", "0", '1280x1024x24', '-ac'],
		});
		xvfb.start((err)=>{if (err) {console.error(err); process.exit(1);}})
		browser = await puppeteer.launch({
			headless: false,
			defaultViewport: null,
			args: ['--no-sandbox', '--remote-debugging-port=9222','--start-fullscreen', '--display='+xvfb._display]
		});
	} else {
		browser = await puppeteer.launch({
				headless: false,
				defaultViewport: {width: 100,height: 100},
				args: ['--no-sandbox', '--window-size=50,50',
				'--disable-background-timer-throttling',
				'--disable-backgrounding-occluded-windows',
				'--disable-renderer-backgrounding',
				'--window-position=-500,0'
				]
		});
	}
	const page = await browser.newPage();
	await page.goto('https://customerconnect.vmware.com/web/vmware/login',{waitUntil: 'networkidle0'});
	const navigationPromise = page.waitForNavigation();
	await page.type('#email',words[0]);
	await page.type('#password',words[1]);
	await page.keyboard.press('Enter');
	await navigationPromise;
	try {
		await page.waitForSelector('#passcode-visible',{timeout: 1000});
		const answer = await inquirer.prompt([{
			type: 'input',
			name: 'passCode',
			message: 'Enter MFA pass code: '
		}]);
		await page.type('#passcode-visible',answer.passCode);
		await page.keyboard.press('Enter');
	} catch (error) {
		mfa=false;
	}
	await page.waitForSelector('.ng-star-inserted',{timeout: 90000});
	await page.goto('https://customerconnect.vmware.com/patch',{waitUntil: 'networkidle0'});
	await page.waitForSelector('.patchSearch',{timeout: 90000});
	const { cookies } = await page._client.send('Network.getAllCookies');
	var cookieContent=\`# HTTP cookie file.
# Generated for Wget
# Edit at your own risk.

\`;
	for (let cookie of cookies.values()) {
		var string = "";
		string += cookie.domain + '\t';
        //if (string.includes('vmware')) {
			string = string.replace(/^\./,'');
			string +=  String(cookie.session).toUpperCase() + '\t';
			string +=  cookie.path + '\t';
			string +=  String(cookie.secure).toUpperCase() + '\t';
			if (cookie.expires == -1) {
				string +=  "0" + '\t';
			} else {
				string +=  cookie.expires + '\t';
			}	
			string +=  cookie.name + '\t';
			string +=  cookie.value;
			cookieContent += string.trim() + '\n';
		//}
	}
	await fs.writeFile('./ocookies.txt',cookieContent);
	await browser.close()
	if (platform != 'darwin') {
		xvfb.stop();
	}
})();
EOF
			chmod -R 600 node-bm.js
			chmod 700 node_modules
		fi
		# just to be sure
		rm $cdir/bm.txt >& /dev/null
		node node-bm.js 2>&1 |tee $cdir/bm.txt
		grep .ng-star-inserted $cdir/bm.txt >& /dev/null
		if [ $? -eq 0 ]
		then
			colorecho "	Login Failure Bad or Missing Credential" 1
			pkill -9 Xvfb
			rm $cdir/bm.txt >& /dev/null
			if [ $debugv -eq 0 ]
			then
				rm node-bm.js
			fi
			exit
		fi
		grep Navigation $cdir/bm.txt >& /dev/null
		if [ $? -eq 0 ]
		then
			colorecho "	DNS or WSL1 issue? Unable to reach My VMware" 1
			pkill -9 Xvfb
			rm $cdir/bm.txt >& /dev/null
			if [ $debugv -eq 0 ]
			then
				rm node-bm.js
			fi
			exit
		fi
		egrep 'Cannot find module|loading shared libraries' $cdir/bm.txt >& /dev/null
		if [ $? -eq 0 ]
		then
			colorecho "	Installation Issue, run vsm.sh --clean" 1
			colorecho "	if problem continues reinstall using install.sh" 1
			rm $cdir/bm.txt >& /dev/null
			pkill -9 Xvfb
			if [ $debugv -eq 0 ]
			then
				rm node-bm.js
			fi
			exit
		fi
		popd >& /dev/null
	fi
	#rm $cdir/bm.txt >& /dev/null

	# recheck, just in case
	grep OAMAuthnCookie $cdir/ocookies.txt >& /dev/null
	oauth_err=$?

	#if [ $dopatch -eq 1 ] && [ $dovexxi -eq 1 ]
	#then
	#	get_patch_url # get the url for patches
	#fi
}

function background_oauth() {
	sleep 901
	oauth_login 0
}

function get_product_patches() {
	ppr=`echo $missname | sed 's/\([A-Z]\+\)[0-9][0-9A-Z]\+/\1/'`
	# TODO: Expand to all listed patches!
	if [ Z"$ppr" = Z"ESXI" ] || [ Z"$ppr" = Z"VC" ]
	then
		oauth_login 0
		# may need ##U# to translate to ### for VC
		ppv=`echo $v | sed 's/.\{1\}/&./g' | sed 's/\.$//'`
		# Now use the API
		get_patch_list  # call just in case
		xsrf=`grep -i xsrf-token $cdir/$ck|cut -f7`
		# create payload
		pson=`jq --arg s "$ppr" '.prodList[] | select(.productName|test($s; "i"))' $rcdir/_patch_versions.xhtml`
		p_pid=`echo $pson | jq ".productId"`
		p_name=`echo $pson | jq ".productName"`
		vson=`echo $pson | jq --arg v "^$ppv" '.versions[]|select(.versionName|test($v))'`
		# making an assumption we only want the last one
		v_id=`echo $vson|jq '.versionId'|head -1`
		v_name=`echo $vson|jq '.versionName'|head -1`
		rType=`echo $vson|jq '.resultType'|head -1`
		p_payload="{\"productId\":$p_pid,\"productName\":$p_name,\"versionId\":$v_id,\"versionName\":$v_name,\"releaseDate\":null,\"severity5x\":\"\",\"severity\":\"\",\"category\":\"\",\"classification\":\"\",\"releaseName\":null,\"buildNumber\":null,\"bulletinNumber\":null,\"resultType\":$rType,\"includeDependencies\":true}"
		p_cl=`echo -n $p_payload | wc -c`
		# filename is different than search name for some
		if [ ${#ppv} -eq 3 ]
		then
			ppv="${ppv}.0"
		fi
		wget -O $rcdir/_${ppr}_${ppv}_patchlist.xhtml --load-cookies $cdir/$ck --post-data="$p_payload" --header="Referer: $mypatch_ref" --header="Content-length: $p_cl" --header="Content-Type: application/json" --header="User-Agent: $ua" --header="X-XSRF-TOKEN: $xsrf" $mypatch_search >& /dev/null
	else
		debugecho "Cannot get patches for $ppr"
	fi
}

function getPatchArrays() {
	darr=(`jq ".patchResult[]|.downloadUrl" ${rcdir}/_${ppr}_${ppv}_patchlist.xhtml|sed 's/"//g'`)
	shah=(`jq ".patchResult[]|.sha1Checksum" ${rcdir}/_${ppr}_${ppv}_patchlist.xhtml|sed 's/"//g'`)
	if [ ${darr[0]} = "null" ]
	then
		darr=(`jq ".patchResult[]|.files[]|.downloadUrl" ${rcdir}/_${ppr}_${ppv}_patchlist.xhtml|sed 's/"//g'`)
		shah=(`jq ".patchResult[]|.files[]|.sha1checksum" ${rcdir}/_${ppr}_${ppv}_patchlist.xhtml|sed 's/"//g'`)
	fi
}

function downloadPatches() {
	ospecname=$specname
	omissname=$missname
	olongReply=$longReply
	if [ $dopatch -eq 1 ] && [ $dovexxi -eq 1 ]
	then
		ppr=`echo $missname | sed 's/\([A-Z]\+\)[0-9][0-9A-Z]\+/\1/'`
		if [ Z"$ppr" = Z"ESXI" ] || [ Z"$ppr" = Z"VC" ]
		then
			ppv=`echo $v | sed 's/.\{1\}/&./g' | sed 's/\.$//'`
			if [ ${#ppv} -eq 3 ]
			then
				ppv="${ppv}.0"
			fi
			if [ -e $rcdir/_${ppr}_${ppv}_patchlist.xhtml ]
			then
				gotodir $missname "Patches" ${ppr}${ppv}
				
				# Download links as array
				#jq .[] ${rcdir}/${prod}_patchlist.xhtml |grep download
				d=0
				sha='sha1sum'
				getPatchArrays
				for px in ${darr[@]}
				do
					# this causes a 'break'
					# need to restart downloadPatches
					oauth_login 1
					if [ $doprogress -eq 1 ] || [ $debugv -eq 1 ]
					then
						if [ $shaVerify -eq 0 ]
						then
							echo -n "."
						fi
					fi
					py=`echo $px | cut -d\? -f 1`
					f=`basename $py`
					name=$f
					sha256=${shah[$d]}
					shaForce=0
					if [ $shaVerify -eq 1 ]
					then
						# Hash data comes from elsewhere
						# Upgrade Hash History
						grep $name  $repo/.hashHistory >& /dev/null
						if [ $? -ne 0 ]
						then
							echo "$sha	$sha256	$name" >> $repo/.hashHistory
						fi
						# Verify Hash
						verifyHash $name $sha $sha256
					fi
					if  [ ! -e ${name} ] && [ ! -e ${name}.gz ] || [ $doforce -eq 1 ] || [ $shaForce -eq 1 ]
					then
						#echo `pwd` $name
						if [ $doprogress -eq 1 ] || [ $debugv -eq 1 ]
						then
							if [ $shaVerify -eq 0 ]
							then
								echo -n "p"
							fi
						fi
						# just in case we are not at beginning of line
						echo ""
						echo "Downloading $name to `pwd`:"
						retries=1
						err=0
						mywget $name "$px" '--progress=bar:force' 1
						oname=$name
						while [ $err -eq 8 ]
						do
							# need to redownload the patch list
							get_product_patches
							getPatchArrays
							px=${darr[$d]}
							# in the few moments, the name could have changed
							py=`echo $px | cut -d\? -f 1`
							f=`basename $py`
							name=$f
							sha256=${shah[$d]}
							# filename changed for array element, get rid of old
							if [ $oname != $name ]
							then
								rm -rf $oname
							fi
							echo -n "Continueing $retries ..."
							err=0
							oauth_login 0
							mywget $name "$px" '-c --progress=bar:force' 1
							((retries++))
							if [ $retries -gt $retrycount ]
							then
								err=9
							fi
						done
						if [ $doshacheck -eq 1 ]
						then
							shadownload=1
							#echo ${darr[$d]}
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
					if [ $shaVerify -eq 0 ]
					then
						echo "!"
					fi
				fi
				colorecho "Patches to $repo/dlg_${missname}/Patches"
				cd ${cdir}/depot.vmware.com/PROD/channel
			fi
		fi
	fi
	specname=$ospecname
	missname=$omissname
	longReply=$olongReply
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
		#additional="Additional"
		additional=$nestdir
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

	vtdir=`echo $ldir | sed 's/\([A-Z]\+\)[0-9x]\+/\1/'`

	# do not make for Additional
	if [ Z"$additional" != Z"base" ] && [ Z"$additional" != Z"Additional" ] && [ Z"$vtdir" != Z"VMTOOLS" ]
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
		if [ ! -e dlg_$tdir ] || [ Z"$nestdir" != Z"" ]
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
		if [ -e ${fn}.gz ]
		then
			fn=${fn}.gz
		fi
		if  [ ! -e ${rdir}/${fn} ] && [ -e $fn ]
		then 
			echo -n "$fn: symlink "
			if [ Z"$additional" = Z"Additional" ] || [ Z"$vtdir" = Z"VMTOOLS" ]
			then
				ln -s ../$additional/dlg_$tdir/$fn $rdir
				if [ $? -eq 1 ]
				then
					rm $rdir/$fn
					ln -s ../$additional/dlg_$tdir/$fn $rdir
				fi
			else
				ln -s ../../$additional/dlg_$tdir/$fn $rdir
				if [ $? -eq 1 ]
				then
					rm $rdir/$fn
					ln -s ../../$additional/dlg_$tdir/$fn $rdir
				fi
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
	use_pager="`which more` -e"
	if [ Z"$PAGER" != Z"" ]
	then
		use_pager=$PAGER
	fi

	cat << EOF | $use_pager
LinuxVSM $VERSIONID Help
$0 [-c|--check] [--clean] [--dlg search] [--dlgl search] [-d|--dryrun] [-f|--force] [--fav favorite] [--favorite] [--fixsymlink] [-e|--exit] [-h|--help] [--historical] [-mr] [-nh|--noheader] [--nohistorical] [--nosymlink] [-nq|--noquiet] [-ns|--nostore] [-nc|--nocolor] [--dts|--nodts] [--oem|--nooem] [--oss|--nooss] [--oauth] [-p|--password password] [--progress] [-q|--quiet] [--rebuild] [--symlink] [-u|--username username] [-v|--vsmdir VSMDirectory] [-V|--version] [--verify] [--veriforce] [-y] [-z] [--debug] [--repo repopath] [--save] [--olde 12]
	-c|--check - do sha256 check against download
	--clean - remove all temporary files and exit
	--dlg - download specific package by name or part of name (regex)
	--dlgl - list all packages by name or part of name (regex)
	-d|--dryrun - dryrun, do not download
	-f|--force - force download of packages
	--fav favorite - specify favorite on command line
	--favorite - download suite marked as favorite
	--fixsymlink - convert old repo to symlink based repo
	-e|--exit - reset and exit
	-h|--help - this help
	-mr - remove temporary files
	--historical - display older versions when you select a package
	--nohistorical - disable --historical
    --nested - download nested ESXi images
	-nh|--noheader - leave off the header bits
	-nq|--noquiet - disable quiet mode
	-ns|--nostore - do not store credential data and remove if exists
	-nc|--nocolor - do not output with color
    --olde # - number of hours (default 12) before -mr enforced
	-p|--password - specify password
	--progress - show progress for OEM, OSS, and DriverTools
	-q|--quiet - be less verbose
	--rebuid - rebuild/add to JSON used by --dlgl and --dlg
	--symlink - use space saving symlinks
	--nosymlink - disable --symlink mode
	-u|--username - specify username
	-v|--vsmdir path - set VSM directory - saved to configuration file
	-V|--version - version number
	-y - do not ask to continue
	-z|--compress - compress files that can be compressed
	--dts - include DriversTools in All-style downloads
		    saved to configuration file
	--nodts - do not include DriversTools in All-style downloads
		      saved to configuration file
	--oss - include OpenSource in All-style downloads
		    saved to configuration file
	--nooss - do not include OpenSource in All-style downloads
		      saved to configuration file
	--oem - include CustomIso in All-style downloads
		    saved to configuration file
	--nooem - do not include CustomIso in All-style downloads
		      saved to configuration file
	--debug - debug mode
	--retries count - number of retries to do, default is 8
	--repo path - specify path of repo
		          saved to configuration file
	--save - save settings to $HOME/.vsmrc, favorite always saved on Mark
	--verify - verify hashes of files downloaded
	--veriforce - verify hashes of files downloaded and if hash does not 
			verify then download once more

To Download the latest Perl CLI use 
	(to escape the wild cards used by the internal regex):
	./vsm.sh --dlg CLI\.\*\.x86_64.tar.gz

Use of the Mark option, marks the current product suite as the
favorite. There is only 1 favorite slot available. Favorites
can be downloaded without traversing the menus.
    To Download the latest Perl CLI use 
	(to escape the wild cards used by the internal regex):
	./vsm.sh --dlg CLI\.\*\.x86_64.tar.gz

    Use of the Mark option, marks the current product suite as the
    favorite. There is only 1 favorite slot available. Favorites
    can be downloaded without traversing the menus. To download your 
    favorite use:
	$ vsm.sh -mr -y --favorite -q --progress

    Those items that show up in Cyan are those where My VMware meta data has    
    not been downloaded yet.

    Those items that show up in Grey are those too which you are not
    entitled.

    Those items in reverse color (white on black or cyan) are those items
    not downloaded. For packages and not files, the reverse color only
    shows up if the directory is not in the repo and is not related to 
    missing files or new files.

    Caveat: Access to these downloads does not imply you are entitled
    for the material. Please see My VMware for your entitlements.

    Instead of using numbers for everything you can use the following as well:
	a or A - All
	b or B - Back
	e or E - Exit
	x or X - Exit
	q or Q - Exit
	m or M - Mark
	p or P - Patches
	r or R - redraw the menu
	d or D - Print where you are in the Menus
	/searchString - Search for string in current menu, if it exists,
			go to menu option, or list multiple options
			(case insensitive)
EOF

	exit;
}

function findos() {
	if [ -e /etc/os-release ]
	then
		. /etc/os-release
		theos=`echo $ID | tr '[:upper:]' '[:lower:]'`
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
	if [ Z"$theos" = Z"centos" ] || [ Z"$theos" = Z"redhat" ] || [ Z"$theos" = Z"fedora" ] || [ Z"$theos" = Z"photon" ]
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
			$python -c "help('modules')" 2>/dev/null | grep $dep >& /dev/null
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
	elif [ Z"$theos" = Z"alpine" ]
	then
		apk -e info $dep >& /dev/null
		if [ $? -eq 1 ]
		then
			echo "Missing Dependency $dep"
			needdep=1
		fi
	elif [ Z"$theos" = Z"unknown" ]
	then
		if [ Z"$dep" = Z"libxml2" ]
		then
			# ignore
			ignore=1
		elif [ Z"$dep" = Z"python-urllib3" ]
		then
			$python -c "help('modules')" 2>/dev/null | grep urllib3 >& /dev/null
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

python="python"
function finddeps {
	#Packages required by all OS
	all_checkdep="bc jq wget"
	#Packages required by MacOS
	#macos_checkdep="$all_checkdep node python xcodebuild gnu-sed uudecode"
	macos_checkdep="$all_checkdep node python xcodebuild gnu-sed"
	#Packages required by all Linux Distros currently supported
	linux_checkdep="$all_checkdep libxml2 nodejs"
	#Packages required by Enterprise Linux and derivatives (including fedora)
	el_checkdep="ncurses xorg-x11-server-Xvfb libXScrnSaver at-spi2-atk gcc-c++ make nss gtk3"
	#Packages required by Fedora 
	fedora_checkdep="$linux_checkdep $el_checkdep python3 python3-urllib3 mesa-libgbm alsa-lib"
	#Packages required by RedHat and derivatives 
	redhat_checkdep="$linux_checkdep $el_checkdep python python-urllib3"
	redhat8_checkdep="$linux_checkdep $el_checkdep python2 python2-urllib3"
	#Packages required by Debian and derivatives 
	debian_checkdep="$linux_checkdep python python-urllib3 libxml2-utils ncurses-base xvfb libnss3 libgtk-3-0 libgbm1 libasound2 libxss1"
	ubuntu20_checkdep="$linux_checkdep python3 python3-urllib3 libxml2-utils ncurses-base xvfb libgtk-3-0 g++ libnss3 libgbm1 libxss1 make"
	#Packages required by PhotonOS
	photon_checkdep="$linux_checkdep python2 python-urllib3 xorg-server xorg-applications libXScrnSaver at-spi2-atk gtk3 make alsa-lib"
	#Packages required by Alpine
	alpine_checkdep="$linux_checkdep python3 py3-urllib3 xvfb libxscrnsaver at-spi2-atk gtk-3.0 make alsa-lib"
	if [ Z"$theos" = Z"macos" ]
	then
		. $HOME/.bash_profile
		loopdeps "$macos_checkdep"
		alias sed=gsed
		#alias uudecode="`which uudecode` -p"
		alias sha256sum="`which shasum` -a 256"
		alias sha1sum="`which shasum`"
	else
		# set language to English
		LANG=en_US.utf8
		export LANG
		#loopdeps "$linux_checkdep"
		#alias uudecode="`which uudecode` -o -"
	fi
	if [ Z"$theos" = Z"centos" ] || [ Z"$theos" = Z"redhat" ]
	then
		myver=`echo $VERSION_ID | cut -d\. -f1`
		if [ $myver -ge 8 ]
		then
			python="python2"
			loopdeps "$redhat8_checkdep"
		else
			loopdeps "$redhat_checkdep"
		fi
	elif [ Z"$theos" = Z"fedora" ]
	then
		loopdeps "$fedora_checkdep"
	elif [ Z"$theos" = Z"ubuntu" ]
	then
		myver=`echo $VERSION_ID | cut -d\. -f1`
		if [ $myver -ge 20 ]
		then
			loopdeps "$ubuntu20_checkdep"
		else
			loopdeps "$debian_checkdep"
		fi
	elif [ Z"$theos" = Z"debian" ]
	then
		myver=`echo $VERSION_ID | cut -d\. -f1`
		if [ $myver -ge 10 ]
		then
			loopdeps "$ubuntu20_checkdep"
		else
			loopdeps "$debian_checkdep"
		fi
	elif [ Z"$theos" = Z"photon" ]
	then
		loopdeps "$photon_checkdep"
	elif [ Z"$theos" = Z"alpine" ]
	then
		loopdeps "$alpine_checkdep"
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
	if [ $mon -eq 2 ] && [ $day -gt 9 ] && [ $day -lt 11 ]
	then
		ac=$((1+RANDOM % 2))
		echo `tput setaf $ac`
		cat << "EOF"
                   _    _                         
                  | |  | |                        
                  | |__| | __ _ _ __  _ __  _   _ 
                  |  __  |/ _` | '_ \| '_ \| | | |
                  | |  | | (_| | |_) | |_) | |_| |
                  |_|  |_|\__,_| .__/| .__/ \__, |
                               | |   | |     __/ |
                               |_|   |_|    |___/ 
 ______                    _           _       _____              
|  ____|                  | |         ( )     |  __ \             
| |__ ___  _   _ _ __   __| | ___ _ __|/ ___  | |  | | __ _ _   _ 
|  __/ _ \| | | | '_ \ / _` |/ _ \ '__| / __| | |  | |/ _` | | | |
| | | (_) | |_| | | | | (_| |  __/ |    \__ \ | |__| | (_| | |_| |
|_|  \___/ \__,_|_| |_|\__,_|\___|_|    |___/ |_____/ \__,_|\__, |
                                                             __/ |
                                                            |___/ 
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

function getNested()
{
	if [ ! -e ${repo}/Nested ]
	then
		mkdir -p ${repo}/Nested
	fi
	cd ${repo}/Nested
	for x in `wget -O -  http://vmwa.re/nestedesxi 2>&1 | grep '<li>' |grep nested-esxi |awk -F\" '{print $2}'`; 
	do 
		name=`basename $x` 
		if [ ! -e ${name} ] && [ ! -e ${name}.gz ] || [ $doforce -eq 1 ]
		then
			mywget $name $x
		fi
		sz=0
		if [ -e $name ]
		then
			sz=`stat $fopt $sfmt $name`
		fi
		if [ $sz -ne 0 ]
		then
			if [ -e $name ] || [ $doforce -eq 1 ]
			then
				compress_file $name
			fi
		else
			# do not save 0 file
			if [ -e $name ]
			then
				rm $name
			fi
		fi
	done
}

function getLicenses() {
	# need eval
	eval_ref="https://customerconnect.vmware.com/eval"
	eval_post='{"searchText":"","filter":"ACTIVE","sortByField":"PRODUCT_NAME","sortOrder":"ASC","page":1,"size":100}'
	eval_api='https://customerconnect.vmware.com/channel/api/v1.0/custom-license/product-list'
	lic_api='https://customerconnect.vmware.com/channel/api/v1.0/custom-license/license-list'
	# get eval_list
	xsrf=`grep -i xsrf-token $cdir/$ck|cut -f7`
	cl=`echo -n $eval_post | wc -c`
	eval_list=`wget -q -O - $cc --load-cookies $cdir/$ck --post-data="$eval_post" --header="Referer: $xhr" --header="Content-length: $cl" --header="Content-Type: application/json" --header="User-Agent: $ua" --header="x-dtpc: $dtpc" --header="X-XSRF-TOKEN: $xsrf" --header='TE: Trailers' $eval_api 2>/dev/null`
	prod_list=`echo $eval_list | jq '.result[].productId'`
	for prodId in $prod_list
	do
		lic_post="{\"productId\":$prodId,\"searchText\":\"\",\"filter\":\"ACTIVE\",\"sortByField\":\"DAYS_REMAINING\",\"sortOrder\":\"DESC\",\"page\":1,\"size\":10}"
		cl=`echo -n $lic_post | wc -c`
		lic_list=`wget -q -O - $cc --load-cookies $cdir/$ck --post-data="$lic_post" --header="Referer: $xhr" --header="Content-length: $cl" --header="Content-Type: application/json" --header="User-Agent: $ua" --header="x-dtpc: $dtpc" --header="X-XSRF-TOKEN: $xsrf" --header='TE: Trailers' $lic_api 2>/dev/null`
		echo $lic_list | jq '.result.productName+"\t"+(.result.licenses[]|.serialKey+"\t"+.expirationDate)' | sed 's/\\t/\t/g'|sed 's/"//g'
	done
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
shaVerify=0
veriforce=0
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
dlgid=''
allmissing=0
olde=12
certcheck=1
renodejs=0
nested=0
retrycount=8
getlicenses=0
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

while [[ $# -gt 0 ]]; do key="$1"; case "$key" in --allmissing) $allmissing=1; shift;; --dlgroup) dlgroup=$2; dlgid=$3; shift;shift;; -c|--check) doshacheck=1 ;; -h|--help) usage ;; -i|--ignore) doignore=1 ;; -l|--latest) dolatest=0 ;; -r|--reset) doreset=1 ;; -f|--force) doforce=1 ;; -e|--exit) doreset=1; doexit=1 ;; -y) myyes=1 ;; -u|--username) username=$2; shift ;; -p|--password) password=$2; shift ;; -ns|--nostore) nostore=1 ;; -nh|--noheader) noheader=1 ;; -d|--dryrun) dryrun=1 ;; -nc|--nocolor) docolor=0 ;; --nested) nested=1 ;; --repo) repo="$2"; if [ Z"$vsmrc" = Z"" ]; then load_vsmrc; fi; shift ;; --dlg) mydlg=$2; dodlg=1; shift ;; --dlgl) mydlg=$2; dodlglist=1; shift ;; --vexpertx) dovexxi=1 ;; --patches) if [ $dovexxi -eq 1 ]; then dopatch=1; fi ;; -v|--vsmdir) cdir=$2; if [ Z"$vsmrc" = Z"" ]; then load_vsmrc; fi; shift ;; --save) dosave=1 ;; --symlink) symlink=1 ;; --nosymlink) symlink=0 ;; --fixsymlink) fixsymlink=1; symlink=1 ;; --historical) historical=1 ;; --nohistorical) historical=0 ;; --debug) debugv=1 ;; --debugv) dodebug=1 ;; --clean) cleanall=1; doreset=1; remyvmware=1;; --dts) mydts=1 ;; --oem) myoem=1 ;; --oss) myoss=1 ;; --nodts) mydts=0 ;; --nooem) myoem=0 ;; --nooss) myoss=0 ;; -mr) remyvmware=1;; -mn) renodejs=1;; -q|--quiet) doquiet=1 ;; -nq|--noquiet) doquiet=0 myq=0 ;; --progress) myprogress=1 ;; --favorite) if [ Z"$favorite" != Z"" ]; then myfav=1; fi ;; --fav) fav=$2; myfav=2; shift ;; --retries) retrycount=$2; shift;; -V|--version) version ;; --verify) shaVerify=1;; --veriforce) shaVerify=1; veriforce=1 ;; -z|--compress) compress=1 ;; --nocompress) compress=0 ;; --rebuild) rebuild=1 ;; --keeplocs) rebuild=2 ;; --olde) olde=$2; shift;; --nocertcheck) certcheck=0;; --licenses) getlicenses=1 ;; *) usage ;; esac; shift; done

# Certcheck
cc=''
if [ $certcheck -eq 0 ]
then
	cc='--no-check-certificate'
fi

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
touch $cdir/.test >& /dev/null
if [ $? -eq 1 ]
then
	colorecho "$cdir is not writable by ${xu}." 1
	exit
fi
if [ -e "${cdir}/.test" ]
then
	rm $cdir/.test
fi

# Check Repo
touch $repo/.test >& /dev/null
if [ $? -eq 1 ]
then
	colorecho "$repo is not writable by ${xu}." 1
	exit
fi
if [ -e "${repo}/.test" ]
then
	rm $repo/.test
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
	echo "	Rebuild:	$rebuild"
	echo "	Force Download:	$doforce"
	echo "	Checksum:	$doshacheck"
	echo "	Historical Mode:$historical"
	echo "	Symlink Mode:	$symlink"
	echo "	Reset XML Dir:	$doreset"
	echo "	Nested: $nested"
	echo "	Verify Mode:	$shaVerify"
	echo "	Retry Count:	$retrycount"
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
rm -f index.html.* 2>/dev/null

# Get Olde Time and remove temp files if time limited reached, default 12 hours
fopt="-c"
ffmt="%Y"
sfmt="%s"
if [ Z"$theos" = Z"macos" ]
then
	fopt="-f"
	ffmt="%m"
	sfmt="%z"
fi
if [ -e ${rcdir}/_downloads.xhtml ]
then
	mrt=$((olde*3600))
	ot=$((($(date +%s) - $(stat $fopt $ffmt -- ${rcdir}/_downloads.xhtml)) - $mrt))
	debugvecho "	Cache Timeout: 	$ot" 
	if [ $ot -gt 0 ]
	then
		remyvmware=1
	fi
fi

# Delete all My VMware files! So we can start new
if [ $remyvmware -eq 1 ]
then
	rm -rf ${rcdir}/_* ${cdir}/*.txt
	rm -rf $repo/.hashHistory
fi

if [ $doreset -eq 1 ]
then
	rm -rf ${rcdir}/* ${cdir}/*.txt
	rm -rf $repo/.hashHistory
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
	if [ -e $cdir/vex_auth.html ]
	then
		rm $cdir/vex_auth.html
	fi
	rm -rf $repo/.hashHistory
	rm -rf $HOME/.vsm/.key >& /dev/null
	rm -rf ${cdir}/node* ${cdir}/*.json ${cdir}/*.txt ${cdir}/node-bm.js ${cdir}/node-pt.js ${cdir}/bm.txt
	pkill -9 Xvfb
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
rm -f ${cdir}/*.html 2>/dev/null

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
	rm -rf ${cdir}/bm.txt >& /dev/null
	exit
fi

# Present the list
cd depot.vmware.com/PROD/channel

# Patches
oauth_err=0
mydl_ref='https://customerconnect.vmware.com/group/vmware/downloads#tab1'
mypatch_ref='https://customerconnect.vmware.com/patch'
mypatch_versions='https://customerconnect.vmware.com/channel/api/v1.0/patch/loadproductsandversions'
mypatch_search='https://customerconnect.vmware.com/channel/api/v1.0/patch/search'
myvmware_login='https://customerconnect.vmware.com/web/vmware/login'
#myvmware_oauth='https://customerconnect.vmware.com/oam/server/auth_cred_submit'
myvmware_oauth='https://auth.vmware.com/oam/server/auth_cred_submit?Auth-AppID=WMVMWR'
myvmware_prod='https://customerconnect.vmware.com/channel/public/api/v1.0/products/getAllProducts?locale=en_US&isPrivate=true'
myvmware_template='https://customerconnect.vmware.com/group/vmware/gateway/api/v1.0/navigation/template?locale=us&source=myvmware'
myvmware_token='https://customerconnect.vmware.com/channel/public/api/v1.0/navigation/coveo/token'
prod_xhr='https://customerconnect.vmware.com/channel/public/api/v1.0/products/getProductHeader?locale=en_US&'
related_xhr='https://customerconnect.vmware.com/channel/public/api/v1.0/products/getRelatedDLGList?locale=en_US&'
# referer https://customerconnect.vmware.com/group/vmware/downloads/details?downloadGroup=DLG&productId=.dlgList[].productId&rPId=.dlgList[].releasePackageId
dlghdr_xhr='https://customerconnect.vmware.com/channel/public/api/v1.0/products/getDLGHeader?locale=en_US&' #downloadGroup=DLG&productID=.dlgList[].productId
betahdr_xhr='https://customerconnect.vmware.com/channel/public/api/v1.0/dlg/beta/header?locale=en_US&' #downloadGroup=DLG
beta_xhr='https://customerconnect.vmware.com/channel/api/v1.0/dlg/beta/details?locale=en_US&' #downloadGroup=DLG
dlg_xhr='https://customerconnect.vmware.com/channel/public/api/v1.0/dlg/details?locale=en_US&' # downloadGroup=DLG&productId=.product[].id&rPId=.product[].releasePackageId
dlgrel_xhr='https://customerconnect.vmware.com/channel/public/api/v1.0/products/getDLGRelatedDLGList?locale=en_US&'
eula_xhr='https://customerconnect.vmware.com/channel/api/v1.0/dlg/eula/accept?locale=en_US&' #downloadGroup=DLG
download_xhr='https://customerconnect.vmware.com/channel/api/v1.0/dlg/download' # POST
vex_login='https://vexpert.vmware.com/login'
vex_ref='https://vexpert.vmware.com/my/downloads/'
oaua='Mozilla/5.0 (X11; Fedora; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.75 Safari/537.36'
ppr=''
ppv=''

# save a copy of the .vsmrc and continue
if [ $noheader -eq 0 ]
then
	echo -n "	"
fi
save_vsmrc

# seed oauth check
need_login=0
if [ -f ${cdir}/ocookies.txt ]
then
	need_login=`stat $fopt $ffmt ${cdir}/ocookies.txt 2> /dev/null`
fi
# Authenticate
oauth_login 0
if [ $oauth_err -eq 0 ]
then
	if [ $noheader -eq 0 ]; then colorecho "	Oauth:		1"; fi
else
	colorecho "	Oauth:		Error" 1
	dopatch=0
	rm -rf ${cdir}/bm.txt >& /dev/null
	exit
fi
if [ $dopatch -eq 1 ] && [ $dovexxi -eq 1 ]
then
	if [ $noheader -eq 0 ]; then colorecho "	Patches:	1"; fi
fi

findCk

if [ $nested -eq 1 ] && [ $dovexxi -eq 1 ]
then
	# does not require a login so get and exit
	if [ $noheader -eq 0 ]; then colorecho "	Nested:	1"; fi
	getNested
	exit
fi

# Get Eval Licenses
if [ $getlicenses -eq 1 ] && [ $dovexxi -eq 1 ]
then
	if [ $noheader -eq 0 ]; then colorecho "	Licenses:	1"; fi
	getLicenses
	exit
fi

# normal downloads
if [ ! -e ${rcdir}/_downloads.xhtml ] || [ $doreset -eq 1 ]
then
	# Get JSON
	mywget ${rcdir}/_h_downloads.xhtml $myvmware_prod

	grep "Temporary Maintenance" ${rcdir}/_h_downloads.xhtml >& /dev/null
	if [ $? -eq 0 ]
	then
		colorecho "Error: My VMware Temporary Maintenance" 1
		rm -rf ${cdir}/bm.txt >& /dev/null
		exit;
	fi

	if [ ! -e ${rcdir}/_h_downloads.xhtml ]
	then
		colorecho "Error: Could not get My VMware Downloads File" 1
		rm -rf ${cdir}/bm.txt >& /dev/null
		exit;
	fi

	# Parse JSON
	cat ${rcdir}/_h_downloads.xhtml | jq '.[][].productList[]|.name,.actions[]'| tr '\n' ' ' | sed 's/} {/}\n{/g' | sed 's/} "/}\n"/g' | sed 's/" {/"\n{/g' |egrep '^"|Download'|tr '\n' ' '|sed 's/} "/}\n"/g' > ${rcdir}/_downloads.xhtml

	if [ $err -ne 0 ]
	then
		rm -rf ${cdir}/bm.txt >& /dev/null
		exit $err
	fi
fi


# Login to vexpert.vmware.com
vexpert_login

# start of history
myvmware_root="https://customerconnect.vmware.com/group/vmware/"
myvmware_ref="https://customerconnect.vmware.com/group/vmware/downloads#tab1"
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
		layer+=('productList[]')
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
			layer+=('productList[]')
			layer+=('name')
		elif [ ${layer[2]} = "name" ]
		then
			layer=(${layer[0]})
			layer+=("productList[$lr]")
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

function getMyVersions()
{
	# This changed...
	# we need to go to My VMware now
	action=`jq "${layers}[0].target" $rcdir/_h_downloads.xhtml | sed 's#./info/slug/#category=#' | sed 's#/#\&product=#'|sed 's#/#\&version=#' | sed 's/"//g'`
	
	debugecho $pName
	missname=$choice
	if [ ! -e ${rcdir}/_${missname}.xhtml ] || [ $doreset -eq 1 ]
	then
		
		mywget ${rcdir}/_${missname}.xhtml ${prod_xhr}${action}
		#mywget ${rcdir}/_${missname}_dlgList.xhtml ${related_xhr}${action}
	fi
	#getVersionList
	tver=`jq '.versions[].id' ${rcdir}/_${missname}.xhtml|sed 's/"//g'`
	pkgs=''
	if [ Z"$tver" != Z"" ]
	then
		for x in $tver
		do
			pkgs="$pkgs ${missname}_${x}"
		done
	fi
}

naction=''
function getMySuites()
{
	# deal with version. If 1 then its the same file
	nnr=$(($nr-1))
	missname=${layer[$nnr]}
	nnr=$(($nnr-1))
	ver=`echo $missname | sed "s/${layer[$nnr]}_//"`
	#over=`basename $action`
	naction=`echo $action | sed "s/version=.*/version=$ver/"`
	if [ ! -e ${rcdir}/_${missname}.xhtml ] || [ $doreset -eq 1 ]
	then
		#mywget ${rcdir}/_${missname}.xhtml ${prod_xhr}${naction}
		mywget ${rcdir}/_${missname}.xhtml "${related_xhr}${naction}&dlgType=PRODUCT_BINARY"
		#mywget ${rcdir}/_${missname}.xhtml ${myvmware_root}${naction}
	fi
	mversions=`jq '.dlgEditionsLists[].name' ${rcdir}/_${missname}.xhtml|sed 's/"//g'|sed 's/ /_/g'`
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
		fName=`echo "dlg_${x}"|sed 's/-/_/g'`
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
			if [ $useDlg -eq 0 ]
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
				# API not showing how to do this
				#if [ $vexit -eq 0 ]
				#then
				#	if [ ${#npkg[@]} -eq 0 ]
				#	then
				#		npkg=("${GRAY}${x}${NB}${NC}")
				#	else
				#		npkg+=("${GRAY}${x}${NB}${NC}")
				#	fi
				#else
					# really should check for existence 
					colorMyPkgsFound
				#fi
			else
				colorMyPkgsFound
			fi
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
	snr=$(($specReply-1))
	# use longReply as this is groups by more-details
	xpkgs=`jq ".dlgEditionsLists[$snr].dlgList[].code" $rcdir/_${specname}.xhtml 2>/dev/null |sed 's/"//g'|sed 's/-/_/g'`
	if [ Z"$xpkgs" = Z"" ]
	then
		colorecho "There are no Packages Available for this Software"
	fi
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
	snr=$(($specNnr-1))
	pnr=$(($lr-1))
	iname=`echo $missname | sed 's/_/[_-]/g'`
	#downloadGroup=DLG&productID=.dlgList[].productId
	vurl=`jq ".dlgEditionsLists[$snr].dlgList[$pnr]|.code,.productId" $rcdir/_${specname}.xhtml|sed 's/"//g'|tr '\n' ' ' |sed 's/^/downloadGroup=/' |sed 's/ /\&productId=/'`
	#downloadGroup=DLG&productID=.dlgList[].productId&rPId=.dlgList[].releasePackageId
	vhr=`jq ".dlgEditionsLists[$snr].dlgList[$pnr]|.code,.productId,.releasePackageId" $rcdir/_${specname}.xhtml|sed 's/"//g'|tr '\n' ' ' |sed 's/^/downloadGroup=/' |sed 's/ /\&productId=/'|sed 's/ /\&rPId=/' | sed 's/ //'`
	xhr="https://customerconnect.vmware.com/group/vmware/downloads/details?${vhr}"
	if [ ! -e ${rcdir}/_${missname}_ver.xhtml ] || [ $doreset -eq 1 ]
	then
		mywget ${rcdir}/_${missname}_ver.xhtml ${dlghdr_xhr}${vurl} xhr $xhr
	fi
	if [ $sc -eq 0 ]
	then
		tver=`jq 'if (.versions | length) > 1 then .versions[].id else "" end' ${rcdir}/_${missname}_ver.xhtml|sed 's/"//g'|sed 's/-/_/g'`
		colorMyPkgs "$tver"
		pkgs=${npkg[@]}
	fi
}

function getMyPatches()
{
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
		patcnt=0
		if [ -e ${rcdir}/_${ppr}_${ppv}_patchlist.xhtml ]
		then
			patcnt=`jq '.patchResult|length' ${rcdir}/_${ppr}_${ppv}_patchlist.xhtml`
			if [ Z"$patcnt" = Z"" ]
			then
				patcnt=0
			fi
		fi
	fi
}

vhr=''
function getMyFiles()
{
	sc=$1
	snr=$(($specNnr-1))
	iname=`echo $missname | sed 's/_/[_-]/g'`
	ichoice=`echo $choice | sed 's/-/_/g'`
	#downloadGroup=DLG&productID=.dlgList[].productId
	#code=`jq ".dlgEditionsLists[$snr].dlgList[$fnr].code" ${rcdir}/_${specname}.xhtml|sed 's/"//g'`
	#mywget ${rcdir}/_${missname}_eula.xhtml "${eula_xhr}downloadGroup=${choice}" xhr $xhr
	if [ Z"$dlgroup" = Z"" ]
	then
		vhr=`jq ".dlgEditionsLists[$snr].dlgList[]|if (.code|test(\"${iname}$\")) then .code,.productId,.releasePackageId else \"\" end" ${rcdir}/_${specname}.xhtml |sed '/""/d'|sed 's/"//g' |tr '\n' ' ' |sed 's/^/downloadGroup=/' |sed 's/ /\&productId=/'|sed 's/ /\&rPId=/' | sed 's/ //'`
	fi
	use_xhr=$dlg_xhr
	if [ Z"$missname" != Z"$ichoice" ] && [ $historical -eq 1 ]
	then
		icode=`echo $ichoice | sed 's/_/[_-]/g'`
		# Missing file due to historical, change missname and get header
		d=`jq ".versions[]|if (.id|test(\"${icode}$\")) then .id else \"\" end" ${rcdir}/_${missname}_ver.xhtml|sed '/""/d'|sed 's/"//g'`
		vhr=`echo $vhr | sed "s/$iname/$d/"`
		mhr=`echo $vhr | sed "s/\&rPId=.*//"`
		xhr="https://customerconnect.vmware.com/group/vmware/downloads/details?${vhr}"
		missname=${ichoice}
		if [ ! -e ${rcdir}/_${missname}_ver.xhtml ] || [ $doreset -eq 1 ]
		then
			mywget ${rcdir}/_${missname}_ver.xhtml ${dlghdr_xhr}${mhr} xhr $xhr 
		fi
	else
		if [ Z"$dlgid" = Z"beta" ]
		then
			xhr="https://customerconnect.vmware.com/group/vmware/downloads/get-download?${vhr}"
			use_xhr=$beta_xhr
		else
			xhr="https://customerconnect.vmware.com/group/vmware/downloads/details?${vhr}"
		fi
	fi
	if [ ! -e ${rcdir}/_${missname}.xhtml ] || [ $doreset -eq 1 ]
	then
		mywget ${rcdir}/__${missname}.xhtml ${use_xhr}${vhr} xhr $xhr 
		# Strip out 'header' elements
		sed 's/},/},\n/g' ${rcdir}/__${missname}.xhtml | sed 's/:\[/:\[\n/' |sed 's/}]/}\n]/' | grep -v '"header":true' | tr '\n' ' ' |sed 's/, ]/]/' > ${rcdir}/_${missname}.xhtml
	fi
	# get the files
	whatever=`echo $choice|sed 's/-/_/g'`
	xpkgs=`jq '.downloadFiles[].fileName' ${rcdir}/_${missname}.xhtml | sed 's/"//g'`
	if [ Z"$xpkgs" = Z"" ]
	then
		notice=`jq '.downloadFiles[0]|if (.description|test("follow")) then .description else "" end' ${rcdir}/__${missname}.xhtml | sed -e 's/<[^>]*>//g' |sed 's/"//g'`
		if [ Z"$notice" = Z"" ]
		then
			notice="No Downloads Available"
		fi
		echo -e "${PURPLE}$notice${NC}"
	fi
	# need to swing through xpkgs for exist vs not
	pkgs="$xpkgs"
	writeJSON
	if [ $sc -eq 0 ]
	then
		colorMyPkgs "$xpkgs" 0
		pkgs="All ${npkg[@]}"
	fi

	if [ Z"$dlgid" != Z"beta" ]
	then
		##
		# OEM/DTS/Patches - only perform if options set
		if [ $mydts -eq 1 ]
		then
			if [ ! -e ${rcdir}/_${missname}_dts.xhtml ] || [ $doreset -eq 1 ]
			then
				icode=`echo $missname|sed 's/_/[_-]/g'`
				d=`jq ".versions[]|if (.id|test(\"${icode}$\")) then .id else \"\" end" ${rcdir}/_${missname}_ver.xhtml|sed '/""/d'|sed 's/"//g'`
				mywget ${rcdir}/_${missname}_dts.xhtml "${dlgrel_xhr}${naction}&downloadGroup=${d}&dlgType=DRIVERS_TOOLS" xhr $xhr
			fi
			dtslist=(`jq '.dlgEditionsLists[].dlgList[].code' ${rcdir}/_${missname}_dts.xhtml 2>/dev/null |sed 's/"//g'|sed 's/-/_/g'`)
			if [ ${#dtslist[@]} -gt 0 ] && [ $sc -eq 0 ]
			then
				pkgs="$pkgs DriversTools"
			fi
		fi
		if [ $myoem -eq 1 ]
		then
			if [ ! -e ${rcdir}/_${missname}_oem.xhtml ] || [ $doreset -eq 1 ]
			then
				icode=`echo $missname|sed 's/_/[_-]/g'`
				d=`jq ".versions[]|if (.id|test(\"${icode}$\")) then .id else \"\" end" ${rcdir}/_${missname}_ver.xhtml|sed '/""/d'|sed 's/"//g'`
				mywget ${rcdir}/_${missname}_oem.xhtml "${dlgrel_xhr}${naction}&downloadGroup=${d}&dlgType=CUSTOM_ISO" xhr $xhr
				mywget ${rcdir}/_${missname}_add.xhtml "${dlgrel_xhr}${naction}&downloadGroup=${d}&dlgType=ADDONS" xhr $xhr
			fi
			oemlist=(`jq '.dlgEditionsLists[].dlgList[].code' ${rcdir}/_${missname}_oem.xhtml 2>/dev/null |sed 's/"//g';jq '.dlgEditionsLists[].dlgList[].code' ${rcdir}/_${missname}_add.xhtml 2>/dev/null |sed 's/"//g'|sed 's/-/_/g'`)
			if [ ${#oemlist[@]} -gt 0 ] && [ $sc -eq 0 ]
			then
				pkgs="$pkgs CustomIso"
			fi
		fi
		patcnt=0
		getMyPatches
		if [ $patcnt -gt 0 ]
		then
			pkgs="$pkgs Patches"
		fi
	else
		dtslist=()
		oemlist=()
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
		pkgs=`jq "${layers}" $rcdir/_h_downloads.xhtml | sed 's/ /_/g'|sed 's/"//g'`
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
				# no or 1 version or not historical
				if [ Z"$tver" = Z"" ] || [ $historical -ne 1 ]
				then
					infiles=1
					getMyFiles 0
				fi
		elif [ $nr -eq 7 ]
		then
			# File missing, so get data, went down then back up
			#if [ $historical -eq 1 ]
			#then
			#	wgetMyVersion
			#fi
			infiles=1
			getMyFiles 0
		fi
	fi
}

pName=''
prevChoice=$choice
function createMenu()
{
	##
	# TODO:
	# if grey nothing is selectable just viewable active buttons are Exit/Back
	##
	if [ ${#pkgs} -ne 0 ]
	then
		prevChoice=$choice
		if [ Z"$pkgs" = Z"All " ]; then pkgs=''; fi # Nothing so Drop the All!
		echo $pkgs | grep "All" >& /dev/null
		all_h=$?
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
		if [ Z"$mark" != Z"" ]
		then
			debugvecho "Fav Potential: ${pName}_${layer[4]}"
		fi
		cnt_r=`echo "$pkgs $mark $back Exit" | wc -w`
		redraw=1
		export COLUMNS=8
		while [ $redraw -eq 1 ]
		do
			select choice in $pkgs $mark $back Exit
			do
				sfail=0
				redraw=0
				# search for text
				if [ ${REPLY:0:1} = "/" ]
				then
					search=`echo "$pkgs $mark $back Exit" | sed 's/ /\n/g' | grep -in ${REPLY:1}`
					if [ $? -eq 0 ]
					then
						OREPLY=$REPLY
						# single item or multiple?
						# Multiple == submenu
						cnt_s=`echo $search | sed 's/ /\n/g' |wc -l`
						if [ $cnt_s -eq 1 ]
						then
							choice=`echo $search|awk -F: '{print $2}'`	
							REPLY=`echo $search|awk -F: '{print $1}'`
						else
							sdraw=1
							tput bold
							echo "Multiple results found for ${REPLY:1}"
							while [ $sdraw -eq 1 ]
							do
								select schoice in $search "Back"
								do
									sdraw=0
									if [ $REPLY = "b" ] || [ $REPLY = "B" ]
									then
										#always last
										schoice="Back"
										REPLY=$OREPLY
										redraw=1
									fi
									if [ Z"$schoice" != Z"" ]
									then
										choice=`echo $schoice|awk -F: '{print $2}'`	
										REPLY=`echo $schoice|awk -F: '{print $1}'`
									else
										echo "${RED}Please enter a valid numeric number or b${NC}"
										tput bold
										sdraw=1
									fi
									if [ $sdraw -eq 0 ]
									then
										break
									fi
								done
							done
							#echo "\t`echo $search|sed 's/ /\n\t/g'`"
							echo -n $NC
						fi
					else
						echo "${RED}Search failed for ${REPLY:1}${NC}"
						sfail=1
					fi
				fi
				# Need to do something on redraw (break) and redraw
				if [ $REPLY = "r" ] || [ $REPLY = "R" ]
				then
					redraw=1
				fi
				# Debug
				if [ $REPLY = "d" ] || [ $REPLY = "D" ]
				then
					if [ Z"$pName" = Z"" ]
					then
						echo "Top Menu"
					else
						echo $pName
					fi
					sfail=1
				fi
				# letter substitutions, we also need longReply to mean something
				if [ $REPLY = "e" ] || [ $REPLY = "E" ] || [ $REPLY = "x" ] || [ $REPLY = "X" ] || [ $REPLY = "q" ] || [ $REPLY = "Q" ]
				then
					#always last
					choice="Exit"
					REPLY=$cnt_r
				fi
				if [ $all_h -eq 0 ]
				then
					if [ $REPLY = "a" ] || [ $REPLY = "A" ]
					then
						#always first
						choice="All"
						REPLY=1
					fi
				fi
				if [ Z"$mark" != Z"" ]
				then
					if [ $REPLY = "m" ] || [ $REPLY = "M" ]
					then
						#always 3rd to last
						choice="Mark"
						REPLY=$(($cnt_r-2))
					fi
				fi
				if [ $patcnt -gt 0 ]
				then
					if [ $REPLY = "p" ] || [ $REPLY = "P" ]
					then
						#always 3rd to last
						choice="Patches"
						REPLY=$(($cnt_r-3))
					fi
				fi
				if [ Z"$back" != Z"" ]
				then
					if [ $REPLY = "b" ] || [ $REPLY = "B" ]
					then
						#always 2nd to last
						choice="Back"
						REPLY=$(($cnt_r-1))
					fi
				fi
				longReply=$REPLY
				if [ Z"$choice" != Z"" ]
				then
					## needed if we allow
					stripcolor
					if [ $choice = "Exit" ]
					then
						rm ${cdir}/bm.txt >& /dev/null
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
				else
					if [ $redraw -eq 0 ] && [ $sfail -eq 0 ]
					then
						if [ Z"$mark" != Z"" ]
						then
							m=" m,"
						fi
						if [ Z"$back" != Z"" ]
						then
							b=" b,"
						fi
						if [ $patcnt -gt 0 ]
						then
							p=" p,"
						fi
						echo "${RED}Please enter a valid numeric number or one of a, e, x, d,${p}${b}${m} /string${NC}"
						sfail=1
					fi
				fi
				if [ $sfail -eq 0 ]
				then
					break
				fi
			done
		done
	else
		longReply=1 # use this value for follow on elements
	fi
}

function processCode() 
{
	# PARAMS
	#	dlgType: Product Binaries
	#	dlgVersion: .downloadFiles[].version
	#	downloadGroup: DLG
	#	isBetaFlow: false
	#	locale: en_US
	#	md5checksum: .downloadFiles[].md5checksum
	#	productFamily: .product.name
	#	productId: .product.id
	#	releaseDate: .downloadFiles[].releaseDate
	#	tagId: .dlg[].tagId
	#	uUId: .downloadFiles[].uuid
	#pnr=$((lr-1))
	dlgVersion=`jq ".downloadFiles[$pnr].version" ${rcdir}/_${missname}.xhtml|sed 's/"//g'`
	md5checksum=`jq ".downloadFiles[$pnr].md5checksum" ${rcdir}/_${missname}.xhtml|sed 's/"//g'`
	releaseDate=`jq ".downloadFiles[$pnr].releaseDate" ${rcdir}/_${missname}.xhtml|sed 's/"//g'`
	uUId=`jq ".downloadFiles[$pnr].uuid" ${rcdir}/_${missname}.xhtml|sed 's/"//g'`
	productId=`jq '.product.id' ${rcdir}/_${missname}_ver.xhtml|sed 's/"//g'`
	tagId=`jq '.dlg.tagId' ${rcdir}/_${missname}_ver.xhtml|sed 's/"//g'`
	downloadGroup=`jq '.dlg.code' ${rcdir}/_${missname}_ver.xhtml|sed 's/"//g'`
	dlgType=`jq '.dlg.type' ${rcdir}/_${missname}_ver.xhtml|sed 's/"//g'|sed 's/amp;//g'`
	productFamily=`jq '.product.name' ${rcdir}/_${missname}_ver.xhtml|sed 's/"//g'`
	if [ Z"$productFamily" = Z"null" ]
	then
		productFamily=`jq '.productDisplayName' ${rcdir}/_${missname}_ver.xhtml|sed 's/"//g'`
	fi
	if [ Z"$dlgVersion" = Z"null" ]
	then
		dlgVersion=`jq '.version' ${rcdir}/_${missname}_ver.xhtml|sed 's/"//g'`
	fi
	isBetaFlow='false'
	if [ Z"$dlgid" = Z"beta" ]
	then
		dlgType="Product Binaries"
		downloadGroup=$dlgroup
		isBetaFlow='true'
	fi
	if [ Z"$productId" = Z"null" ]
	then
		productId=""
	fi
	# This should change for betas
	payload=""
	if [ Z"$uUId" != Z"null" ]
	then
		if [ Z"$tagId" = Z"null" ]
		then
			payload="{\"locale\":\"en_US\",\"downloadGroup\":\"$downloadGroup\",\"productId\":\"$productId\",\"md5checksum\":\"$md5checksum\",\"tagId\":\"\",\"uUId\":\"$uUId\",\"dlgType\":\"$dlgType\",\"productFamily\":\"$productFamily\",\"releaseDate\":\"$releaseDate\",\"dlgVersion\":\"$dlgVersion\",\"isBetaFlow\":$isBetaFlow}"
		else
			payload="{\"locale\":\"en_US\",\"downloadGroup\":\"$downloadGroup\",\"productId\":\"$productId\",\"md5checksum\":\"$md5checksum\",\"tagId\":$tagId,\"uUId\":\"$uUId\",\"dlgType\":\"$dlgType\",\"productFamily\":\"$productFamily\",\"releaseDate\":\"$releaseDate\",\"dlgVersion\":\"$dlgVersion\",\"isBetaFlow\":$isBetaFlow}"
		fi
	fi
	debugecho $payload
	#payload=`$python -c "import urllib, sys; print urllib.quote(sys.argv[1])" "$pre_payload" 2>/dev/null`
}

function getSHAData()
{
	# granted md5sum is not supported
	sha256=`jq ".downloadFiles[$pnr].sha256checksum" ${rcdir}/_${missname}.xhtml|sed 's/"//g'`
	if [ Z"$sha256" = Z"" ]
	then
		sha256=`jq ".downloadFiles[$pnr].sha1checksum" ${rcdir}/_${missname}.xhtml|sed 's/"//g'`
		if [ Z"$sha256" = Z"" ]
		then
			sha256=`jq ".downloadFiles[$pnr].md5checksum" ${rcdir}/_${missname}.xhtml|sed 's/"//g'`
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
	if [ $shaVerify -eq 1 ]
	then
		grep $name  $repo/.hashHistory >& /dev/null
		if [ $? -ne 0 ]
		then
			echo "$sha	$sha256	$name" >> $repo/.hashHistory
		fi
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
	if [ $rebuild -ge 1 ]
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

isdlurl=0
function getPreUrl()
{
	xurl=$1
	# sometimes there is no preUrl
	if [ $isdlurl -eq 0 ]
	then
		cl=`echo -n $payload | wc -c`
		#lurl=`wget -O - --load-cookies $cdir/$ck --post-data="$payload" --header="Referer: $xhr" --header="Content-length: $cl" --header="Content-Type: application/json" --header="Cookie: s_ptc=%5B%5BB%5D%5D;mv_eid_processed=true" --header="User-Agent: $ua" $xurl 2>&1 | grep downloadUrl | cut -d\" -f4`
		# New API
		xsrf=`grep -i xsrf-token $cdir/$ck|cut -f7`
		dtpc=`grep -i dtpc $cdir/$ck|cut -f7`
		lurl=`wget -O - --load-cookies $cdir/$ck --post-data="$payload" --header="Referer: $xhr" --header="Content-length: $cl" --header="Content-Type: application/json" --header="User-Agent: $ua" --header="x-dtpc: $dtpc" --header="X-XSRF-TOKEN: $xsrf" --header='TE: Trailers' $download_xhr 2>/dev/null|grep downloadURL|cut -d\" -f4 `
	else
		lurl=$xurl
	fi
	debugecho $lurl
}

function verifyHash() {
	vv=$1
	sha2run=$2
	vshah=$3
	echo "Verifying $vv"
	if [ -e ${vv}.gz ]
	then
		v=`gunzip -c $vv | $sha2run | awk '{print $1}'`
	else
		v=`$sha2run ${vv}| awk '{print $1}'`
	fi
	if [ Z"$v" != Z"$vshah" ]
	then
		echo "${RED}FAIL${NC} to verify $vv"
		if [ $veriforce -eq 1 ]
		then
			shaForce=1
		fi
	else
		echo "VERIFIED $vv"
	fi
}

shavexdl=0
function downloadFile()
{
	# simplified getvsm
	dlfile=''
	shavexdl=0
	#getVSMData
	pnr=$(($longReply-2))
	name=`jq ".downloadFiles[$pnr].fileName" ${rcdir}/_${missname}.xhtml|sed 's/"//g'`
	debugecho "$name $pnr"
	oauth_login 0
	if [ ${#name} -ne 0 ]
	then
		doFixSymlinks
		if [ $doprogress -eq 1 ] || [ $debugv -eq 1 ] && [ $dodlg -ne 1 ]
		then
			if [ $shaVerify -eq 0 ]
			then
				echo -n "."
			fi
		fi
		# since we can verify we always get this data
		getSHAData
		shaForce=0
		if [ $shaVerify -eq 1 ]
		then
			shav=(`grep ${name} $repo/.hashHistory 2>/dev/null`)
			if [ $? -eq 0 ]
			then
				verifyHash $name ${shav[0]} ${shav[1]}
			fi
		fi
		if [ ! -e ${name} ] && [ ! -e ${name}.gz ] || [ $doforce -eq 1 ] || [ $shaForce -eq 1 ]
		then 
			processCode
			getPreUrl $download_xhr
			if [ ${#lurl} -gt 0 ]
			then
				if [ $dryrun -eq 1 ]
				then
					echo "mywget $name $lurl '--progress=bar:force' 1"
				else
					retries=1
					echo "Downloading $name to `pwd`:"
					mywget $name $lurl '--progress=bar:force' 1
					# Retry loop w/continue in case file is too large for
					# server timeout on auth
					while [ $err -eq 8 ]
					do
						echo -n "Continueing $retries ..."
						err=0
						oauth_login 0
						getPreUrl $download_xhr
						if [ ${#lurl} -gt 0 ]
						then
							mywget $name $lurl '-c --progress=bar:force' 1
						fi
						((retries++))
						if [ $retries -gt $retrycount ]
						then
							err=9
						fi
					done
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
				echo "${PURPLE}DownloadURL for $name not available${NC}"
				# only if downloadURL not valid
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
		# do not operate on 0 file
		sz=0
		if [ -e $name ]
		then
			sz=`stat $fopt $sfmt $name`
		fi
		if [ $sz -ne 0 ]
		then
			if [ -e $name ] || [ -e ${name}.gz ] || [ $doforce -eq 1 ] || $shaForce -eq 1 ]
			then
				compress_file $name
				mksymlink $name
			fi
		else
			# do not save 0 file
			if [ -e $name ]
			then
				rm $name
			fi
		fi
	fi
}

function getAdditionalDlg()
{
	osc=$1
	gotodir $omissname $osc $missname
	debugecho "gotodir => `pwd`"
	icode=`echo $specname | sed 's/_/[_-]/g'`
	vurl=`jq ".dlgEditionsLists[].dlgList[] | if (.code|test(\"${icode}$\")) then .code,.productId else \"\" end" ${rcdir}/_${omissname}_oem.xhtml ${rcdir}/_${omissname}_dts.xhtml ${rcdir}/_${omissname}_add.xhtml|sed '/""/d' | tr '\n' ' ' | sed 's/"//g'|sed 's/^/downloadGroup=/' |sed 's/ /\&productId=/'| sed 's/ .*//'`
	#vurl="downloadGroup=$specname&productId=$productId"
	if [ ! -e ${rcdir}/_${missname}.xhtml ] || [ $doreset -eq 1 ]
	then
		if [ $doprogress -eq 1 ] || [ $debugv -eq 1 ] && [ $dodlg -ne 1 ]
		then
			if [ $shaVerify -eq 0 ]
			then
				echo -n "-"
			fi
		fi
		mywget ${rcdir}/_${missname}_ver.xhtml ${dlghdr_xhr}${vurl} xhr $xhr
		mywget ${rcdir}/__${missname}.xhtml ${dlg_xhr}${vurl} xhr $xhr
		sed 's/},/},\n/g' ${rcdir}/__${missname}.xhtml | sed 's/:\[/:\[\n/' |sed 's/}]/}\n]/' | grep -v '"header":true' | tr '\n' ' ' |sed 's/, ]/]/' > ${rcdir}/_${missname}.xhtml
	fi
	whatever=$missname
	# null is header so drop
	xpkgs=`jq '.downloadFiles[].fileName' ${rcdir}/_${missname}.xhtml | sed 's/"//g'|grep -v null`
	writeJSON
}

function getAdditional()
{
	sc=$2
	debugecho "DEBUG: missname=>$missname"
	debugecho "DEBUG: add=>$additionalFiles"
	if [ ${#additionalFiles} -ne 0 ]
	then
		ospecname=$specname
		omissname=$missname
		olongReply=$longReply
		doLurl=0
		for specname in $additionalFiles
		do
			longReply=2
			missname=`echo $specname | sed 's/-/_/g'`
			getAdditionalDlg $sc
			for y in $xpkgs
			do
				choice=$y
				downloadFile
				#if [ $doLurl -eq 0 ]
				#then
				#	getPreUrl $url
				#	preUrl=$lurl
				#	doLurl=1
				#fi
				longReply=$(($longReply+1))
				#xloc=$(($xloc+1))
			done
		done
		missname=$omissname
		specname=$ospecname
		longReply=$olongReply
	fi
}

function uag_test() {
	if [ $_v -eq 300 ]
	then
		symdir="view"
	elif [ $_v -eq 0 ] || [ $_v -lt 310 ]
	then
		symdir="UAG_${_v:0:2}"
	else
		symdir="UAG_${_v}"
	fi
}

function getSymdir()
{
	# used for fake symlinks, mostly UAG
	nestdir="Additional"
	symdir=''
	_v=`echo $choice | sed 's/[A-Za-z-]\+-\([0-9]\+\.[0-9]\+\.[0-9]\).*/\1/' | sed 's/\.0$//' |sed 's/\.//g'`
	_vt=`echo $choice | sed 's/[A-Za-z-]\+-\([0-9]\+\.[0-9]\+\.[0-9]\).*/\1/' |sed 's/\.//g'`
	debugecho "$choice => $_v"
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
		VMware-[tT]ools*)
			symdir="VMTOOLS${_vt}"
			nestdir="DriversTools"
			;;
	esac
}

function endOfDownload()
{
	if [ $doprogress -eq 1 ] || [ $debugv -eq 1 ] && [ $dodlg -ne 1 ]
	then
		if [ $shaVerify -eq 0 ]
		then
			echo "!"
		fi
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
		# currently does not verify patches
		downloadPatches
		nr=${#layer[@]}
		nr=$(($nr-1))
		choice=${layer[$nr]}
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
		nestdir=''
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
	patcnt=0
	getMyPatches
	if [ $patcnt -gt 0 ]
	then
		diddownload=0
		downloadPatches
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
		longReply=1
		for x in $tpkgs
		do
			o_sp=$specname
			o_nr=$specNnr
			o_lr=$longReply
			lr=$longReply
			pnr=$(($lr-1))
			snr=$(($specNnr-1))
			choice=`jq ".dlgEditionsLists[$snr].dlgList[$pnr].code" $rcdir/_${specname}.xhtml|sed 's/"//g'`
			missname=$x
			getMyDlgVersions 1
			getMyFiles 1
			getAllChoice
			missname=$x
			longReply=$(($o_lr+1))
			specNnr=$o_nr
			specname=$o_sp
		done
		longReply=$old_sr
	fi
	choice=$old_choice
	specReply=$old_sr
}

function getFavPaths()
{
	# path version Grouping
	#favpaths=(`echo $favorite | sed 's/\([a-z_]\+\)_\([0-9]\+_[0-9x]\+\|[0-9]\+\)_\(.*\)/\1 \2 \3/i'`)
	favpaths=(`echo $favorite | sed 's/\([a-z_]\+\)_\([0-9]\+[_0-9x]\+\|[0-9]\+\)\($\|_[a-z].*\)/\1 \2 \3/i'`)
	# _x at end is usually part of a version, edge case due to lack of greedy
	if [ Z"${favpaths[2]}" = Z"_x" ]
	then
		favpaths[2]=""
		favpaths[1]="${favpaths[1]}_x"
	fi
	# Get First Path Entry (productCategory)
	pc=-1
	for x in `jq ".productCategoryList[].name" _h_downloads.xhtml|sed 's/ /_/g'`
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
		shortPro=`echo ${prodCat[1]}|sed "s/${y}_//"|sed 's/[_-]/./g'`
		# horizon clients have oddifies
		#	need to strip out 'horizon$' but leave it as the missname
		shortProFix=`echo ${prodCat[1]}|sed "s/${y}_//"|sed 's/Clients_horizon/Clients/'|sed 's/[_-]/./g'`
		# Get Second path entry (productList)
		productList=(`jq ".productCategoryList[$pc].productList[].name" _h_downloads.xhtml | grep -in "${shortProFix}\"" | sed 's/:/ /'`)
		lr=${productList[0]}
		# build up front layers
		if [ Z"$lr" = Z"" ]
		then
			colorecho "Unknown Favorite $favorite" 1
			exit
		fi
		if [ $lr -gt 0 ]
		then
			lr=$(($lr-1))
			layer=("productCategoryList[$pc]")
			layer+=("productList[$lr]")
			layer+=("actions")
			missname=`echo ${shortProFix} | sed 's/\./_/g'`
			missnamePro=`echo ${shortPro} | sed 's/\./_/g'`
			choice=$missname
			getLayerPkgs
			layer=("productCategoryList[$pc]")
			layer+=("productList[$lr]")
			layer+=("$missname")
			choice=`echo ${missnamePro}_${favpaths[1]}|sed 's/_$//'`
			#choice=`echo $favorite | sed "s/${pName}_//"`
			layer+=("$choice")
			longReply=`echo $pkgs|sed 's/ /\n/g'|grep -in $choice |cut -d: -f1`
			longReply=$(($longReply-1))
			getLayerPkgs
			# usually handled by createMenu
			if [ ${#pkgs} -eq 0 ]
			then
				longReply=1
			fi
			# no mversions so why do favpaths 2
			if [ Z"$mversions" != Z"" ]
			then
				t_mversions=("$mversions")
				mfpath=`echo ${favpaths[2]}|sed 's/_//'`
				longReply=`echo $mversions|sed 's/ /\n/g'| grep -in ${mfpath} |head -1|cut -d: -f1`
				if [ ${#t_mversions[@]} -gt 1 ]
				then
					longReply=$(($longReply-1))
				fi
				choice=${missname}_${mfpath}
				layer+=("$choice")
			else
				layer+=("$missname")
			fi
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
	historical=1
	# Get LAST item into array
	dlgInfo=(`jq --arg s "$mydlg" '[.dlgList[] | select(.name | test($s))][-1]|.name,.target,.dlg,.parent' $rcdir/newlocs.json | sed 's/"//g'`)
	favorite=${dlgInfo[1]}
	if [ Z"$favorite" = Z"null" ]
	then
		colorecho "No package matching pattern: $mydlg"
		exit
	fi
	getFavPaths
	if [ Z"${dlgInfo[3]}" = Z"" ]
	then
		thedlg=${dlgInfo[2]}
		pkg=`echo ${dlgInfo[2]}|awk -F[0-9] '{print $1}'`
	else
		thedlg=${dlgInfo[3]}
		pkg=`echo ${dlgInfo[3]}|awk -F[0-9] '{print $1}'`
	fi
	lchoice=(`echo $pkgs |sed 's/All //'|sed 's/ /\n/g' | egrep -n "^${pkg}"|sed 's/:/ /'`)
	missname=${lchoice[1]}
	choice=$missname
	longReply=${lchoice[0]}
	#lr=$(($longReply-1))
	lr=$longReply
	getMyDlgVersions 1
	getMyFiles 1
	createLayer
	nr=${#layer[@]}
	# now is it in this layer or 'additional'
	if [ Z"$choice" != Z"$thedlg" ]
	then
		choice=${thedlg}
		createLayer
		nr=${#layer[@]}
		#missname=${choice}
		#wgetMyVersion
		getMyFiles 1
	fi
	if [[ "$xpkgs" == *"${dlgInfo[0]}"* ]]
	then
		getSymdir
		gotodir $missname "base"
		getDlgFile
	elif [[ ${dtslist[@]} == *"${dlgInfo[2]}"* ]] 
	then
		omissname=$missname
		missname=${dlgInfo[2]}
		specname=$missname
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
	#rebuild=0
	getFavPaths
	getAll
	rm -rf ${cdir}/bm.txt >& /dev/null
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
		historical=0
		getDlg
		endOfDownload
		# needed for aac-base scripts
		echo "Local:$repo/dlg_${thedlg}${eou}/$name"
	fi
	rm -rf ${cdir}/bm.txt >& /dev/null
	exit
fi

# TODO: very broken with new API!
if [ Z"$dlgroup" != Z"" ] && [ $dovexxi -eq 1 ]
then
	# limited to JUST the download group, no Additional/CustomISO, etc.
	choice=$dlgroup
	missname=`echo $choice|sed 's/-/_/g'`
	usehdr_xhr=$dlghdr_xhr
	if [ Z"$dlgid" = Z"beta" ]
	then
		vurl="downloadGroup=$choice"
		xhr="https://customerconnect.vmware.com/group/vmware/downloads/get-download?${vurl}"
		usehdr_xhr=$betahdr_xhr
	else
		vurl="downloadGroup=$choice&productId=$dlgid"
		xhr="https://customerconnect.vmware.com/group/vmware/downloads/details?${vurl}"
	fi
	if [ ! -e ${rcdir}/_${missname}_ver.xhtml ] || [ $doreset -eq 1 ]
	then
		mywget ${rcdir}/_${missname}_ver.xhtml ${usehdr_xhr}${vurl} xhr $xhr
	fi
	xpkgs=${choice}
	if [ Z"$dlgid" = Z"beta" ]
	then
		# beta is handled much differently
		colorecho "Downloading Beta $choice"
		vhr="downloadGroup=$choice"
	else
		catmap=`jq '.product.categorymap' ${rcdir}/_${missname}_ver.xhtml|sed 's/"//g'`
		prodmap=`jq '.product.productmap' ${rcdir}/_${missname}_ver.xhtml|sed 's/"//g'`
		versmap=`jq '.product.versionmap' ${rcdir}/_${missname}_ver.xhtml|sed 's/"//g'`
		namemap=`jq '.product.name' ${rcdir}/_${missname}_ver.xhtml|sed 's/"//g'|sed 's/ /_/g'`
		dlgmap=`jq '.dlg.name' ${rcdir}/_${missname}_ver.xhtml|sed 's/"//g'|sed 's/ /_/g'`
		rPId=`jq '.product.releasePackageId' ${rcdir}/_${missname}_ver.xhtml|sed 's/"//g'|sed 's/ /_/g'`
		pc=`jq "[.productCategoryList[]|.id == \"${catmap}\"]|index(true)" ${rcdir}/_h_downloads.xhtml`
		vhr="downloadGroup=$choice&productId=$dlgid&rPId=$rPId"
		lr=`jq "[.productCategoryList[$pc].productList[]|.actions[0].target|contains(\"/${prodmap}/\")]|index(true)" ${rcdir}/_h_downloads.xhtml`
		#productCategoryList[6] productList[1] VMware_Horizon VMware_Horizon_7_12 VMware_Horizon_7_12_Horizon_7.12_Enterprise VIEW_7120_ENT
		if [ Z"$lr" != Z"null" ]
		then
			layer=("productCategoryList[$pc]")
			layer+=("productList[$lr]")
			layer+=("${namemap}")
			layer+=("${namemap}_${versmap}")
			layer+=("${namemap}_${versmap}_${dlgmap}")
			#layer+=("${missname}")
		fi
	fi
	getMyFiles 1
	getAllChoice
	rm -rf ${cdir}/bm.txt >& /dev/null
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

