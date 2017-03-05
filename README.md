# aac-lib
AAC Library of Tools

This is a collection of tools I use within my own
environments to help me get over hurdles I write about at <a
href=https://www.astroarch.com/blog>AstroArch Consulting, Inc.</a>, where
you can find my vSphere Upgrade Saga as well as many other Upgrade Sagas
and writings about Wordpress, security, administration, and consulting.

For more analytical content please visit <a
href=https://www.virtualizationpractice.com/>TVP Strategy</a> where some
of these ideas first start. Eventually, I hope to extend this repository
to much larger projects.

Tools (in no particular order) Include:

## Git Pre-Commit

- <a href=https://github.com/Texiwill/aac-lib/tree/master/hooks>GIT Pre-Commit</a>

### Description
Git Pre-Commit script to check for API Keys, PII, and various other
leakages and deny the commit if source files contain anything untoward.
This tool is the result of my [Foray into Jenkins, Docker, Git, and
Photon](http://www.astroarch.com/?s=foray) with testing using Ixia. In
addition, to checking the files for API Keys, etc. if anything is found,
the script will log the leakge to syslog to be picked up by a SIEM or
some other monitoring tool.

## ERK (Elasticsearch-Rsyslog-Kibana) Stack Installer

- <a href=https://github.com/Texiwill/aac-lib/tree/master/erk>ERK Installer</a>

### Description
A bash script to automatically install an Elasticsearch-Rsyslog-Kibana
stack. Rsyslog replaces Logstash and allows direct forwarding of syslog
messages to Elasticsearch for processing. I use this to learn more about
ElasticSearch's capabilities as an extension to my VMware vRealize Log
Insight server.

## TOCENTOS

- <a href=https://github.com/Texiwill/aac-lib/tree/master/tocentos>Convert from RHEL to CentOS</a>

### Description
A set of scripts to convert from a RHEL 6/7 install to a CentOS 6/7
install. A customer wanted a quick way to move away from RHEL but stay
within the family of products.

## VLI

- <a href=https://github.com/Texiwill/aac-lib/tree/master/vli>Texiwill's Security</a> VMware vRealize Log Insight Content Pack

### Description
A set of security operations dashboards VMware vRealize Log Insight.

## OVFIMPORT

- <a href=https://github.com/Texiwill/aac-lib/tree/master/ovfimport>GOVC/OVFTOOL Import of a Directory of OVA/OVFs</a>

### Description
A set of scripts to import OVA/OVFs into vCenter/vSphere en masse using
a configuration file of simple key value pairs. There are two scripts,
the govc script is incomplete. I found too much missing, so wrote and
expanded the same script using ovftool.

## HTML5

- <a href=https://github.com/Texiwill/aac-lib/tree/master/html5>Auto update the vSphere HTML5 Fling</a> for the VMware vSphere Web Client Appliance

### Description
A simple script to get the latest HTML5 Fling for the VMware vSphere Web Client Appliance and install if necessary.

## BLKTRACE

- <a href=https://github.com/Texiwill/aac-lib/tree/master/blktrace>Run blktrace on Linux for The Other Other Operation benchmark input</a>

### Description
A bash script to automatically run blktrace/blkparse based on references
directories. Directories are converted to filesystems which are used
instead of devices. The arguments accept devices as well as needed and
if you know what you are doing.

## OWNCLOUD

- <a href=https://github.com/Texiwill/aac-lib/tree/master/owncloud>Upgrade Scripts for Owncloud with and without selinux</a>

### Description
A bash script to automatically upgrade and reset file and directory
permssions after an upgrade via YUM or RPM. Included is also
the script to update selinux settings for files and directories.

These scripts are useful to automate the database upgrade after owncloud
is updated. Nearly all these script lines are within the owncloud
documentationI added a few I need for Centos 7 with selinux enabled.

## ISO Library Tool

- <a href=https://github.com/Texiwill/aac-lib/tree/master/isolib>ISO Library Tool isolib.sh</a>

### Description
iso-lib.sh is a tool to help maintain a library of blu-ray, DVD, or CD
data disks. I write to Blu-Ray as a removable media backup which I can
store in a safe or offsite. A more permanent storage solution than
spinning rust or even SSDs.
