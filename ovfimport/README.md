# aac-lib
AAC Library of Tools

- <a href=https://github.com/Texiwill/aac-lib/tree/master/>List of Tools</a>

## import
This script uses ovftool (originally govc) to import OVA/OVFs into VMware
vSphere providing the following benefits:

	* Import a directory of OVA/OVFs, including those in a .zip file
	* Uses a key/value configuration file for storing settings, 
	* the ability to specify the name of the keys for a run. To allow import of different instances of the same OVA/OVF
	* Aids in deploying by listing possible settings not already covered by the key/value configuration file

ov-import.sh will automatically unpack .zip files containing OVFs and its files as well as take a single OVA/OVF as an argument.

While this work started with the govc-import.sh it soon transitioned to
the ov-import.sh as ovftool handles all the OVA/OVFs generally used. Govc
still has some issues with vApps and networking. Future updates and
testing will be made against the ov-import.sh. The govc-import.sh is
provided for those wishing to use it.

The why of this script is to aid in disaster recovery and creation of
new environments easily. Put all the OVAs/OVFs in one place and let the
tool do the work after some minor configuration. 

These tools read all the options for an OVA/OVF and allows settings to
be specified for all of them as necessary.

### Description
The govc-import.sh tool requires govc and json_reformat from the YAJL
(Yet Another JSON Library) software package. Without which this script
will not work so we check for these to be somewhere within your path.

The ov-import.sh tool requires ovftool to be installed

The scripts require some default settings for govc/ovftool, which we
look for in $HOME/.govc. Govc and ovftool will ask for passwords so you
do not need to put one in the file if you choose not to do so.

export GOVC_INSECURE=1
export GOVC_URL=VCENTER_SERVER_NAME
export GOVC_USERNAME=IMPORT_LOGIN
export GOVC_PASSWORD=IMPORT_PASSWORD
export GOVC_DATASTORE=DEFAULT Datastore
export GOVC_NETWORK=Network
export GOVC_RESOURCE_POOL='/Datacenter/host/Cluster/Resources'
export GOVC_DATACENTER=DatacenterName

We also read the $HOME/.ov-defaults, ./.ov-defaults, or the
.ov-defaults stored with the ov-import.sh script file for specific
configuration options for the OVAs/OVFs to import.

Here is a sample .ov-defaults. These defaults represent some
global settings for gateway, dns, netmask, vSwitch, and network. Each of
these can be overridden by a follow on setting representing the OVA/OVF
to import. In this case we have given ip addresses for vSphere Data
Protection, vSphere Management Assistant, and VSAN Witness. The Witness
actually requires a second vSwitch and portgroup for VSAN traffic. We set
those within the .ov-defaults file as well. The ov-defaults can also
have a password setting on a per OVA/OVF basis. If one is not present,
the import script will ask for it. If you use PASSWORD here, govc will
ask for it on import. If the password is blank PASSWORD will also be
used so govc can ask for it directly. There is also a richer ov-defaults
included in this repository.

ovtfool does not ask for passwords within the import. The govc tool does
not handle vServices but the ovftool script does. See below for those
OVA/OVF tested.

The following is from the included ov-defaults file:
	- #
	- # Findings from testing
	- 1 noimport-vSphere_Replication_AddOn_OVF10
	- #
	- ## Specific deployment option
	- normal deployment-VMware-VirtualSAN-Witness
	- #
	- ## for govc-import.sh
	- 1 remap-h5ngcVA
	- 1 remap-vMA
	- 1 remap-vSphere_Replication_OVF10
	- #
	- ## Where to break pre-check lookups
	- ip break-vMA
	- vswitch break-VMware-VirtualSAN-Witness
	- #
	- # general import settings
	- 192.168.1.1 gw-global
	- 192.168.1.2 dns-global
	- 255.255.255.0 netmask-global
	- vSwitch0 vswitch-global
	- VMNetwork network-global
	- example.com domain-global
	- false ssh-global
	- false ceip-global
	- #
	- # Per OVA/OVF settings
	- PASSWORD password-VMware-VirtualSAN-Witness
	- PASSWORD password-VMware-Support-Assistant-Appliance
	- PASSWORD password-vSphere_Replication_OVF10
	- PASSWORD password-VMware-vRO-Appliance
	- vro.example.com hostname-VMware-vRO-Appliance
	- vra.example.com hostname-VMware-vR-Appliance

