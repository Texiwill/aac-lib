# aac-lib
AAC Library of Tools

Other Tools Include:

- <a href=https://github.com/Texiwill/aac-lib/tree/master/hooks>GIT Pre-Commit</a>
- <a href=https://github.com/Texiwill/aac-lib/tree/master/erk>ERK Stack Installer</a>
- <a href=https://github.com/Texiwill/aac-lib/tree/master/vli>LogInsight Content Packs</a>
- <a href=https://github.com/Texiwill/aac-lib/tree/master/tocentos>Convert RHEL to CentOS</a>

## ISO Library Tool

### Description
iso-lib.sh is a tool to help maintain a library of blu-ray, DVD, or CD
data disks. I write to Blu-Ray as a removable media backup which I can
store in a safe or offsite. A more permanent storage solution than
spinning rust or even SSDs. The tool has 4 major options:

- --prepare <directory> - prepares the target directory for burning. This will remove Synology and Mac specific additions to directories, as well as list those items that are not compressed in some fashion.
- --compile <directory> - compiles the target directory into a list of missing files from the existing blu-ray discs.
- --create <directory> - creates a DVD/Blu-ray data disc from the target directory based on the results of the --compile option.
- --rebuild - rebuilds the library from existing discs

Normal usage would be to rebuild, prepare, insert a blank disc, compile,
then create. Compile and Create are required for each new disc to
be created.

Other options include:

- --help - to get help
- --device <device> - device to use to burn disc

### Dependencies
To properly burn blu-ray discs on Linux you need to use the
official Joerg Schilling Cdrecord-ProDVD-ProBD-Clone v3 binary from
http://cdrtools.sourceforge.net/private/cdrecord.html

No other version burns blu-ray's properly. You end up with coasters
without Joerg Schilling's version.

### Installation
Place in /usr/local/bin, $HOME/bin, or anywhere within your path. The
tool does use sudo, so sudo access for mounting and unmounting loopback
devices is required.

### Support
Email elh at astroarch dot com for assistance or if you want to check
for more items.

### ChangeLog
1.0.2 - Ignored ASCII trademarks in uncompress/bad format list

1.0.1 - Added support for .enc (encrypted files) which are already compressed and support to output the version # as part of the --help argument.

1.0.0 - Initial Release
