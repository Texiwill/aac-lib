#!/bin/sh
#
# Copyright (c) 2017-2018 AstroArch Consulting, Inc. All rights reserved
#
#
#
# Set SELINUX settings for Owncloud
#
# Target: CentOS/RHEL 7
#
###
# Reference: https://doc.owncloud.org/server/9.0/admin_manual/installation/selinux_configuration.html
###
semanage fcontext -a -t httpd_sys_rw_content_t '/opt/owncloud/oc_data'
restorecon -R '/opt/owncloud/oc_data'
semanage fcontext -a -t httpd_sys_rw_content_t '/var/www/html/owncloud/data'
restorecon -R '/var/www/html/owncloud/data'
semanage fcontext -a -t httpd_sys_rw_content_t '/var/www/html/owncloud/config'
restorecon -R '/var/www/html/owncloud/config'
semanage fcontext -a -t httpd_sys_rw_content_t '/var/www/html/owncloud/apps'
restorecon -R '/var/www/html/owncloud/apps'

setsebool -P httpd_can_network_connect_db on
setsebool -P httpd_can_connect_ldap on
setsebool -P httpd_can_network_connect on
setsebool -P httpd_can_sendmail on