Usage follows:
govc-import.sh [[-p|--precheck]|[-d|--dryrun]|[-n|--nocleanup]|[-h|--help]]

or

ov-import.sh [-y|--name Key-Name-to-use] [-p|--precheck] [-d|--dryrun] [-n|--nocleanup] [-h|--help] [ova/ovf to import]

	-y|--name specifies the name part of the Key to use within the .ov-defaults file
	-p|--precheck prechecks the OVA or OVF for missing options
	-d|--dryrun runs all but the final import. This will create a file named filename.a.txt which contains the final import command
	-n|--nocleanup is implied by --dryrun. The *.a.txt files are kept around as are any unpacked ZIP or mounted ISO images
	-h|--help displays the help
	ova/ovf/ZIP/iso to import is the last argument, allowing to specify a specfic file instead of all OVAs, OVFs, and ZIP files within the current directory. This is the only way to import from an ISO image.

General usage is really a three step process:
	* move the OVAs/OVFs into a single directrory
	* Precheck for settings using: ov-import.sh --dryrun
	* Fix any missing items or use defaults if available
	* Import the OVAs/OVFs using: ov-import.sh


The --dryrun will do everything but the final import, which is
a good way to look at the created ovfname.a.txt files. The a.txt files
contain useful information about defaults that are needed as well as
the actual ovftool command to be run, but was not.

Use of --dryrun will tell you what is missing from the .ov-defaults file.

We have tested these scripts ([GOVC,OV]) against the following VMware
Products and the results are as expected, working:

	These products work in both scripts:
	* VMware Virtual SAN Witness Appliance [GOVC|OV]
	* VMware vSphere Web Client (h5ngcVA) [GOVC|OV]
	* VMware vSphere Management Assistant (VMA) [GOVC|OV]
	* VMware vSphere Data Protection (VDP) [GOVC|OV]
	* VMware vRealize Orchestrator (VROVA) [GOVC|OV]
	* VMware vRealize Appliance (VRA) [GOVC|OV]

	These products work only with ov-import.sh:
	* VMware vRealize Business for Cloud (VRBC) [OV]
	* VMware vRealize Infrastructure Navigator (VIN) [OV]
	* VMware vRealize Log Insight (VRLI) [OV]
	* VMware vRealize Operations Manager (VROPS) [OV]
	* VMware NSX Manager (NSXV) [OV]
	* VMware Integrated Containers/Harbor (VIC) [OV]
	* VMware vRealize Network Insight (VRNI) [OV]
	* VMware Cloud Volumes formerly VMware App Volumes [OV]
	* VMware vSphere Replication Server (VR) [OV]
	* VMware Big Data Extensions (BDE) [OV]
	* VMware vCenter Server Appliance (VCSA) [OV]

And these unofficial OVA/OVFs:
	* <a href="http://www.virtuallyghetto.com/2016/11/esxi-6-5-virtual-appliance-is-now-available.html">William Lam's Nested ESXi Appliance</a> [OV]

And the following Third Party Products:

	* DoubleCloud VSearch [GOVC|OV]
	* IxiaDeveloper [OV]
	* Runecast Analyzer [OV]
	* SIOS iQ [OV]
	* Unitrends Enterprise Backup [OV]
	* Turbonomic formerly VMTurbo Ops Manager [OV]
	* Solarwinds Virtualization Manager [OV]

Do not use on the following:
	* End User Computing Access Point (it is better to use <a href=https://communities.vmware.com/docs/DOC-30835>apdeploy</a>)

### Installation
Get a copy of govc or ovftool, then place the script anywhere
convenient. Then create a .ov-defaults and .govc file as appropriate.
Govc-import is really on hold now until govc also improves.

### Support
Email elh at astroarch dot com for assistance or if you want to add
for more items.

### Changelog
1.7 Updated README

1.6 Added License

1.5 Fixed import of specific images. Added support to import based on specified keynames for importing more than one of the same OVA or OVF. (useful for importing nested ESXi labs)

1.4 Fixed support for Nested ESXi Appliance, it was missing some properties

1.3 Support for ISO images such as VCSA plus change how we handle ZIP files. Specify the ZIP file or ISO on the command line and they are extracted into separate directories. They are not handled if just in the directory.

1.2 updates to support Nested ESXi Appliance with the need for the --allowAllExtraConfig option to ovftool

1.1 changed forceIpv6 to be just ipv6 in lookup with a directive to look up the exact keyvalue pair. 

1.0 first release
