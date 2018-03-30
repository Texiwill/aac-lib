# aac-lib
AAC Library of Tools

- <a href=https://github.com/Texiwill/aac-lib/tree/master/>List of Tools</a>

## vsm
Linux Version of VMware Software Manager (MacOS Install)
- <a href=https://github.com/Texiwill/aac-lib/tree/master/>List of Tools</a>

### Description
A MacOS and slightly more intelligent version of VSM. See README.md for more information:
- <a href=https://github.com/Texiwill/aac-lib/tree/master/vsm>LinuxVSM README</a>

### Installation
To install vsm.sh on MacOS you need to first install the prerequisites. 
Those are Xcode, XML::Twig, Homebrew, jq, and wget. Here is how you do those:

	First install Xcode from Apple
	Next install Homebrew using:
		$ ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
	Next install jq and wget
		brew install gnu-sed
		brew install wget
		brew install jq
	Next install XML::Twig
		sudo perl -MCPAN -e shell
		cpan> install XML::Twig
		... lots of questions and such. Answer YES or Y or y to
		any yes/no question presented ...
		cpan> exit
	Next install vsm.sh
		wget https://raw.githubusercontent.com/Texiwill/aac-lib/master/vsm/vsm.sh
		chmod +x vsm.sh

### Update
To keep vsm and your repository updated to the latest release/downloads
you can add the following lines to your local cron. This tells the
system to update the installer, then update vsm, then run vsm with your
currently marked favorite. Note 'user' is your username. 

Be sure to Mark a release as your favorite! If you do not, this does
not work. The 'Mark' menu item does this.

I added these lines to a script within /etc/cron.daily (which usually runs at 3AM):
```
wget https://raw.githubusercontent.com/Texiwill/aac-lib/master/vsm/vsm.sh
chmod +x vsm.sh
```

The following line starts VSM download at 6AM. You would add using the command `crontab -e`:
```
0 6 * * * /Users/user/vsm.sh -y -mr --favorite
```

### Support
Email elh at astroarch dot com for assistance or if you want to add
for more items.

