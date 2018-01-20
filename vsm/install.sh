#!/bin/sh
# Copyright (c) AstroArch Consulting, Inc.  2017,2018
# All rights reserved
#
# An installer for the Linux version of VMware Software Manager (VSM)
# with some added intelligence the intelligence is around what to download
# and picking up things available but not strictly listed, as well as
# bypassing packages not created yet
#
# Requires:
# wget 
#
# vim: tabstop=4 shiftwidth=4

which wget >& /dev/null
if [ $? -eq 1 ]
then
        sudo yum -y install wget
fi

wget -O aac-base.install https://raw.githubusercontent.com/Texiwill/aac-lib/master/base/aac-base.install
chmod +x aac-base.install
./aac-base.install -u
sudo ./aac-base.install -i vsm

echo "VSM is now in /usr/local/bin/vsm.sh"
