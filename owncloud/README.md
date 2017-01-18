# aac-lib
AAC Library of Tools

- <a href=https://github.com/Texiwill/aac-lib/tree/master/>List of Tools</a>

## OWNCLOUD

### Description
These are a set of scripts I use when updating owncloud via yum. You
run these scripts after the upgrade. owncloud.sh upgrades the database
and permissions. se-owncloud.sh fixes selinux if you are using it.

References: 
- https://doc.owncloud.org/server/9.0/admin_manual/installation/installation_wizard.html
- https://doc.owncloud.org/server/9.0/admin_manual/installation/selinux_configuration.html

### Installation
Run the script using SUDO as root access is required.  

	# sudo ./owncloud.sh
	# sudo ./se-owncloud.sh

I need to run both, but if you are not using selinux then the second
script is unnecessary.

### Support
Email elh at astroarch dot com for assistance or if you want to add
for more items.

### Changelog
- added config.php to se-owncloud.sh

- added recursive to restorecon for directories, etc.
