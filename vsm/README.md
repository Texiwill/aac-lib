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

As of v4.0.0 LinuxVSM now uses the My VMware mode by default. This
implies that previously out of date items are not up to date once more.

Also, you should know that Code Stream is a license ontop of VRA, and
VRA is already in LinuxVSM.

To install use the included script, install.sh as follows.
```
	chmod 755 install.sh
	./install.sh
```
If you are outside the America/Chicago timezone you will want to call it as follows:
```
	./install.sh Time/Zone
```

For example to set the time zone for London UK use:
```
	./install.sh 'Europe/London'
```

Here is an example run and help:
```
$ /usr/local/bin/vsm.sh --help
/usr/local/bin/vsm.sh [--dlg search] [-d|--dryrun] [-f|--force] [--favorite] 
[-e|--exit] [-h|--help] [-l|--latest] [-m|--myvmware] [-mr] [-ns|--nostore] 
[-nc|--nocolor] [--dts|--nodts] [--oem|--nooem] [--oss|--nooss] [-p|--password
password] [--progress] [-q|--quiet] [-r|--reset] [-u|--username username] [-v|--vsmdir VSMDirectory] 
[-V|--version] [-y] [--debug] [--repo repopath] [--save]
    --dlg - download specific package by name or part of a name
    -d|--dryrun - dryrun, do not download
    -f|--force - force download of packages
    --favorite - Download suite marked as favorite
    -e|--exit - reset and exit
    -h|--help - this help
    -l|--latest - substitute latest for each package instead of listed
        Deprecated: Now the default, the argument does nothing any more.
    -m|--myvmware - get missing suite and packages from My VMware. 
        Deprecated: Now the default, the argument does nothing any more.
    -mr - reset just My VMware information, implies -m
    -ns|--nostore - do not store credential data and remove if exists
    -nc|--nocolor - do not output with color
    -p|--password - specify password
    --progress - show progress of downloads (only makes sense with -q)
    -q|--quiet - be less verbose
    -r|--reset - reset vsmdir - Not as useful as it once was -mr is much more
	useful
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
    --debug - debug mode, outputs --progress and useful information on failure
    --repo path - specify path of repo
                  saved to configuration file
    --save - save defaults to $HOME/.vsmrc

    All-style downloads include: All, All_No_OpenSource, Minimum_Required

    Requires packages:
    wget python python-urllib3 libxml2 perl-XML-Twig ncurses

    To Download the latest Perl CLI use (to escape the wild cards):
	$ vsm.sh -mr -y --dlg CLI\.\*\\.x86_64.tar.gz

    Use of the Mark option, marks the current product suite as the
    favorite. There is only 1 favorite slot available. Favorites
    can be downloaded without traversing the menus. To download your 
    favorite use:
	$ vsm.sh -mr -y --favorite -q --progress

    Those items that show up in Cyan are those where My VMware meta data has    
    not been downloaded yet.

    Those items in reverse color (white on black or cyan) are those items
    not downloaded. For packages and not files, the reverse color only
    shows up if the directory is not in the repo and is not related to 
    missing files or new files.

    Caveat: Access to these downloads does not imply you are licensed
    for the material. Please see My VMware for your licenses.

Example Run:

$ vsm.sh -mr -y
Using the following options:
	Version:	    4.0.0
	OS Mode:        centos
	VSM XML Dir:	/tmp/vsm
	Repo Dir:	    /mnt/repo
	Dryrun:		    0
	Force Download:	0
	Reset XML Dir:	0
	Get Latest:	    0
	My VMware:	    1
	Use credstore:	1
Saving to /home/user/.vsmrc
1) Datacenter_Cloud_Infrastructure
2) Infrastructure_Operations_Management
3) Exit
#? 1
1) Datacenter_Cloud_Infrastructure_VMware_Software_Manager
2) Datacenter_Cloud_Infrastructure_VMware_Validated_Design_for_Software_Defined_Data_Center
3) Datacenter_Cloud_Infrastructure_VMware_vCloud_Suite
4) Datacenter_Cloud_Infrastructure_VMware_vSphere
5) Datacenter_Cloud_Infrastructure_VMware_vSphere_with_Operations_Management
6) Back
7) Exit
#? 4
1) Datacenter_Cloud_Infrastructure_VMware_vSphere_6_5
2) Datacenter_Cloud_Infrastructure_VMware_vSphere_6_0
3) Datacenter_Cloud_Infrastructure_VMware_vSphere_5_5
4) Datacenter_Cloud_Infrastructure_VMware_vSphere_5_1
5) Datacenter_Cloud_Infrastructure_VMware_vSphere_5_0
6) Back
7) Exit
#? 1
1) Datacenter_Cloud_Infrastructure_VMware_vSphere_6_5_Essentials
2) Datacenter_Cloud_Infrastructure_VMware_vSphere_6_5_Essentials_Plus
3) Datacenter_Cloud_Infrastructure_VMware_vSphere_6_5_Standard
4) Datacenter_Cloud_Infrastructure_VMware_vSphere_6_5_Enterprise
5) Datacenter_Cloud_Infrastructure_VMware_vSphere_6_5_Enterprise_Plus
6) Datacenter_Cloud_Infrastructure_VMware_vSphere_6_5_Desktop
7) Datacenter_Cloud_Infrastructure_VMware_vSphere_6_5_vSphere_Scale-Out
8) Back
9) Exit
#? 5
 1) All
 2) Minimum_Required
 3) All_Plus_OpenSource
 4) BDE_232
 5) ESXI65U1
 6) NSXV_640
 7) VC65U1E
 8) VDP617
 9) VIC131
10) VR6512
11) VRLI_451_VCENTER
12) VROPS_661
13) VROVA_731
14) Mark
15) Back
16) Exit
#? 14
Favorite: Datacenter_Cloud_Infrastructure_VMware_vSphere_6_5_Enterprise_Plus
Saving to /home/user/.vsmrc
#? 5
 1) All
 2) Minimum_Required
 3) All_Plus_OpenSource
 4) VMware-VMvisor-Installer-6.5.0.update01-5969303.x86_64.iso
 5) update-from-esxi6.5-6.5_update01.zip
 6) VMware-ESXi-6.5U1-RollupISO.iso
 7) ESXi6.5U1-RollupISO-README.pdf
 8) OpenSource
 9) CustomIso
10) DriversTools
11) Back
12) Exit
#? 1
All ESXI65U1 already downloaded
...... 0% [                                       ] 0           --.-K/s              
100%[======================================>] 424         --.-K/s   in 0s      

2018-03-17 18:07:16 (51.9 MB/s) -  Release_Notes_lsi-mr3-7.703.15.00-1OEM.txt  saved [424/424]

...................................................EE......EE!
Downloads  to /mnt/repo/dlg_ESXI65U1/CustomIso
..........................................................................................................................!
All ESXI65U1 DriversTools already downloaded!
 1) All
 2) Minimum_Required
 3) All_Plus_OpenSource
 4) VMware-VMvisor-Installer-6.5.0.update01-5969303.x86_64.iso
 5) update-from-esxi6.5-6.5_update01.zip
 6) VMware-ESXi-6.5U1-RollupISO.iso
 7) ESXi6.5U1-RollupISO-README.pdf
 8) OpenSource
 9) CustomIso
10) DriversTools
11) Back
12) Exit
#? 12
```

