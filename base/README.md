# aac-lib
AAC Library of Tools

- <a href=https://github.com/Texiwill/aac-lib/tree/master/>List of Tools</a>

## BASE 

### Description
A bash script to automatically install all the requirements to use Ansible
to add functionality to a Linux installations. This includes Ansible playbooks
to install PowerCLI w/PowerNSX & PowerVRA, ov-import/ovftool, DNSCrypt,
vctui, LinuxVSM, vCLI, DCLI, and others.

Why did I create these scripts?  To help keep my configuration up
to date across Linux and to install specific items like PowerCLI and
DNSCrypt. While the scripts are pretty generic they are targeted for
CentOS/RHEL builds, they should also work on Debian distributions as
well. In addition, since VMware is no longer working on the vSphere
Management Appliance, I have created one to replace/improve, that includes
PowerCLI, PowerNSX, PowerVRA, vCLI, LinuxVSM, vctui, ov-import.sh,
and ovftool.

The problem is that you need to install a few things before you can
begin to use Ansible. The main script installs all those necessary bits,
then switches to use Ansible.

LinuxVMA documentation is at <a href=https://github.com/Texiwill/aac-lib/tree/base/LinuxVMA.md>Here</a>.

#### Supported Operating Systems
Full support for LinuxVMA/LinuxVSM is available for:

* RHEL/CentOS 7
* RHEL/CentOS 8
* Debian 9
* Debian 10
* Debian 11
* Ubuntu 18.04
* Ubuntu 20.04
* Ubuntu 22.04
* PhotonOS 3 - requires creating an account and installing sudo to use
* Rocky 9
* AlmaLinux 9

WSL2 also works per the community
* Now for LinuxVSM 6.4.x

MacOSX support exists:
* Now for LinuxVSM 6.4.x

### Installation
Run the following:

	wget -O aac-base.install https://raw.githubusercontent.com/Texiwill/aac-lib/master/base/aac-base.install
	./aac-base.install -u

### Usage
Run the script and if root access is required you will be asked to
provide sudo credentials

	$ ./aac-base.install
	Get wget
	Checking for EPEL repository
	Checking for Ansible
	1) LinuxVSM    4) dropbox    7) vctui	  10) dcli
	2) PowerCLI    5) ovftool    8) vma	  11) Exit
	3) dnscrypt    6) vCLI	     9) LinuxVMA
	#? 

We verify timezones, repositories, and SELinux bits are installed then
prompt for the actions to take. 

You can also call the script with the tail end of the available install
scripts as well. Such as:

	# ./aac-base.install -i powercli

The usage of the script is:

	Usage: ./aac-base.install [--install|-i installer] [--update|-u] [-v|--version] [--help|-h] [--noansible|-n] [--user USER] [--home HOME] [timezone]
		-u|--update => Update
		-i|--install => Install
		-V|--version => version
		-v|--verbose => verbose Ansible
		-n|--noansible => No Ansible, older shell script approach
		Last Argument is used to set the timezone
		Default timezone America/Chicago

Use the following script, to keep everything up to date. If wget is not
installed it will ask for it.

<pre>
which wget >& /dev/null
if [ $? -eq 1 ]
then
    sudo yum -y install wget
fi

wget -O aac-base.install https://raw.githubusercontent.com/Texiwill/aac-lib/master/base/aac-base.install
chmod +x aac-base.install
./aac-base.install -u
</pre>

### Installers

#### Base - 2.x
Installs the base AAC setup. This is mostly setting timezones and ensuring wget and ansible are availabile

#### powercli - 1.0.6
Installs Powershell and VMware PowerCLI: run command 'powercli' to start

#### vcli - 1.0.3
Installs vSphere CLI using LinuxVSM to download the latest file.

#### dcli - 1.0.2
Installs Datacenter CLI (DCLI)

#### ovftool - 1.0.3
Installs ovftool using LinuxVSM to download the latest file.

#### LinuxVMA - 1.0.3
Installs LinuxVSM, PowerCLI, ov-import.sh, ovftool, DCLI, and vcli to create
a Linux vSphere Management Appliance.  PowerCLI includes Powershell,
PowerCLI, PowerNSX, and PowerVRA.

#### LinuxVSM - 1.1.2
Install a port of VMware's Software Manager to Linux - LinuxVSM.

