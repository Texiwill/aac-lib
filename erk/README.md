# aac-lib
AAC Library of Tools

Other Tools Include:

- <a href=https://github.com/Texiwill/aac-lib/tree/master/isolib>ISO Library Tool isolib.sh</a>
- <a href=https://github.com/Texiwill/aac-lib/tree/master/hooks>Git Pre-Commit Hook</a>
- <a href=https://github.com/Texiwill/aac-lib/tree/master/vli>LogInsight Content Packs</a>
- <a href=https://github.com/Texiwill/aac-lib/tree/master/tocentos>Convert RHEL to CentOS</a>

## ERK (Elasticsearch-Rsyslog-Kibana) Stack Installer

### Description
A bash script to automatically install an Elasticsearch-Rsyslog-Kibana
stack on CentOS/RHEL 7. Rsyslog replaces Logstash and allows direct
forwarding of syslog messages to Elasticsearch for other processing. I
forward my VMware vRealize LogInsight logs to ERK for use with ElasticSearch.

Why did I create this script? Nothing I found on the web was as automated,
pulled the latest sources, and worked seamlessly with rsyslog, SELinux,
and either iptables & FirewallD.

> Reference: 
> 	http://www.havensys.net/making-a-free-log-server/

### Installation
Run the script using SUDO as root access is required.  The script installs
the latest Rsyslog, Elasticsearch, Kibana, but also adjusts SELinux and
either FirewallD or Iptables as well.

	# sudo ./erk.install

If the erk.install.filename files exist, they provide additioanl
mechanisms to secure Kibana/ES. erk.install will either present a list
of these mechanims or if only one exists, run it. Currently there is a
way to frontend ERK with an Nginx proxy to add simple authentication.

### Todo

- Add support for ES Shield
- Add Grafana support
- Determine why TCP 514 cannot receive syslog messages

### Support
Email elh at astroarch dot com for assistance or if you want to add
for more items.

### Changelog
- fixed SELinux for Rsyslog talking to ES

- fixed SELinux for the Nginx frontend to Kibana

- Added initial Nginx Support and Iptables as well as FirewallD
