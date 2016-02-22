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
