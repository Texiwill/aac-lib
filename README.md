# aac-lib
AAC Library of Tools

Tools Include:

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
