# aac-lib
AAC Library of Tools

- <a href=https://github.com/Texiwill/aac-lib/tree/master/>List of Tools</a>

## BASE 

### Description
A bash script to automatically install all the requirements to use Puppet
as the configuration manager for CentOS/RHEL installations as well
as other one off installations such as PowerCLI w/PowerNSX, ovftool,
DNSCrypt, fpm, and Puppet Server.

Why did I create these scripts?  To help keep my configuration up to date
across Linux and to install specific items like PowerCLI and
DNSCrypt. While the scripts are pretty generic they are targeted for
CentOS/RHEL 6 or 7 builds. In addition, since VMware is no longer working
on the vSphere Management Appliance, I have created one to
replace/improve, that includes PowerCLI, PowerNSX, vCLI, and ovftool.


The problem is that some one offs work better installed via
scripts. Configuring the puppet server for example is one such.

### Installation
Run the script using SUDO as root access is required.  The scripts can install
the latest 4.0 puppet agent, powercli, dnscrypt, and fpm. Puppet-server
configurations are also coming. The standard install will load the proper
timezone, EPEL repository, and SELinux policy RPMs automatically. The
rest is up to you. Here is how it looks.

	# sudo ./aac-base.install
	Checking Timezone settings
	Checking for EPEL repository
	Checking for SELinux Policy RPMS
	If SELinux issues pop up use the following to debug:
		sealert -a /var/log/audit/audit.log
	1) aac-base.install.dnscrypt	5) aac-base.install.fpm
	2) aac-base.install.powercli	6) Exit
	3) aac-base.install.puppetbase
	#? 

We verify timezones, repositories, and SELinux bits are installed then
prompt for the actions to take. Puppetbase is the first one for my nodes
and the rest are for one off services not install by puppet currently.

You can also call the script with the tail end of the available install
scripts as well. Such as:

	# sudo ./aac-base.install -i powercli

The usage of the script is:

	sudo ./aac-base.install [--update|-u] [--install|-i installer] [--help|-h] [timezone]
	--update|-u - update the script(s), then reload

Use the following script, which requires sudo, to get everything to run
these installers:

<pre>
which wget >& /dev/null
if [ $? -eq 1 ]
then
    sudo yum -y install wget
fi

wget -O aac-base.install https://raw.githubusercontent.com/Texiwill/aac-lib/master/base/aac-base.install
chmod +x aac-base.install
./aac-base.install -u
sudo ./aac-base.install
</pre>

### Installers

#### Base
Installs the base AAC setup. This is mostly setting timezones and ensuring wget and other useful tools are available.

#### dnscrypt
Installs and compiles DNScrypt. After install, the compilers, and other
tools are removed. This configure dnsmasq and dnscrypt to make a DNS
server. It is up to you to set firewall rules to route all port 53 items
to this DNS Crypt server.

In addition, it installs a script that changes the DNS crypt server used
daily based on some basic rules. Such as Country, Style, etc.

#### powercli
Installs Powershell, VMware PowerCLI, and VMware PowerNSX onto any RPM
based Linux distribution.

#### vcli
Installs vSphere CLI using vsm to download the latest file.

#### ovftool
Installs ovftool using vsm to download the latest file.

#### vma
Installs vsm, powercli, ovftool, and vcli to create a vSphere Management
Appliance. 

#### vsm
Install a port of VMware's Software Manager to Linux.

#### puppetbase
Installs the Puppet 4.x agents for use with a Puppet Server.

### Todo
Build out Puppet 4.0 framework for my virtualized environment.
Create a REPO for build/install later

### Support
Email elh at astroarch dot com for assistance or if you want to add
more items.

### Changelog
1.5 update to ovftool installer to include ov-import.sh

1.4 update function added

1.3 updates to ensure -i option works with further includes for VSM

1.2-vcli, vsm, ovftool, vma. Added VSM installer, but updated vma to install vsm and vcli and ovftool to call vsm

1.1-powercli Improved Powershell install to use the latest files

1.1-vcli Added perl-XML-LibXML from CentOS/RHEL Repos over VMware's to
get rid of Gthr error
