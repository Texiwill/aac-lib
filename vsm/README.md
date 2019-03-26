# aac-lib
AAC Library of Tools

- <a href=https://github.com/Texiwill/aac-lib/tree/master/>List of Tools</a>

## vsm
Linux Version of VMware Software Manager

### Description
A slightly more intelligent version of VSM for Linux and MacOS. It ignores
missing definition files that cause the VMware version to stop working. It
also finds packages not in the definitions yet. It is also possible to find
the latest of every package.

As of v4.0.0 LinuxVSM now uses the My VMware mode by default. This
implies that previously out of date items are now up to date once more.

As of v5.3.2 LinuxVSM now requires --oauth to be used to work properly. This
is due to a change from VMware.

As of 5.3.5 the --oauth option is deprecated as Oauth is forced to be
used for all metadata downloads.

Also, you should know that Code Stream is a license ontop of VRA, and
VRA is already in LinuxVSM.

To install on MacOS X read <a href=https://github.com/Texiwill/aac-lib/blob/master/vsm/MacOS.md>MacOS.md</a>.

To install on Linux use the included script, install.sh as follows.
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

For example to automatically pick up the time zone use:
```
	./install.sh `timedatectl status | grep "zone" | sed -e 's/^[ ]*Time zone: \(.*\) (.*)$/\1/g'`
```

Here is an example run and help:
```
$ /usr/local/bin/vsm.sh --help
/usr/local/bin/vsm.sh [-c|--check] [--dlg|--dlgl search] [-d|--dryrun]
[-f|--force] [--fav favorite] [--favorite] [-e|--exit] [-h|--help]
[--historical] [-l|--latest] [-m|--myvmware] [-mr] [-ns|--nostore]
[-nc|--nocolor] [--dts|--nodts] [--oem|--nooem] [--oss|--nooss] [--oauth]
[-p|--password password] [--patches] [--progress] [-q|--quiet] [-r|--reset]
[-u|--username username] [-v|--vsmdir VSMDirectory] [-V|--version]
[-y] [-z|--compress] [--debug] [--repo repopath] [--save] [--symlink]
[--fixsymlink]
    -c|--check - do sha256 check against download
    --clean - remove all metadata including credential store
    --dlg - download specific package by name or part of a name (regex)
    --dlgl - list package by name or part of a name (regex)
    -d|--dryrun - dryrun, do not download
    -f|--force - force download of packages
    --fav favorite - specify favorite on command line, implies --favorite
    --favorite - Download suite marked as favorite
    -e|--exit - reset and exit
    -h|--help - this help
    --historical - display older versions when you select a package *
                   saved to configuration file
    -l|--latest - substitute latest for each package instead of listed
        Deprecated: Now the default, the argument does nothing any more.
    -m|--myvmware - get missing suite and packages from My VMware. 
        Deprecated: Now the default, the argument does nothing any more.
    -mr - reset just My VMware information, implies -m
    -ns|--nostore - do not store credential data and remove if exists
    -nc|--nocolor - do not output with color
    --oauth - Fall back to Oauth login method. If you have access in 
              My VMware, then will download if VSM method fails. If no 
              access, no download. 
              Deprecated: Now the default, the argument does nothing any more.
    -p|--password - specify password
    --progress - show progress of downloads (only makes sense with -q)
    -q|--quiet - be less verbose
                 saved to configuration file
    -r|--reset - reset vsmdir - Not as useful as it once was -mr is much more
	         useful
    --symlink - create symlinks for CustomIso, DriversTools, and 
                OpenSource modules. Saved to configuration file
    --fixsymlink - convert older repo to newer symlink style, implies --symlink
    -u|--username - specify username
    -v|--vsmdir path - set VSM directory
                       saved to configuration file
    -V|--version - version number
    -y - do not ask to continue
    -z|--compress - compress files after download
                    saved to configuration file
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

$ vsm.sh -mr -y -c
Using the following options:
	Version:	4.5.0
	Data Version:   1.0.0
	OS Mode:        centos
	VSM XML Dir:	/tmp/vsm
	Repo Dir:	/mnt/repo
	Dryrun:		0
	Force Download:	0
	Checksum:       1
	Reset XML Dir:	0
	My VMware:	1
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
   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
   Use the above line with the --fav line to get all of vSphere 6.5 Enterprise+

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
#? 5 (Shows only if --historical in use)
1) ESXI65U2
2) ESXI65U1
3) ESXI650D
4) ESXI650
5) ESXI650A
6) Back
7) Exit
#? 1
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

Release_Notes_lsi-mr3-7.703.15.00-1OEM.txt: check passed

...................................................EE......EE!
Downloads  to /mnt/repo/dlg_ESXI65U1/CustomIso
..........................................................................................................................!
All ESXI65U1 DriversTools already downloaded!
All sha256sum Check Sums Passed

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

Do the following to auto-update LinuxVSM every day at 3AM (Note: update.sh
is only created if you use install.sh to install, inspect the shell
script for the appropriate lines for your own update.sh)
```
cp $HOME/aac-base/update.sh /etc/cron.daily
```

The following line starts VSM download at 6AM. You would add using the
command `crontab -e`:
```
0 6 * * * /usr/local/bin/vsm.sh -c -y -mr --favorite
```

The following line starts VSM download at 6AM for multiple favorites. You
would add using the command `crontab -e`:
```
0 6 * * * ~/bin/vsm_favorites.sh
```

Where vsm_favorites.sh is taken from the tools directory herein. Please
modify for your favorites.

### Use Case/Examples
See the tools directory and its README.md to see all examples of using
LinuxVSM in scripts

### Support

#### Frequently Asked Questions
* I receive a "Credential Error Getting" error

This has three solutions, one is not solvable except by VMware. 

1. If your My VMware account has not been used recently or has no entitlements or trials, it is possible that your VMware Software Manager entitlement has been removed or is not working. You can verify this by using the VMware provided VMware Software Manager on a Windows system and attempt to login. If that works, then it is one of the other issues.

2. If your DNS server is acting up, you may get Credential errors, check that DNS is working.

3. Your credential may be incorrect. Remove your "VSM XML Dir", usually /tmp/vsm (rm /tmp/vsm)  and start over.

* I receive a "Network Error Getting" error

This is usually a sign that DNS is not working or the site is
unavailable. Verify you can reach https://my.vmware.com to verify the
site and DNS. Occassionally VMware does maintenance that causes issues. Or
the DNS server you are working is not working correctly.

* On What operating systems will LinuxVSM run?

  * RHEL 6/7, Centos 6/7, Fedora 14/19
  * Debian 9.x, Ubuntu 17.10 (or higher)
  * MacOS High Siera, MacOS Mojave
  * Embedded Ubuntu within Windows 10 (community tested - @magneet_nl)
  * ArchLinux (community tested - @WikiITWizard)

#### Email
Email elh at astroarch dot com for assistance or if you want to add
for more items.
