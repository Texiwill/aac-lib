#!/bin/bash
#
# Copyright (c) AstroArch Consulting, Inc.  2016-2018
# All rights reserved

device=/dev/sr0
if [ X"$1" = X"--device" ]
then
	# we want the device to be $1 then everything else works
	shift
	device=$1
	shift
fi

if [ X"$1" = X"--rebuild" ]
then
	cd /run/media/$USER/*; 
	ba=`pwd | sed "s/ /_/g"`
	ba=`basename $ba`
	if [ ! -e ~/.isolibrary ]
	then
		mkdir ~/.isolibrary
	fi
	if [ -d ~/.isolibrary ]
	then
		find . -type f -print > ~/.isolibrary/$ba
		dev=`mount|grep /run/media |awk '{print $1}'`
		echo "Sleeping before eject..."
		sleep 5
		eject $dev
	else
		echo "Error: ~/.isolibrary not a directory"
	fi
fi

if [ X"$1" = X"--prepare" ]
then
	if [ X"$2" = X"" ]
	then
		echo "Prepare failed no Src directory specified"
	else
		cd $2
		find . -type f -name \.DS_Store -print > /tmp/iso$$
		find . -type f -name Thumbs\.db -print >> /tmp/iso$$
		find . -type d -name \.AppleDouble -print >> /tmp/iso$$
		find . -type d -name \@eaDir -print >> /tmp/iso$$
		find . -type f -name '._*' -print >> /tmp/iso$$
		cat /tmp/iso$$ | sed "s/^/rm -rf \"/" | sed "s/$/\"/" > /tmp/riso$$
		sh -x /tmp/riso$$
		rm /tmp/iso$$ /tmp/riso$$
		LC_ALL=C; export LC_ALL
		echo "Uncompressed/Bad Format List:"
		find . -type f -print | egrep -iv '\.7z|\.zip|\.gz|\.bz|\.tgz|\.rar|\.lnk$|\.Z|\.enc|repo$|,'
		find . -type f -print | grep -P "[\x80-\xFF]" |egrep -v "®|™"
	fi
fi

if [ X"$1" = X"--compile" ]
then
	if [ -d ~/.isolibrary ]
	then
		cd ~/.isolibrary	
		if [ -e .isolibrary ]
		then
			rm .isolibrary
		fi
		cat * > .isolibrary
		if [ X"$2" = X"" ]
		then
			echo "Missing Source directory only merging files"
		else
			(cd $2; find -P . -type f -print > ~/.isolibrary/.srclibrary)
			# now we do some magic, we determine where everything is
			cd ~/.isolibrary

			### Start with Uniq filenames between the two libraries
			cat .isolibrary .srclibrary | sort | uniq -u | egrep -v '\.AppleDouble|\.DS_Store|\._' |fgrep -v '(1)' > .difflibrary

			### determine if top level directories exist and if not
			### add to ignore list
			cat .difflibrary  | awk -F\/ '{printf "ls %s >& /dev/null; if [ $? != 0 ]; then echo %s; fi\n",$2,$2}' | uniq > /tmp/iiso$$
			rm .ignlibrary .dolibrary
			xray=`(cd $2; sh /tmp/iiso$$)`
			dray=""
			for x in $xray
			do
				if [ X"$dray" = X"" ]
				then
					dray=\.\/$x
				else
					dray="$dray|\.\/$x"
				fi
				grep \.\/$x .difflibrary >> .ignlibrary
			done
			rm /tmp/iiso$$

			### Then look at basenames to see if file has moved
			### add to moved list
			egrep -v $dray .difflibrary > .dolibrary

			cat .dolibrary |awk -F\/ '{printf "cnt=`fgrep \"%s\" .dolibrary | wc -l`; if [ $cnt -gt 1 ]; then echo \"%s\"; fi\n",$NF,$0}'| sed 's/(/\\(/g' | sed 's/\\(/(/' | sed 's/)/\\)/g' |sed 's/\\)/)/' > /tmp/miso$$
			sh /tmp/miso$$ > .mvlibrary
			rm /tmp/miso$$

			### Concoct backup list from diff , ignore, and 
			### moved lists
			cat .difflibrary .ignlibrary .mvlibrary | sort | uniq -u > .baklist
			echo "`wc -l .baklist` potential files to backup..."
			echo "	computing size ... "

			### Size of files in list and any missing
			awk '{printf "ls -l \"%s\"\n",$0}' .baklist > /tmp/biso$$
			(cd $2; sh /tmp/biso$$ 2> ~/.isolibrary/.missinglist| awk '{sum=sum+$5} END {sum=sum/1000/1024/1024; cnt=sum/98; printf "	%f GB / %s Discs",sum,cnt}')
			echo ""
			rm /tmp/biso$$

			cat .missinglist | sed 's/ls: cannot access //' | sed 's/: No such file or directory//' > .misslist

			### The true list of files
			
			cat .misslist .baklist | sed 's/ls: cannot access //' | awk -F: '{print $1}'|sort|uniq -u > .backup
			echo "	`wc -l .backup` files to backup"

		fi
	else
		echo "Missing Library: Either use the rebuild or create option first"
	fi
fi

if [ X"$1" = X"--create" ]
then
	if [ -d ~/.isolibrary ]
	then
		cd ~/.isolibrary	

		### Get Media info
		dvd+rw-mediainfo $device 2>/dev/null > /tmp/bd$$
		grep "no media" /tmp/bd$$ >& /dev/null
		if [ $? = 0 ]
		then
			echo "Missing Media"
			exit
		fi
		sz=`grep 32h /tmp/bd$$ | tail -1 | awk -F= '{print $2}'`
		bytes=`grep 00h /tmp/bd$$ |awk -F= '{print $2}'`
		rm /tmp/bd$$

		echo "Creating $sz image with $bytes addressable"

		### Current Count of Disks
		cnt=`ls [A-Z]* | wc -l`
		cnt=$((cnt + 1))
		fn="ISO_Library_$cnt"

		### Now decide what goes where
		if [ X"$2" = X"" ]
		then
			echo "Missing Source directory not doing anything"
			exit;
		fi
		### Size of files in list and any missing
		awk '{printf "ls -l \"%s\"\n",$0}' .backup > /tmp/biso$$
		(cd $2; sh /tmp/biso$$) > .itinerary
		rm /tmp/biso$$ 2>&1 | grep -v "No such file or directory"
		if [ $? = 0 ]
		then
			echo "Must run --compile first"
			exit;
		fi

		### Create a Disk
		truncate --size=$sz /tmp/${fn}.udf
		mkudffs --vid="${fn}" /tmp/${fn}.udf
		sudo mkdir /mnt/$fn
		sudo mount -oloop,rw /tmp/${fn}.udf /mnt/$fn
		sudo chown -R $USER.$USER /mnt/$fn

		bytesleft=$bytes
		cat .itinerary | while read line
		do
			fsz=`echo $line | awk '{print $5}'`
			st=`echo $line | awk '{print $1}'`
			en=`echo $line | awk '{print $8}'`
			ffn=`echo $line | sed "s/$st.*$en //" |sed 's/\.\///'`
			din=`dirname "$ffn"`
			if [ "$fsz" -lt "$bytesleft" ]
			then
				if [ ! -d "/mnt/$fn/$din" ]
				then
					mkdir -p "/mnt/$fn/$din"
				fi
				(cd $2; cp "$ffn" "/mnt/$fn/$ffn" )

				bytesleft=$((bytesleft - $fsz))
				echo $bytesleft
			fi
		done

		### Unmount & Burn the Bluray
		sudo rmdir /mnt/ISO_Library*
		sudo umount /mnt/$fn

		### Need to use Joerg Schilling's version
		if [ -f /usr/local/bin/cdrecord ]
		then
			/usr/local/bin/cdrecord --version |grep ProBD > /dev/null
			if [ $? -eq 0 ]
			then
				/usr/local/bin/cdrecord -v -dao driveropts=burnfree dev=$device /tmp/${fn}.udf
			else
				echo "Cannot burn need Cdrecord-ProDVD-ProBD version"
			fi
		fi
		#growisofs -Z $device=/tmp/ISO_Library_18 -overburn -V $fn
		#if [ -f /usr/bin/nerocmd ]
		#then
		#	#nerocmd --write --drive=$device --volume-name=$fn --bd --image /tmp/$fn
		#	;
		#else
		#	echo "Missing Nero Linux 4 or higher"
		#	echo "Cannot burn image /tmp/$fn"
		#	exit
		#fi

		echo "Now Rerun --rebuild for this disc with $2"
		echo "	then rerun --compile for this disc with $2"
		echo "	then rerun --create for next disc with $2"
	fi
fi

if [ X"$1" = X"--help" ]
then
	echo "Usage: $0 [--device <devname>] [--rebuild|--compile <src directory>|--prepare <src directory>|--create <src directory>|--help]"
	echo "use --rebuild to rebuild from Discs"
	echo "Best to use --prepare then --compile then --create"
fi
