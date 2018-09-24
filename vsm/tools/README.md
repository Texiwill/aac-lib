# aac-lib
Tools that make use of LinuxVSM

## allpkg.sh
Download all packages given a regex and a refinement item.

### Description
Usage: ./allpkg.sh package refinement
	package is the general name of a package
	refinement is a refinement upon that search
	Example: ./allpkg.sh VCSA iso
	- which would download all iso images for every iso version of VCSA

## vsm_favorites.sh
Download all packages specified by Suite name.

### Description
Download all packages and patches specified by Suite names using new space saving features.

Usage: ./vsm_favorites.sh >& results & tail -f results

### Support
Email elh at astroarch dot com for assistance or if you want to add
for more items.
