#!/bin/sh

ver=`curl -sk https://labs.vmware.com/flings/vsphere-html5-web-client|grep Build |awk '{print $2}' | sort -t. -nrk1,1 -k2,2 | head -1`
v=$ver".0"

if [ ! -e installer-${ver}.0.bsx ]
then
	wget --no-check-certificate https://download3.vmware.com/software/vmw-tools/vsphere_html_client/installer-${v}.bsx
	service vsphere-client stop
	chmod +x installer-${v}.bsx
	./installer-${v}.bsx
	service vsphere-client start
else
	echo "Already at vSphere HTML5 Client $v"
fi
