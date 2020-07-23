# aac-lib
AAC Library of Tools

- <a href=https://github.com/Texiwill/aac-lib/tree/master/>List of Tools</a>

## vsm
Linux Version of VMware Software Manager

### Support
Email elh at astroarch dot com for assistance or if you want to add
for more items.

### Changelog
6.4.0 - Updated to support latest My VMware login and API, this release has many more dependencies and only currently works on Linux subsystems not WSL or MacOSX. --patches support has been temporarily dropped

6.3.6 - Fixed RHEL8 Python2 usage

6.3.5 - Fixed RHEL8 Dependency checks

6.3.4 - Fixed Ubuntu 20.04 Dependency checks

6.3.3 - Fixed partial cache of cookies

6.3.2 - Fixed a caching issue with Authentication

6.3.1 - Update to MacOS 10.15.4 fix

6.3.0 - Fix for MacOS 10.15.4 -- Thank you brumcmil

6.2.9 - Added --olde option that defaults to 12 hours to remove temporary files between runs (forces -mr option to be used after the hour setting expires).

6.2.8 - More holiday messages and several uid fixes

6.2.7 - Debug and Menu issue fix

6.2.6 - Date issue fixed

6.2.5 - Small impovement to holiday messages

6.2.4 - Holiday Messages

6.2.3 - Fix to download favorites like Fusion using --fav

6.2.2 - Small bugfix to ensure vExpert mode does not impact other modes 
	(cookie mixup)

6.2.1 - Several bug fixes in menus for improved vExpert mode and vExpert.md

6.2.0 - Check for new versions. Added vExpert support

6.1.6 - Fix for double digit minor version like Horizon 7.10 and version check 
	for upgrades.

6.1.5 - Slight change due to My VMware change

6.1.4 - Added a new way to parse certain data files

6.1.3 - Fix for direct downloads such as Horizon Clients

6.1.2 - Applied same fix to --dlgl

6.1.1 - Fixed --dlg download issue

6.1.0 - Fixed --dlg regex issue

6.0.9 - Fixed My VMware login, VMware changed how they login

6.0.8 - Fixed incorrect reference for download groups for historical

6.0.7 - Fixed incorrect downloads based on non-entitlement

6.0.6 - Remove some beta code and reset symdir variables after use

6.0.5 - Update to Menu subsystem for lack of historical options

6.0.4 - Update to get the JSON, code was out of order

6.0.3 - Update to get the JSON seed file for --dlg, --dlgl

6.0.2 - Menu without --historical was messed up, as well --historical 
        after download -- @virtualex

6.0.1 - Slight change to help/Readme, removal of old option

6.0.0 - 100% My VMware, note if you do not have entitlements you cannot 
        download the packages. That is a My VMware change. Also, there is no
	longer a datafile, there is a seed file and a way to rebuild or add
	to that seed file now available.

5.3.7 - Fix to pick up proper download urls for some tools

5.3.6 - Better implementation of Oauth, parsing, and removal of static urls

5.3.5 - More updates due to Major website change. Many parsing issues fixed

5.3.4 - Found the proper URL for pre-Major website change style capabilities

5.3.3 - Major website change bug fix, could not parse multiple word names properly

5.3.2 - Major Website change also to download vSphere need --oauth option

5.3.1 - Added some packages

5.3.0 - Unimproved the Options

5.2.9 - Improved Options

5.2.8 - DriversTools and Package naming change

5.2.7 - Linux Mint support

5.2.6 - Small bugfixes related to menu items for new packages

5.2.5 - Fixes for incorrect menu items for new packages

5.2.4 - Encryption of temporary credential store

5.2.3 - Merged dependency checking changes from tsborland.

5.2.2 - Removed Package special case

5.2.1 - BugFix: Missing Packages/DriversTools Updates

5.2.0 - BugFix: Missing Packages

5.1.9 - BugFix: Missing Packages

5.1.8 - BugFix: Missing Packages

5.1.7 - BugFix: DriversTools not showing for Historical mode

5.1.6 - BugFix: In advertently showed Chrome Web Store links which are 
	not possible to download on Linux.

5.1.5 - BugFix: With Historical Mode DriversTools option did not always show up

5.1.4 - BugFix: Associated Files take 2

5.1.3 - BugFix: Associated Files

5.1.2 - Fixed test condition for associated files: CustomIso/DriversTools

5.1.1 - Minor change to with downloading unknown bits

