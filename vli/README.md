# aac-lib
AAC Library of Tools

- <a href=https://github.com/Texiwill/aac-lib/tree/master/>List of Tools</a>

## vli
Security Operations Content Pack for VMware vRealize Log Insight

### Description

The Security Operations content pack was initially developed to visualize
your Login and Internal Segmentation Edge firewall data in a usable
fashion. Every tool talking to or connecting VMware vCenter or VMware
vSphere should have its own service account. Without a way to visualize
this, it is an auditing nightmare. In addition, any login to vCenter
using administrator, administrator@, system, or domain administrator
should be anathema. Therefore we have a count of times that happens
and an appropriate alert. Lastly, logging in as root to vSphere should
also be anathema. Therefore we have a count of times root login actions
happen and have an appropriate alert. The last two elements are per the
hardening guide from VMware.

The content pack has evolved into a multi-purpose Security Operations
Center with the following dashboards:

- Activity Dashboard is used to visualize user activity within vSphere and alert upon root or administrator access. This dashboard should always show data in an active vSphere environment.
- Login/Logout API Invocations Dashboard is used to visualize API invocations by user, user-agent, and quantity. We attempt to line up logins and logouts with the API invocations to gain visibility into what is happening on vSphere. We also look at CLI calls direct to hosts.
- Firewall Events Dashboard is used to visualize firewall events by host, source of data, and packet actions. This dashboard will only show data if Internal Segmentation Edge firewalls are in use.
- ESXi Config Changes is used to visualize changes in your underlying ESXi nodes. At the moment we are picking up Network and other changes including placement of VMs. This dashboard also include Shell comand tracking and alerting.
- VM Configuration Changes Dashboard is used to visualize changes to your virtual machines as they happen. If this dashboard shows no data, that is a good thing.
- VMRC/MKS Events Dashboard is used to visualize and alert upon actions that use the VMware Remote Console to a VM whether started within vCenter clients or direct host interaction. If this dashboard shows no data, that is a good thing.
- Datastore Browser Events Dashboard is used to visualize and alert upon activity surrounding the datastore browser within vCenter and upon each host. If this dashboard shows no data, that is a good thing.
- Permissions Dashboard is used to visualize and alert upon changes and additions to the vCenter permissions associated role based access control. If this dashboard shows no data, that is a good thing.
- SecureESX Dashboard is used by the SecureESX Security Content Automation Protocal (SCAP) scanner for vSphere. This scanner is available from AstroArch Consulting, Inc. and features use of the DISA STIG identifiers.

Compatibility:
- VMware vSphere 6.0 or later for Login Events & Actions and Firewall Events Dashboards
- Vmware vSphere 6.5 or later for all other Dashboards (they may work with vSphere 6.0 but not tested)
- VMware vCloud Networking and Security (all versions)
- VMware NSX v6.2 or later
- VMware vRealize Log Insight 3.6 or later

Dependencies:
- We use extracted fields from the VMware vSphere content pack
- We use extracted fields from the VMware NSX Content pack

Additional Information:
- All extracted fields for the Security Operations content pack start with soc
- All alarms for the Security Operations content pack start with SOC

If some of the dashboards here seem similar to others, they may be. The
goal is to create one content pack to act as the SOC without having to
jump to too many places.

And the Beta versions:
- beta Works with vShield Manager (Texiwill Securitybeta.vlcp)
- nsx-beta Works with NSX Manager (Texiwill Security nsx-beta.vlcp)

### Installation
Import into LogInsight

### Support
Email elh at astroarch dot com for assistance or if you want to add
for more items.

### Changelog
- 1.0 RC7 - changed vSphere to ESXi in dashboards where appropriate. Also added Shell commands alerting and tracking to the ESXi Config Changes dashboards. Fixed the Data Store Browser dashboards to be more accurate (Thank you fellow vExpert Justin Bias).

- 1.0 RC6 - added the vSphere Config Changes Dashboard. Updated the Firewall dashboard to include a chart of Dropped by port.

- 1.0 RC5 - renamed Login and Activity Dashboard to just Activity with adjust ment to graph titles. Renamed API Invocations dashboard to Login/Logout and API Invocations to line up login and logous with low level vSphere API Invocations. Added visibility into Direct connect activities.

- 1.0 RC4 - rename others to beta. v1.0 contains alerts, new dashboards, etc. All the bits to be acceptable to VMware.