#### vctui - 1.0.6
Installs the vctui tool for connecting to vCenter.

#### dropbox - 1.0.0
Installs the Docker Container version of Dropbox for system wide use

#### dnscrypt - 1.0.0
Installs DNSCrypt Proxy 2.x

#### isolib - 1.0.0
Installs isolib.sh 

#### LinuxVDI - 1.0.0
Linux based VDI install

#### pxeboot - 1.0.0
Linux pxeboot server setup for OS Images. Tested only on Rocky 9

#### pihole - 1.0.0
Linux pihole server setup including TLS and SELinux support. Tested only on Rocky 9

#### mariadb - 1.0.0
Linux Mariadb network server. Tested only on Rocky 9

### Support
Email elh at astroarch dot com for assistance or if you want to add
more items.

Base 2.2.1, LinuxVSM, dCLI, vctui, and isolib tested against CentOS 7,8,9; Rocky 9, AlmaLinux 9, Fedora 39, Ubuntu 22.04.3

### Changelog
2.2.2 Base - Fixed update issues

1.0.7 PowerCLI - updates

2.2.1 Base - Support for AlmaLinux, Rocky

1.1.3 LinuxVSM - Support for Rocky/AlmaLinux and better support for all other OSes

1.0.3 dCLI - Updated for latest dCLI

1.0.7 vctui - Updated for latest vctui

1.0.1 isolib - Updated for only RedHat Family of OS

1.1.2 LinuxVSM - Support for Ubuntu 22.04

1.1.1 LinuxVSM - Support for Alpine

2.1.7 Changes to support Alpine 

1.1.0 LinuxVSM - Support for Debian 11

2.1.6 Changes to support Big Sur

2.1.5 Changes to always ask for password when using ansible/vCLI updates for Photon OS and RHEL8

2.1.4 Changes to support Photon OS 3

2.1.3 Change to improve Ubuntu on WSL

2.1.2 Change to help and WSL support

2.1.1 Updates if wget does not already exist/LinuxVSM installer update

2.1.0 Beginning MacOSX support, Fixes for Debian 9, RHEL 8, Ubuntu 20

2.0.4 LinuxVMA / vma mapping

2.0.3 Fix: translate vsm to LinuxVSM, add python-pip dependency for Ubuntu

2.0.2 Fix to not use -K for ansible-playbook when running already as root

2.0.1 Fix a permission issue with vma playbook, missing dependicies for vctui

2.0.0 Move to Ansible

1.7.2 VSM: changes to accomodate fedora

1.6.1 PowerCLI: changes to update

1.5.7 vCLI: missing package dependency

1.5.6 vCLI: support for vCLI 6.7

1.7.4 Base: Fixed issue with empty dependencies

1.6.0 PowerCLI: Support for PowerCLI 10.x and Latest PowerShell + Debian

1.7.3 Base: Changes to package management and error output

2.0.0 DNSCRYPT: Update to 2.x

1.1.1 OVFTOOL: Support for Debian and latest LinuxVSM

1.7.1 Base: Support for --user

1.5.4 VCLI: Support for Debian

1.7.0 Base/VSM: Support for Debian/Ubuntu

1.5.3 VMA: Wrong package installed

1.1.0 OVF: Updated to use hiera and added -v1 option to use old config files

1.6.1 VSM: added jq to dependencies

1.0.1 DNScrypt: switched to use GitHub for code and updates

1.6.4 moved update to not require root

1.6.3 fixed startsrv to always restart

1.6.2 added -h|--home option

1.5.2 VCLI: 1.0.1 OVFTOOL: update to add -f to vsm

1.5.1 VCLI: Added perl-Socket6 to required packages

1.5.1 VSM: removed vsm.sh if it exists in directory from which installer was run

1.6.1 added versions for all sub installers

1.6 fixed a missing end quote

1.5 update to ovftool installer to include ov-import.sh

1.4 update function added

1.3 updates to ensure -i option works with further includes for VSM

1.2-vcli, vsm, ovftool, vma. Added VSM installer, but updated vma to install vsm and vcli and ovftool to call vsm

1.1-powercli Improved Powershell install to use the latest files

1.1-vcli Added perl-XML-LibXML from CentOS/RHEL Repos over VMware's to
get rid of Gthr error
