# aac-lib
AAC Library of Tools

- <a href=https://github.com/Texiwill/aac-lib/tree/master/>List of Tools</a>

## LinuxVMA

### Description
LinuxVMA is a collection of Ansible playbooks designed to install the
following on a Linux System. They are:

* LinuxVSM
* VMware Linux CLI/SDK
* PowerCLI
* PowerNSX
* PowerVRA
* ovftool
* ov-imports.sh (automate ovftool w/hiera database)
* dcli
* vctui

More functions/capabilities will be added over time. What you get out
of all this is the APIs for Perl, Ruby, PowerShell, Go, and Python as
well as the tools required to manage a vSphere environment from Linux. A
replacement for the retired VMware Management Assistant package.

#### Supported Operating Systems
Full support for LinuxVMA/LinuxVSM is available for:

* RHEL/CentOS 7
* RHEL/CentOS 8
* Debian 9
* Debian 10
* Ubuntu 18.04
* Ubuntu 20.04
* PhotonOS 3 - requires creating an account and installing sudo to use
* Microsoft WSL2

### Installation
Run the script and if root access is required you will be asked to
provide sudo credentials

	$ ./aac-base.install -v -i LinuxVMA

Use the following script, to keep everything up to date. If wget is not
installed it will ask for it.

<pre>
which wget >& /dev/null
if [ $? -eq 1 ]
then
    sudo yum -y install wget
fi

wget -O aac-base.install https://raw.githubusercontent.com/Texiwill/aac-lib/master/base/aac-base.install
chmod +x aac-base.install
./aac-base.install -u
./aac-base.install -v -i LinuxVMA
</pre>

### Support
Email elh at astroarch dot com for assistance or if you want to add
more items.

### Changelog
1.0.3 vCLI Support for PhotonOS, fixes for RHEL8

1.0.2 LinuxVSM support for PhotonOS
