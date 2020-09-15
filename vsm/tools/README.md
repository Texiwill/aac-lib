# aac-lib
Tools that make use of LinuxVSM

## allpkg.sh
Download all packages given a regex and a refinement item.

### Description
```
Usage: ./allpkg.sh package refinement
	package is the general name of a package
	refinement is a refinement upon that search
	Example: ./allpkg.sh VCSA iso
	- which would download all iso images for every iso version of VCSA
```
## vsm_favorites.sh

Download all packages specified by Suite name.

### Description
Download all packages and patches specified by Suite names using new
space saving features. Note as of v2.0.0 of vsm_favorites.sh there are
many new arguments to get current plus previous versions.

```
vsm_favorites.sh [--latest][--n+1][--n+2][--n+3][--n+4][--n+5][--n+6][--all][-h|--help][-s|--save][--euc][-v|--version]
	--latest - get the latest only (default)
	--n+1 - get the latest + 1 previous version
	--n+2 - get the latest + 2 previous versions
	--n+3 - get the latest + 3 previous versions
	--n+4 - get the latest + 4 previous versions
	--n+5 - get the latest + 5 previous versions
	--n+6 - get the latest + 6 previous versions
	--all - get everything
	--euc - Add Additional EUC components
	-mr   - Clear 1st time use
	-h|--help - this help
	-s|--save - save get and --euc options to $HOME/.vsmfavsrc
	-v|--version - version information

Uses contents of $HOME/.vsmfavsrc to set Get and EUC options.
```

## vami.sh
Create a VAMI repo suitable for sharing via NGINX

### Description 
Checks for NGINX and provides how to link in the VAMI repo. Can also be
used with Apache.
```
Usage: ./vami.sh [-t|--target tgtName] [-f|--force][-d|--debug][-h|--help]
	Uses LinuxVSM repo as target unless tgtName specified.
```

### Support
Email elh at astroarch dot com for assistance or if you want to add
for more items.
