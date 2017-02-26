# aac-lib
AAC Library of Tools

- <a href=https://github.com/Texiwill/aac-lib/tree/master/>List of Tools</a>

## import
2 scripts to use govc or ovftool to import a directory full of ova and
ovf files. The ovftool will automatically unpack .zip files containing
OVFs and its files as well as take a single OVA/OVF as an argument.

While this work started with the govc-import.sh it soon transitioned to
the ov-import.sh as ovftool handles all the OVA/OVFs generally used. Govc
still has some issues with vApps and networking. Future updates and
testing will be made against the ov-import.sh. The govc-import.sh is
provided for those wishing to use it.

The why of this script is to aid in disaster recovery and creation of
new environments easily. Put all the OVAs/OVFs in one place and let the
tool do the work after some minor configuration. This tool does not import vCenter as that is handled by many other scripts.

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
.ov-defaults stored with the govc-import.sh script file for specific
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
	#
	# Findings from testing
	1 noimport-vSphere_Replication_AddOn_OVF10
	#
	## Specific deployment option
	normal deployment-VMware-VirtualSAN-Witness
	#
	## for govc-import.sh
	1 remap-h5ngcVA
	1 remap-vMA
	1 remap-vSphere_Replication_OVF10
	#
	## Where to break pre-check lookups
	ip break-vMA
	vswitch break-VMware-VirtualSAN-Witness
	#
	# general import settings
	192.168.1.1 gw-global
	192.168.1.2 dns-global
	255.255.255.0 netmask-global
	vSwitch0 vswitch-global
	VMNetwork network-global
	example.com domain-global
	false ssh-global
	false ceip-global
	#
	# Per OVA/OVF settings
	PASSWORD password-VMware-VirtualSAN-Witness
	PASSWORD password-VMware-Support-Assistant-Appliance
	PASSWORD password-vSphere_Replication_OVF10
	PASSWORD password-VMware-vRO-Appliance
	vro.example.com hostname-VMware-vRO-Appliance
	vra.example.com hostname-VMware-vR-Appliance

Usage follows:
govc-import.sh [[-p|--precheck]|[-d|--dryrun]|[-n|--nocleanup]|[-h|--help]]

or

ov-import.sh [[-p|--precheck]|[-d|--dryrun]|[-n|--nocleanup]|[-h|--help]] [ova/ovf to import]

General usage is really a three step process:
	- move the OVAs/OVFs into a single directrory
	- Precheck for settings using: [g]ov[c]-import.sh --precheck
	- Fix any missing items or use defaults if available
	- Import the OVAs/OVFs using: [g]ov[c]-import.sh

Govc: The --dryrun will do everything but the final import, which is a good
way to look at the created json files or the modified OVF files. Some
tools have malformed OVF files according to govc, so they need to be
modified directly. The script does this by creating a new.ovf and using
that for import after taking the corrective actions.  So far the
ones we have found are for the vSphere Web Client and the Management
Assistant. You mark those in the ov-defaults file using the remap keyword
as seen in the example file.

Ovftool: The --dryrun will do everything but the final import, which is
a good way to look at the created ovfname.a.txt files. The a.txt files
contain useful information about defaults that are needed as well as
the actual ovftool command to be run, but was not.

Use of --dryrun will tell you what is missing from the .ov-defaults file.

We have tested these scripts ([GOVC,OV]) against the following VMware
Products and the results are as expected, working:

	These products work in both scripts:
	- VMware Virtual SAN Witness Appliance [GOVC|OV]
	- VMware vSphere Web Client (h5ngcVA) [GOVC|OV]
	- VMware vSphere Management Assistant (VMA) [GOVC|OV]
	- VMware vSphere Data Protection (VDP) [GOVC|OV]
	- VMware vRealize Orchestrator (VROVA) [GOVC|OV]
	- VMware vRealize Appliance (VRA) [GOVC|OV]

	These products work only with ov-import.sh:
	- VMware vRealize Business for Cloud (VRBC) [OV]
	- VMware vRealize Infrastructure Navigator (VIN) [OV]
	- VMware vRealize Log Insight (VRLI) [OV]
	- VMware vRealize Operations Manager (VROPS) [OV]
	- VMware NSX Manager (NSXV) [OV]
	- VMware Integrated Containers/Harbor (VIC) [OV]
	- VMware vRealize Network Insight (VRNI) [OV]
	- VMware Cloud Volumes formerly VMware App Volumes [OV]
	- VMware vSphere Replication Server (VR) [OV]

And the following Third Party Products:

	DoubleCloud VSearch [GOVC|OV]
	IxiaDeveloper [OV]
	Runecast Analyzer [OV]
	SIOS iQ [OV]
	Unitrends Enterprise Backup [OV]
	Turbonomic formerly VMTurbo Ops Manager [OV]
	Solarwinds Virtualization Manager [OV]

Unknown at this time:
	VMware Big Data Extensions (BDE)

### Installation
Get a copy of govc or ovftool, then place the script anywhere
convenient. Then create a .ov-defaults and .govc file as appropriate.

### Support
Email elh at astroarch dot com for assistance or if you want to add
for more items.

### Changelog
1.1 changed forceIpv6 to be just ipv6 in lookup with a directive to look up the exact keyvalue pair. 

1.0 first release