### Installation
To install use the provided install.sh script which calls the aac-lib/base installers to install vsm.

### Update
To keep vsm and your repository updated to the latest release/downloads
you can add the following lines to your local cron. This tells the
system to update the installer, then update vsm, then run vsm with your
currently marked favorite. Note 'user' is your username. 

Caveat: This approach only works if you use the aac-lib/base installers to
install vsm. If you did not then just use the last line.

Be sure to Mark a release as your favorite! If you do not, this does
not work. The 'Mark' menu item does this.

I added these lines to a script within /etc/cron.daily (which usually runs at 3AM):
```
cd /home/user/aac-base
./aac-base.install -u
./aac-base.install -i vsm
```

The following line starts VSM download at 6AM. You would add using the command `crontab -e`:
```
0 6 * * * /usr/local/bin/vsm.sh -y -mr --favorite
```

### Support
Email elh at astroarch dot com for assistance or if you want to add
for more items.

### Changelog
4.0.4 - MacOS Support

4.0.3 - Small Bug with --dlg fixed, plus initial download speedup

4.0.2 - Support for VC55U3H, 60U3 fixes, and --dlg updates thanks to Michelle Laverick (@m_laverick)

4.0.1 - Support for VC65U1G plus bugfix from Alex Lopez (@ivirtualex)

4.0.0 - My VMware now default, cleaned up Debug more

3.9.0 - Added Debian Support

3.8.1 - Hopefully the last progress issue

3.8.0 - One more progress issue.

3.7.9 - Bug fix in progress. My thanks to Alex Lopez (@ivirtualex) for finding.

3.7.8 - Bug fix when missing .vsmrc, fixes to progress. My thanks to Alex
Lopez (@ivirtualex) for finding the bug.

3.7.7 - slight change to versioning of a package

3.7.6 - Changes to how .vsmrc is processed to support Docker. .vsmrc can 
now be in $HOME, Repo Dir, or VSM XML Dir (/tmp/vsm). If the .vsmrc is
in any directory besides the default or $HOME you will need to specify
the --repo or -v|--vsmdir options and order is important.

3.7.5 - Fix to progress bars once more, should be final form. Added another
suite and fixed more broken due to new version downloads.

3.7.4 - Fixed missing progress when -nq specified

3.7.3 - Improved progress to include download progress

3.7.2 - Minor bug fix to allow proper download of VRNI

3.7.1 - Minor bug fix when encountering My VMware package that contains
VSM packages, added quiet and progress flags, and a slight code reorganization.

3.7.0 - CustomIso (OEM), and DriverTools can now be downloaded for all
My VMware packages where they exist.

3.6.0 - -mr now implies -m, added Mark capability to -m, fixed wget not
	using cookies all the time

3.5.5 - Fixed download of VVD issue 

3.5.4 - Fixed download directory issue

3.5.3 - More option issues corrected.

3.5.2 - Fixed some downloads (VRLI for vCenter and others) thanks to fellow 
	vExperts Michael Rudluff and Rotem Agmon

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
