# aac-lib
AAC Library of Tools

- <a href=https://github.com/Texiwill/aac-lib/tree/master/>List of Tools</a>

## html5
This is an update script that can be run from cron on the HTML5 vCenter Client VM. 

### Description
This simple script looks for the latest HTML5 Client for vCenter, downloads it, installs and restarts the client. If the version is already there, it does not download and will not install, just report the occurrence.

### Installation
	Place in /usr/local/bin, then
	ln -s /usr/local/bin/update-html5-client.sh /etc/cron.daily

### Support
Email elh at astroarch dot com for assistance or if you want to add
for more items.
