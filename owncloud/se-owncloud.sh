semanage fcontext -a -t httpd_sys_rw_content_t '/opt/owncloud/oc_data'
restorecon '/opt/owncloud/oc_data'
semanage fcontext -a -t httpd_sys_rw_content_t '/var/www/html/owncloud/data'
restorecon '/var/www/html/owncloud/data'
semanage fcontext -a -t httpd_sys_rw_content_t '/var/www/html/owncloud/config'
semanage fcontext -a -t httpd_sys_rw_content_t '/var/www/html/owncloud/config/config.php'
restorecon '/var/www/html/owncloud/config'
restorecon '/var/www/html/owncloud/config/config.php'
semanage fcontext -a -t httpd_sys_rw_content_t '/var/www/html/owncloud/apps'
restorecon '/var/www/html/owncloud/apps'

setsebool -P httpd_can_network_connect_db on
setsebool -P httpd_can_connect_ldap on
setsebool -P httpd_can_network_connect on
setsebool -P httpd_can_sendmail on

