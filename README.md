# aac-lib
AAC Library of Tools

Tools Include:

## Git Pre-Commit

### Description
 Git Pre-Commit script to check for API Keys, PII, and various other
 leakages

 A hook script to verify what is about to be committed.
	-- Looks for IPV4 Addresses
	-- Looks for Domain Names (user@domain)
	-- Looks for Passwords (hashes)
	-- Looks for API Keys (hashes)
	-- Looks for PII such as SSN, CC#, some DL#, etc.

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
