# aac-lib
AAC Library of Tools

- <a href=https://github.com/Texiwill/aac-lib/tree/master/>List of Tools</a>

## vsm
Linux Version of VMware Software Manager

### Description
A Linux and slightly more intelligent version of VSM for Linux. It ignores
missing definition files that cause the VMware version to stop working. It
also finds ones not in the definitions yet. It is also possible to find
the latest of every package.

This version was optimized for RedHat style distributions and will need
a change to work on non-RedHat style distributions. If someone uses
debian and wants this to work there, get me the dpkg commands needed.

To install use the following script (it will prompt you for the root
password) no need to use sudo yourself:

```
#!/bin/sh
which wget >& /dev/null
if [ $? -eq 1 ]
then
	sudo yum -y install wget
fi

wget -O aac-base.install https://raw.githubusercontent.com/Texiwill/aac-lib/master/base/aac-base.install
chmod +x aac-base.install
./aac-base.install -u
sudo ./aac-base.install -i vsm
```

Here is an example run and help:
```
$ /usr/local/bin/vsm.sh --help
/usr/local/bin/vsm.sh [--dlg search] [-d|--dryrun] [-f|--force] [--favorite] 
[-e|--exit] [-h|--help] [-l|--latest] [-m|--myvmware] [-mr] [-ns|--nostore] 
[-nc|--nocolor] [--dts|--nodts] [--oem|--nooem] [--oss|--nooss] [-p|--password
password] [-r|--reset] [-u|--username username] [-v|--vsmdir VSMDirectory] 
[-V|--version] [-y] [--debug] [--repo repopath] [--save]
	--dlg - download specific package by name or part of a name
	-d|--dryrun - dryrun, do not download
	-f|--force - force download of packages
        --favorite - Download suite marked as favorite
	-e|--exit - reset and exit
	-h|--help - this help
	-l|--latest - substitute latest for each package instead of listed
		Only really useful for latest distribution at moment
	-m|--myvmware - get missing suite and packages from My VMware
		Cannot mark this suite information as a favorite
	-mr - reset just My VMware information
	-ns|--nostore - do not store credential data and remove if exists
	-nc|--nocolor - do not output with color
	-p|--password - specify password
	-r|--reset - reset repos
	-u|--username - specify username
	-v|--vsmdir path - set VSM directory
	                   saved to configuration file
	-V|--version - version number
	-y - do not ask to continue
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
	--repo path - specify path of repo
	              saved to configuration file
	--save - save defaults to $HOME/.vsmrc

	All-style downloads include: All, All_No_OpenSource, Minimum_Required
	Requires packages:
	wget python python-urllib3 libxml2 perl-XML-Twig ncurses

	To Download the latest Perl CLI use (to escape the wild cards):
	./vsm.sh --dlg CLI\.\*\\.x86_64.tar.gz

       Use of the Mark option, marks the current product suite as the
       favorite. There is only 1 favorite slot available. Favorites
       can be downloaded without traversing the menus.

       Those items that show up in Cyan when the -m|--myvmware option
       is set are those items only seen with that option. I.e. not part
       of the standard downloads from VSM. 

       Those items in reverse color (white on black or cyan) are those items
       not downloaded. For packages and not files, the reverse color only
       shows up if the directory is not in the repo and is not related to 
       missing files or new files.

       To enable download of My VMware content which includes minimally
       VMware Horizon, VMware Horizon Clients, VMware Workstation,
       and VMware Fusion use the -m option. Else they will not appear.

       Caveat: Access to these downloads does not imply you are licensed
       for the material. Please see My VMware for your licenses.

$ ./vsm.sh
<span style="color:purple">Using the following options:</span>
   	Version:	1.0.0
   	VSM XML Dir:	/tmp/vsm
   	Repo Dir:	/mnt/rainbow/iso/vmware/depot/content
   	Dryrun:		0
   	Force Download:	0
   	Reset XML Dir:	0
   	Get Latest:	0
   	Use credstore:	1
   
Continue with VSM (Y/n)?
   
Saving to: ‘index.html.1’
   
100%[======================================>] 455,010     1.87MB/s   in 0.2s   
   
2017-09-14 08:03:49 (1.87 MB/s) - ‘index.html.1’ saved [455010/455010]
   
1) Datacenter_Cloud_Infrastructure
2) Infrastructure_Operations_Management
4) Exit
#? 1
1) Datacenter_Cloud_Infrastructure_VMware_Software_Manager
2) Datacenter_Cloud_Infrastructure_VMware_vCloud_Suite
3) Datacenter_Cloud_Infrastructure_VMware_vSphere
4) Datacenter_Cloud_Infrastructure_VMware_vSphere_with_Operations_Management
5) Back
6) Exit
#? 3
1) Datacenter_Cloud_Infrastructure_VMware_vSphere_6_5
2) Datacenter_Cloud_Infrastructure_VMware_vSphere_6_0
3) Datacenter_Cloud_Infrastructure_VMware_vSphere_5_5
4) Datacenter_Cloud_Infrastructure_VMware_vSphere_5_1
5) Back
6) Exit
#? 1
1) Datacenter_Cloud_Infrastructure_VMware_vSphere_6_5_English_Desktop
2) Datacenter_Cloud_Infrastructure_VMware_vSphere_6_5_English_Enterprise
3) Datacenter_Cloud_Infrastructure_VMware_vSphere_6_5_English_Enterprise_Plus
4) Datacenter_Cloud_Infrastructure_VMware_vSphere_6_5_English_Essentials
5) Datacenter_Cloud_Infrastructure_VMware_vSphere_6_5_English_Essentials_Plus
6) Datacenter_Cloud_Infrastructure_VMware_vSphere_6_5_English_Standard
7) Back
8) Exit
#? 3
1) All		   7) VROVA_730		  13) VR65
2) Minimum_Required	   8) VRLI_450_VCENTER	  14) Mark
3) All_Plus_OpenSource  9) BDE_232		  15) Back
4) NSXV_632		  10) VDP614		  16) Exit
5) VC650E		  11) ESXI650D
6) VROPS_660		  12) VIC110
#? 11
1) All
2) Minimum_Required
3) All_Plus_OpenSource
4) VMware-VMvisor-Installer-201704001-5310538.x86_64.iso
5) ESXi650-201704001.zip
6) OpenSource
7) CustomIso
8) DriversTools
9) Back
10) Exit
#? 4
Saving to: ‘VMware-VMvisor-Installer-201704001-5310538.x86_64.iso’
   100%[======================================>] 347,172,864 7.70MB/s   in 45s  

2017-10-11 08:04:21 (7.43 MB/s) - ‘VMware-VMvisor-Installer-201704001-5310538.x86_64.iso’ saved [347172864/347172864]
<span style="color:purple">Downloads to /mnt/rainbow/iso/vmware/depot/content/dlg_ESXI65U1</span>
 
1) All		   7) VROVA_730		  13) VR65
2) Minimum_Required	   8) VRLI_450_VCENTER	  14) Mark
3) All_Plus_OpenSource  9) BDE_232		  15) Back
4) NSXV_632		  10) VDP614		  16) Exit
5) VC650E		  11) ESXI650D
6) VROPS_660		  12) VIC110
#? 14
<span style="color:purple">Favorite: Datacenter_Cloud_Infrastructure_VMware_vSphere_6_5_English_Enterprise_Plus
Saving to /home/elh/.vsmrc</span>
```

