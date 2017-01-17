# aac-lib
AAC Library of Tools

Tools Include:

## ISO Library Tool

- <a href=https://github.com/Texiwill/aac-lib/tree/master/isolib>ISO Library Tool isolib.sh</a>

### Description
iso-lib.sh is a tool to help maintain a library of blu-ray, DVD, or CD
data disks. I write to Blu-Ray as a removable media backup which I can
store in a safe or offsite. A more permanent storage solution than
spinning rust or even SSDs.

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
A bash script to automatically install an Elasticsearch-Rsyslog-Kibana stack. Rsyslog replaces Logstash and allows direct forwarding of syslog messages to Elasticsearch for processing.

## TOCENTOS

- <a href=https://github.com/Texiwill/aac-lib/tree/master/tocentos>Convert from RHEL to CentOS</a>

### Description
A set of scripts to convert from a RHEL 6/7 install to a CentOS 6/7 install.

## VLI

- <a href=https://github.com/Texiwill/aac-lib/tree/master/vli>VMware LogInsight Content Pak</a>

### Description
A set of content paks for VMware Log Insight

## HTML5

- <a href=https://github.com/Texiwill/aac-lib/tree/master/html5>Auto update HTML5 vCenter/vSphere Client</a>

### Description
A simple script to get the latest vSphere/vCenter HTML5 Client and install if necessary.

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
