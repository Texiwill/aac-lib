#!/bin/bash

ocpath='/var/www/html/owncloud'
ocdpath='/opt/owncloud/oc_data'
htuser='apache'
htgroup='apache'
rootuser='root'

sudo -u ${htuser} php /var/www/html/owncloud/occ maintenance:mode --off
sudo -u ${htuser} php /var/www/html/owncloud/occ upgrade 

printf "Creating possible missing Directories\n"
#mkdir -p $ocpath/data
mkdir -p $ocpath/assets

printf "chmod Files and Directories\n"
find ${ocpath}/ -type f -print0 | xargs -0 chmod 0640
find ${ocpath}/ -type d -print0 | xargs -0 chmod 0750
find ${ocdpath}/ -type f -print0 | xargs -0 chmod 0640
find ${ocdpath}/ -type d -print0 | xargs -0 chmod 0750

printf "chown Directories\n"
chown -R ${rootuser}:${htgroup} ${ocpath}/
chown -R ${htuser}:${htgroup} ${ocpath}/apps/
chown -R ${htuser}:${htgroup} ${ocpath}/config/
chown -R ${htuser}:${htgroup} ${ocdpath}
chown -R ${htuser}:${htgroup} ${ocpath}/themes/
chown -R ${htuser}:${htgroup} ${ocpath}/assets/

chmod +x ${ocpath}/occ

printf "chmod/chown .htaccess\n"
if [ -f ${ocpath}/.htaccess ]
 then
  chmod 0644 ${ocpath}/.htaccess
  chown ${rootuser}:${htgroup} ${ocpath}/.htaccess
fi
if [ -f ${ocdpath}/.htaccess ]
 then
  chmod 0644 ${ocdpath}/.htaccess
  chown ${rootuser}:${htgroup} ${ocdpath}/.htaccess
fi