### Installation
Place in any directory. Requires the following packages:
	wget python python-urllib3 libxml2 perl-XML-Twig ncurses

### Update
To keep vsm and your repository updated to the latest release/downloads
you can add the following lines to your local cron. This tells the
system to update the installer, then update vsm, then run vsm with your
currently marked favorite. Note 'user' is your username. 

Caveat: This approach only works if you use the aac-lib/base installers to
install vsm. If you did not then just use the last line.

Be sure to mark a release as your favorite! If you do not, this does
not work. The 'Mark' menu item does this.

I added these lines to a script within /etc/cron.daily (which usually runs at 3AM):
```
cd /home/user
/home/user/aac-base.install -u
/home/user/aac-base.install -i vsm
```

The following line starts VSM download at 6AM. You would add using the command `crontab -e`:
```
0 6 * * * /usr/local/bin/vsm.sh -y -r -l --favorite
```

### Support
Email elh at astroarch dot com for assistance or if you want to add
for more items.

If someone can provide debian package maangement bits, send them on as
that is the only distribution specific bits in the script.

### Changelog
3.5.1 - Missing option corrected

3.5.0 - Using My VMware to pick up the up to date names instead of hardcoding 
	them. Added VMware Validated Design (VVD). Fixed VRNI and AppVolumes. 
	Also added the need for jq rpm, a JSON interpreter, for the 
	up-to-date names.

