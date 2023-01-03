# aac-lib
AAC Library of Tools

- <a href=https://github.com/Texiwill/aac-lib/tree/master/>List of Tools</a>

## vsm
Linux Version of VMware Software Manager

### NOTICE
__As of v6.7.7, Patch Download Support was added for VC and ESXi only. Use --clean to enable this functionality__

### Description
A slightly more intelligent version of VSM for Linux. It ignores
missing definition files that cause the VMware version to stop working. It
also finds packages not in the definitions yet. It is also possible to find
the latest of every package.

As of v6.7.6, support for case insensitive search has been added.

As of v6.7.5, support for retry on server failure has been added. The default # of retries is 8. Server failures could be the result of authentication expiration.

As of v6.7.1 LinuxVSM now supports Alpine Linux. To use Alpine Linux read <a href=https://github.com/Texiwill/aac-lib/blob/master/vsm/Alpine.md>Alpine.md</a>.

As of v6.7.0 LinuxVSM now supports the use of MFA on the MyVMware
account. To use be sure to run ```vsm.sh --clean``` at least once before trying.

As of v6.4.0 LinuxVSM now uses the My VMware API for all things but
login. This has made the code more resilient to changes from VMware.

As of v6.0.0 LinuxVSM has moved to 100% My VMware capability. This often 
requires an appropriate entitlement to download anything. This is a change
from VMware. The code is now faster, more encompassing, and
cleaner. Furthermore, common options have been removed, see notes below.

Also, you should know that Code Stream is a license ontop of VRA, and
VRA is already in LinuxVSM.

To use vExpert mode read <a href=https://github.com/Texiwill/aac-lib/blob/master/vsm/vExpert.md>vExpert.md</a>.