5.1.0 - Fixed a issue with downloading unknown bits

5.0.9 - Finished fixing URL bug.

5.0.8 - Fixed bug where URL was incorrectly created

5.0.7 - Fixed CustomIso detection to only include ISOS

5.0.6 - added --clean option to clean all temporary files

5.0.5 - Slight fixes for vSphere Platinum support

5.0.4 - --dlg fixes due to --oauth additions. More DriversTools available
        when using --oauth.

5.0.3 - Fixed an issue using oauth fallback for certain content.

5.0.2 - Fixed a historical download issue

5.0.1 - Updated --oauth option to work with additional packages

5.0.0 - Updated parsing of package locations and new options for login

4.9.0 - Fixed Error

4.8.9 - Backed-out UA change

4.8.8 - Fix to Networking Error take #2

4.8.7 - Fix to Network Error

4.8.6 - Fix to --dlg and code reorg

4.8.5 - Missing Package group

4.8.4 - Fix to package name parsing for NSX

4.8.3 - Fix to --fav parsing

4.8.2 - Fixed 67 download parser

4.8.1 - Fixed NSX parsing issue

4.8.0 - DriversTool and small parsing update for shared big files

4.7.9 - More compression code for --fixsymlinks

4.7.8 - Package parsing update

4.7.7 - Slight changes to handle older files

4.7.6 - More parsing updates, lots of DriversTools updates

4.7.5 - Changes to add more existing packages. Fix to reporting, 
	and gzip protections

4.7.4 - One more fix to --fixsymlink, do not link if Link already exist

4.7.3 - Fix to --fixsymlink, it over corrected

4.7.2 - Fixed --historical DriversTools, added --symlink, -z|--compress, 
	and --fixsymlink options

4.7.1 - Fixed --historical bugs, lists were not cleared and improper parsing

4.7.0 - Added --historical option to see and possibly download older
	versions of packages (Thanks to Alex Lopez @ivirtualex) and 
	fixed a bug with credentials (Thanks to Michelle Laverick 
	@m_laverick)

4.6.9 - Change to parsing for potentially missing data

4.6.8 - Update for older versions, README update for Examples

4.6.7 - DriversTools + Language fix for non-english language users

4.6.6 - More product name changes, DriversTools updates

4.6.5 - Small change as Product Names have changes

4.6.4 - added "--dlgl pattern" to test --dlg search patterns

4.6.3 - Small Debug fix

4.6.2 - Fixed a small bug in display

4.6.1 - Fixed --fav bug with parsing

4.6.0 - Download logic bug fixed for differently formated HTML

4.5.9 - Menu logic bug fixed

4.5.8 - Infrastructure Operations Management added back to top

4.5.7 - Small changes for new options

4.5.6 - Update for new Windows VSM Data Files and new options

4.5.5 - Update to install.sh to create the update.sh automatically

4.5.5 - added --fav option to allow for using favorites from commandline
        (no more need to Mark a Favorite)

4.5.4 - Fixed some logic for download paths

4.5.3 - Fixed several bugs: Malformed Data causing download error
        (@ivirtualex),--dlg with older packages, error messages in wrong spot, 
	inappropriate data file errors, code cleanup, and added to logic for 
	download paths.

4.5.2 - Fixed logic for download paths, logic for showing checksum
        failures

4.5.1 - Fixed --dlg error and added some missing data. Datafile 1.0.1 now
        Special thanks to Alex Lopez (@ivirtualex) and 
	Michelle Laverick (@m_laverick)

4.5.0 - Rewrite to better allow updates, --dlg to work, sha256/sha1 sums, and improved MacOS support, not to mention improvements in performance

4.0.4 - MacOS Support

4.0.3 - Small Bug with --dlg fixed, plus initial download speedup

4.0.2 - Support for VC55U3H, 60U3 fixes, and --dlg updates thanks to Michelle Laverick (@m_laverick)

4.0.1 - Support for VC65U1G plus bugfix from Alex Lopez (@ivirtualex)

4.0.0 - My VMware now default, cleaned up Debug more

3.9.0 - Added Debian Support

3.8.1 - Hopefully the last progress issue

3.8.0 - One more progress issue.

3.7.9 - Bug fix in progress. My thanks to Alex Lopez (@ivirtualex) for finding.

3.7.8 - Bug fix when missing .vsmrc, fixes to progress. My thanks to Alex
Lopez (@ivirtualex) for finding the bug.