3.2.4 - Protection for temporary directory were reversed

3.2.3 - Protections from temporary directory owned by wrong user causing
	connection errors

3.2.2 - Protections from running as root and added install.sh to repo

3.2.1 - Minor fix... Fusion wrong file uploaded!

3.2.0 - Added Support for VMware Fusion download and improved errors when
	there are network issues.

3.1.0 - Added support for VMware Horizon, VMware Horizon Clients, and VMware 
	Workstation Pro. For now the Fusion download is within VMware Horizon.

3.0.1 - fixed a grep error showing up when it should not

3.0.0 - -m|--myvmware option now works including the need to install the 'bc'
	package. You can now download packages from My VMware not just view 
	missing packages!  Some things may still need tweaking, however. Also,
	added the -mr option to reset My VMware information only.  Email 
	issues and output using the --debug flag to elh at astroarch dot com.

2.5.2 - Fix to --dlg for single file downloads. Local was missing

2.5.1 - Protection for wildcard option

2.5.0 - Code reorganization and addition of wildcard option

2.0.2 - Fixed bug with single file selection

2.0.1 - Fixed bug where you were able to mark missing suites

2.0.0 - Added ability to get missing suite information from VMware's website
        Fixed the ability to select menu options using wrong input

1.7.0 - Fixed an intialization problem. Required --reset|-r to initialize

1.6.9 - Fixed issue where download was not happening for All when
individual files are listed.

1.6.8 - Fixed issue where individual file download resulted in bad
menu display

1.6.7 - Prompts for creds specific My VMware now

1.6.6 - fixed single file download and readme

1.6.5 - added --nooem|--oem, --nodts|--dts, --nooss|--oss to the .vsmrc
configuration file when options are saved

1.6.1 - moved variable and removed check for perl-XML-XPath as it is no
longer required.

1.6.0 - cleaned up code pulling unique items into one loop not 3
separate loops. Fixed Mark to only appear in one spot.

1.5.0 - added ability to download specific file by name or part of a
name and fixed major bug on associated products list where resultant
list was malformed

1.1.0 - fixed 'Back' to actually send you back just 1 level at all times
by creating a path variable that gets updated for every menu call and
Back used

1.0.1 - fixed 'Back' menu item when actual packages are shown

1.0.0 - added Minimum_Required menu item, do only download the base files
and not OpenSource, DriversTools, or CustomIso. Also added the
--dts|--nodts, --oem|--nooem, --oss|--nooss to set what to download when
any of the 'All' styles are selected.

0.9.5 - fixed latest parsing. It was too broad and did not confine to
the latest of a specific major version. I.e. 60 vs 65

0.9.4 - fixed issue where too much was include in the 'smarts'. Main
Product Downloads were being placed into CustomIso and DriverTools.

0.9.3 - Initial public launch