Here is an example run and help:
```
$ vsm.sh --help
LinuxVSM Help
./vsm.sh [-c|--check] [--clean] [--dlg search] [--dlgl search] [-d|--dryrun] [-f|--force] [--fav favorite] [--favorite] [--fixsymlink] [-e|--exit] [-h|--help] [--historical] [-mr] [-nh|--noheader] [--nohistorical] [--nosymlink] [-nq|--noquiet] [-ns|--nostore] [-nc|--nocolor] [--dts|--nodts] [--oem|--nooem] [--oss|--nooss] [--oauth] [-p|--password password] [--progress] [-q|--quiet] [--rebuild] [--symlink] [-u|--username username] [-v|--vsmdir VSMDirectory] [-V|--version] [-y] [-z] [--debug] [--repo repopath] [--save] [--olde 12]
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

To Download the latest Perl SDK use 
	(to escape the wild cards used by the internal regex):
	./vsm.sh --dlg Perl-SDK-7\.\*\.x86_64.tar.gz

Use of the Mark option, marks the current product suite as the
favorite. There is only 1 favorite slot available. Favorites
can be downloaded without traversing the menus.
    To Download the latest Perl SDK use 
	(to escape the wild cards used by the internal regex):
	./vsm.sh --dlg Perl-SDK-7\.\*\.x86_64.tar.gz

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
	r or R - Redraw menu
	d or D - Print where you are in the menus
	/searchString - Search for string in current menu, if it exists, 
	go to menu option, or list multiple options (case insensitive)

Example Run:

$ vsm.sh -mr -y -c
Using the following options:
	Version:	6.0.0
	OS Mode:        centos
	VSM XML Dir:	/tmp/vsm
	Repo Dir:	/mnt/rainbow/iso/vmware/depot/content
	Dryrun:		0
	Force Download:	0
	Checksum:	1
	Historical Mode:1
	Symlink Mode:	1
	Reset XML Dir:	0
	Use credstore:	1
	Authenticating... 
	Oauth:		1
Saving to /home/elh/.vsmrc
 1) Datacenter_&_Cloud_Infrastructure
 2) Infrastructure_&_Operations_Management
 3) Networking_&_Security
 4) Infrastructure-as-a-Service
 5) Internet_of_things_[IOT]
 6) Application_Platform
 7) Desktop_&_End-User_Computing
 8) Cloud_Services
 9) Other
10) Exit
#? 1
 1) VMware_vCloud_Suite_Platinum
 2) VMware_vCloud_Suite
 3) VMware_vSphere_with_Operations_Management
 4) VMware_vSphere
 5) VMware_vSAN
 6) VMware_vSphere_Data_Protection_Advanced
 7) VMware_vSphere_Storage_Appliance
 8) VMware_vSphere_Hypervisor_(ESXi)
 9) VMware_vCloud_Director
10) VMware_vCloud_NFV
11) VMware_vCloud_NFV_OpenStack_Edition
12) VMware_Validated_Design_for_Software-Defined_Data_Center
13) VMware_vCloud_Availability_for_vCloud_Director
14) VMware_Cloud_Foundation
15) VMware_vSphere_Integrated_Containers
16) VMware_vCloud_Usage_Meter
17) VMware_vCloud_Availability
18) VMware_vCloud_Availability_for_Cloud-to-Cloud_DR
19) VMware_Skyline_Collector
20) VMware_Cloud_Provider_Pod
21) Back
22) Exit
#? 4
1) VMware_vSphere_6_7
2) VMware_vSphere_6_5
3) VMware_vSphere_6_0
4) VMware_vSphere_5_5
5) VMware_vSphere_5_1
6) VMware_vSphere_5_0
7) Back
8) Exit
#? 1
 1) VMware_vSphere_6_7_Essentials
 2) VMware_vSphere_6_7_Essentials_Plus
 3) VMware_vSphere_6_7_Standard
 4) VMware_vSphere_6_7_Enterprise
 5) VMware_vSphere_6_7_Enterprise_Plus
 6) VMware_vSphere_6_7_Platinum
 7) VMware_vSphere_6_7_Desktop
 8) VMware_vSphere_6_7_vSphere_Scale_Out
 9) Back
10) Exit
#? 5
#? 5
 1) All
 2) ESXI67U2
 3) VC67U2
 4) VRLI_462_VCENTER
 5) NSXV_645
 6) VR812
 7) VROVA_760
 8) VROPS_750
 9) VIC152
10) Mark
11) Back
12) Exit
#? 2
1) ESXI67U2
2) ESXI67U1
3) ESXI670
4) Back
5) Exit
#? 1
1) All
2) VMware-VMvisor-Installer-6.7.0.update02-13006603.x86_64.iso
3) update-from-esxi6.7-6.7_update02.zip
4) VMware-ESXi-6.7U2-RollupISO.iso
5) ESXi6.7U2GA-RollupISO-README.pdf
6) DriversTools
7) CustomIso
8) Back
9) Exit
#? 1
....!
Existing ESXI67U2 in /mnt/rainbow/iso/vmware/depot/content/dlg_ESXI67U2
-++..-++...-++..!
Existing ESXI67U2 in /mnt/rainbow/iso/vmware/depot/content/dlg_ESXI67U2/CustomIso
-++..-++..-++..-++..-++..-++..-++..-++.....!
Existing ESXI67U2 in /mnt/rainbow/iso/vmware/depot/content/dlg_ESXI67U2/DriversTools
1) All
2) VMware-VMvisor-Installer-6.7.0.update02-13006603.x86_64.iso
3) update-from-esxi6.7-6.7_update02.zip
4) VMware-ESXi-6.7U2-RollupISO.iso
5) ESXi6.7U2GA-RollupISO-README.pdf
6) DriversTools
7) CustomIso
8) Back
9) Exit
#? 9 or e or E
```

### Installation
To install use the provided install.sh script which calls the aac-lib/base
installers to install vsm.

To install on Photon OS 3 you must first create a regular user and
pre-install sudo. Then you can follow these instructions.

To install on MacOS X read <a href=https://github.com/Texiwill/aac-lib/blob/master/vsm/MacOS.md>MacOS.md</a>. (Please note this required v6.4.2 or later.)

You can install LOCALLY to your Home Directory, as follows:
```
	wget https://raw.githubusercontent.com/Texiwill/aac-lib/master/vsm/vsm.sh
	mv vsm.sh $HOME/bin
	chmod +x $HOME/bin
```

OR To install for everyone on Linux use the included script, install.sh as follows.
```
	wget https://raw.githubusercontent.com/Texiwill/aac-lib/master/vsm/install.sh
	chmod 755 install.sh
	./install.sh
```
OR If you are outside the America/Chicago timezone you will want to call it as follows:
```
	./install.sh Time/Zone
```

For example to set the time zone for London UK use:
```
	./install.sh 'Europe/London'
```

For example to automatically pick up the time zone use:
```
	./install.sh `timedatectl status | grep "zone" | sed -e 's/^[ ]*Time zone: \(.*\) (.*)$/\1/g' | head -1`
```

