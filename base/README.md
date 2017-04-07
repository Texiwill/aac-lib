# aac-lib
AAC Library of Tools

- <a href=https://github.com/Texiwill/aac-lib/tree/master/>List of Tools</a>

## BASE 

### Description
A bash script to automatically install all the requirements to use Puppet
as the configuration manager for CentOS/RHEL installations as well
as other one off installations such as PowerCLI w/PowerNSX, DNSCrypt,
and Puppet Server.

Why did I create these scripts?  To help keep my configuration up to date
across Linux and to install specific items like PowerCLI and
DNSCrypt. While the scripts are pretty generic they are targeted for
CentOS/RHEL 6 or 7 builds.

The problem is that some one offs work better installed via
scripts. Configuring the puppet server for example is one such.

### Installation
Run the script using SUDO as root access is required.  The script installs
the latest 4.0 puppet agent and the possibility of powercli, dnscrypt,
and puppet-server as well as any required puppet modules when the 'puppet'
option is selected.

	# sudo ./aac-base.install
	Checking Timezone settings
	Checking for EPEL repository
	Checking for SELinux Policy RPMS
	If SELinux issues pop up use the following to debug:
		sealert -a /var/log/audit/audit.log
	1) aac-base.install.dnscrypt	5) Exit
	2) aac-base.install.powercli	
	3) aac-base.install.puppetbase
	#? 

We verify timezones, repositories, and SELinux bits are installed then
prompt for the actions to take. Puppetbase is the first one for my nodes
and the rest are for one off services not install by puppet currently.

You can also call the script with the tail end of the available install
scripts as well. Such as:

	# sudo ./aac-base.install -i powercli

The usage of the script is:

	sudo ./aac-base.install [--install|-i installer] [--help|-h] [timezone]

### Todo
Build out Puppet 4.0 framework for my virtualized environment.

### Support
Email elh at astroarch dot com for assistance or if you want to add
more items.

### Changelog
