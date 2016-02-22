# aac-lib
AAC Library of Tools

Tools Include:

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

## Git Pre-Commit

### Description
Git Pre-Commit script to check for API Keys, PII, and various other
leakages and deny the commit if source files contain anything untoward.
This tool is the result of my [Foray into Jenkins, Docker, Git, and
Photon](http://www.astroarch.com/?s=foray) with testing using Ixia. In
addition, to checking the files for API Keys, etc. if anything is found,
the script will log the leakge to syslog to be picked up by a SIEM or
some other monitoring tool.

A hook script to verify what is about to be committed:

- Looks for IPV4 Addresses
- Looks for Domain Names (user@domain)
- Looks for Passwords (hashes)
- Looks for API Keys (hashes)
- Looks for PII 
  - SSN 
  - CC# (Visa, Mastercard, American Express, AMEX, Diners Club, Discover, JCB)
  - US Passport
  - US Passport Cards
  - US Phone 
  - Indiana DL#

Called by "git commit" with no arguments.  The hook should
exit with non-zero status after issuing an appropriate message if
it wants to stop the commit.

> Reference: 
> 	http://www.unix-ninja.com/p/A_cheat-sheet_for_password_crackers

### Installation
Place hooks/pre-commit within /usr/share/git-core/templates to be used
when all Git repositories are cloned or initialized.

If you already have a repository, place within repository/.git/hooks

### Support
Email elh at astroarch dot com for assistance or if you want to check
for more items.