### Update
To keep vsm and your repository updated to the latest release/downloads
you can add the following lines to your local cron. This tells the
system to update the installer, then update vsm, then run vsm with your
currently marked favorite. Note 'user' is your username. 

Caveat: This approach only works if you use the aac-lib/base installers to
install vsm. If you did not then just use the last line.

Be sure to Mark a release as your favorite! If you do not, this does
not work. The 'Mark' menu item does this.

Do the following to auto-update LinuxVSM every day at 3AM (Note: update.sh
is only created if you use install.sh to install, inspect the shell
script for the appropriate lines for your own update.sh)

You can UPDATE LOCALLY to your Home Directory, using the following:
```
echo << EOF > $HOME/bin/update.sh
wget https://raw.githubusercontent.com/Texiwill/aac-lib/master/vsm/install.sh
chmod 755 install.sh
./install.sh
EOF
```
The following line Updates VSM at 3AM. You would add using the
command `crontab -e`, where username is your username:
```
0 3 * * * /home/username/bin/update.sh
```

OR to update for everyone on Linux use the following:
```
cp $HOME/aac-base/update.sh /etc/cron.daily
```

The following line starts VSM download at 6AM. You would add using the
command `crontab -e`:
```
0 6 * * * /usr/local/bin/vsm.sh -c -y -mr --favorite
```

The following line starts VSM download at 6AM for multiple favorites. You
would add using the command `crontab -e`, where username is your username:
```
0 6 * * * /home/username/bin/vsm_favorites.sh
```

Where vsm_favorites.sh is taken from the tools directory herein. Please
modify for your favorites.

### Use Case/Examples
See the tools directory and its README.md to see all examples of using
LinuxVSM in scripts

### Support

#### Frequently Asked Questions
##### I received the following error: 

__UnhandledPromiseRejectionWarning: TimeoutError: Timed out after 30000 ms__

If you are using WSL1, please upgrade to WSL2. WSL1 is not supported. If
it is not a WSL issue, rerun with --clean option as the nodejs libraries
are out-of-date or you have a bad credential. Alternatively, there is
a DNS issue (see below).

##### I receive a Long Error message during Login

This is often due to either a VMware website issue, DNS, or bad credentials.

##### I receive a "Credential Error Getting" error

This has four solutions, one is not solvable except by VMware. 

1. If your My VMware account has not been used recently or has no entitlements or trials, it is possible that your VMware Software Manager entitlement has been removed or is not working. You can verify this by using the VMware provided VMware Software Manager on a Windows system and attempt to login. If that works, then it is one of the other issues.

2. If your DNS server is acting up, you may get Credential errors, check that DNS is working.

3. Your credential may be incorrect. Remove your "VSM XML Dir", usually /tmp/vsm (rm /tmp/vsm)  and start over.

4. Use the --clean option and try again.

##### I receive a "Network Error Getting" error

This is usually a sign that DNS is not working or the site is
unavailable. Verify you can reach https://my.vmware.com to verify the
site and DNS. Occassionally VMware does maintenance that causes issues. Or
the DNS server you are working is not working correctly.

##### Do I have to always type in numbers to exit and go backwards, etc?

No, as of version 6.7.6 you can use the following for common commands:

  * a or A - All
  * b or B - Back
  * e or E - Exit
  * x or X - Exit
  * q or Q - Exit
  * m or M - Mark
  * p or P - Patches
  * r or R - Redraw menu
  * d or D - Print where you are in the Menus
  * /searchString - Search for string in current menu, if it exists, go to menu option, or list multiple options (case insensitive)

##### On What operating systems will LinuxVSM run?

  * RHEL 6/7/8, Centos 6/7/8, Fedora
  * Debian 9/10, Ubuntu 18.04/20.04/22.04
  * Microsoft WSL2 (NOT WSL1)
  * MacOSX
  * Alpine Linux 3.15
  * ArchLinux (community tested - @WikiITWizard)

##### I cannot download a package, says not found or nothing appears

VMware has changed the download process to require entitlement for
everything. LinuxVSM does not bypass VMware's entitlement checks.

##### How do I use --dlg, --dlgl

As of Version 6.0.3 the seed datafile is downloaded automatically and
contains those items pertaining to vSphere only. You can add to this
seed file with your specific items by visiting those packages. For
DriversTools and CustomIso's you will actually need to select that option
as well. Once the file is updated with --rebuild you can then use --dlg
and --dlgl with your specific items in addition ot the seed data.

#### Email
Email elh at astroarch dot com for assistance or if you want to add
for more items.