3.7.7 - slight change to versioning of a package

3.7.6 - Changes to how .vsmrc is processed to support Docker. .vsmrc can 
now be in $HOME, Repo Dir, or VSM XML Dir (/tmp/vsm). If the .vsmrc is
in any directory besides the default or $HOME you will need to specify
the --repo or -v|--vsmdir options and order is important.

3.7.5 - Fix to progress bars once more, should be final form. Added another
suite and fixed more broken due to new version downloads.

3.7.4 - Fixed missing progress when -nq specified

3.7.3 - Improved progress to include download progress

3.7.2 - Minor bug fix to allow proper download of VRNI

3.7.1 - Minor bug fix when encountering My VMware package that contains
VSM packages, added quiet and progress flags, and a slight code reorganization.

3.7.0 - CustomIso (OEM), and DriverTools can now be downloaded for all
My VMware packages where they exist.

3.6.0 - -mr now implies -m, added Mark capability to -m, fixed wget not
	using cookies all the time

3.5.5 - Fixed download of VVD issue 

3.5.4 - Fixed download directory issue

3.5.3 - More option issues corrected.

3.5.2 - Fixed some downloads (VRLI for vCenter and others) thanks to fellow 
	vExperts Michael Rudluff and Rotem Agmon

3.5.1 - Missing option corrected

3.5.0 - Using My VMware to pick up the up to date names instead of hardcoding 
	them. Added VMware Validated Design (VVD). Fixed VRNI and AppVolumes. 
	Also added the need for jq rpm, a JSON interpreter, for the 
	up-to-date names.

3.2.4 - Protection for temporary directory were reversed

3.2.3 - Protections from temporary directory owned by wrong user causing
	connection errors

3.2.2 - Protections from running as root and added install.sh to repo

3.2.1 - Minor fix... Fusion wrong file uploaded!

3.2.0 - Added Support for VMware Fusion download and improved errors when
	there are network issues.

3.1.0 - Added support for VMware Horizon, VMware Horizon Clients, and VMware 
	Workstation Pro. For now the Fusion download is within VMware Horizon.

3.0.1 - fixed a grep error showing up when it should not

3.0.0 - -m|--myvmware option now works including the need to install the 'bc'
	package. You can now download packages from My VMware not just view 
	missing packages!  Some things may still need tweaking, however. Also,
	added the -mr option to reset My VMware information only.  Email 
	issues and output using the --debug flag to elh at astroarch dot com.

2.5.2 - Fix to --dlg for single file downloads. Local was missing

2.5.1 - Protection for wildcard option

2.5.0 - Code reorganization and addition of wildcard option

2.0.2 - Fixed bug with single file selection

2.0.1 - Fixed bug where you were able to mark missing suites

2.0.0 - Added ability to get missing suite information from VMware's website
        Fixed the ability to select menu options using wrong input

1.7.0 - Fixed an intialization problem. Required --reset|-r to initialize

1.6.9 - Fixed issue where download was not happening for All when
individual files are listed.

1.6.8 - Fixed issue where individual file download resulted in bad
menu display

1.6.7 - Prompts for creds specific My VMware now

1.6.6 - fixed single file download and readme

1.6.5 - added --nooem|--oem, --nodts|--dts, --nooss|--oss to the .vsmrc
configuration file when options are saved

1.6.1 - moved variable and removed check for perl-XML-XPath as it is no
longer required.

1.6.0 - cleaned up code pulling unique items into one loop not 3
separate loops. Fixed Mark to only appear in one spot.

1.5.0 - added ability to download specific file by name or part of a
name and fixed major bug on associated products list where resultant
list was malformed

1.1.0 - fixed 'Back' to actually send you back just 1 level at all times
by creating a path variable that gets updated for every menu call and
Back used

1.0.1 - fixed 'Back' menu item when actual packages are shown

1.0.0 - added Minimum_Required menu item, do only download the base files
and not OpenSource, DriversTools, or CustomIso. Also added the
--dts|--nodts, --oem|--nooem, --oss|--nooss to set what to download when
any of the 'All' styles are selected.

0.9.5 - fixed latest parsing. It was too broad and did not confine to
the latest of a specific major version. I.e. 60 vs 65

0.9.4 - fixed issue where too much was include in the 'smarts'. Main
Product Downloads were being placed into CustomIso and DriverTools.

0.9.3 - Initial public launch

