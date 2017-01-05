# aac-lib
AAC Library of Tools

- <a href=https://github.com/Texiwill/aac-lib/tree/master/>List of Tools</a>

## BLKTRACE

### Description
A bash script to automatically run blktrace/blkparse based on references
directories. Directories are converted to filesystems which are used
instead of devices. The arguments accept devices as well as needed and
if you know what you are doing.

The goal is to provide input for <a href=http://www.theotherotherop.org>The Other Other Operation storage benchmark</a>.

### Installation
Run the script using 

	$ ./runblktrace [-h]|[-w seconds] directory [directory [...]]"

or to see help

	$ ./runblktrace -h
	-or-
	$ ./runblktrace

or to specify runtime in seconds, the default is 3600 or 1 hour. The
position of this argument is important, it must be before the directory
list

	$ ./runblktrace -w 4800 directory [directory [...]]


### Todo



### Support
Email elh at astroarch dot com for assistance or if you want to add
for more items.

### Changelog
