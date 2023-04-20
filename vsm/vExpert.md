# aac-lib
AAC Library of Tools

- <a href=https://github.com/Texiwill/aac-lib/tree/master/>List of Tools</a>

## vsm vExpert
Linux Version of VMware Software Manager (vExpert Usage)

### Notes

VMware vExperts now have a tool they can use to download their entitled
packages in full. To do so, you need two logins: My VMware & vExpert Portal.

And a new option: --vexpertx, that gets stored in your $HOME/.vsmrc file
so no need to reuse it every time.

To call LinuxVSM as a vExpert please use the following:

```
vsm.sh -y --vexpertx --historical --patches --dts --oem  --symlink --compress

--vexpertx option adds the following capabilities:
--patches - download patches as well
--licenses - download your vExpert licenses
--nested - download Nested Hypervisor builds
```

Actually, you could probably leave off everything after --historical
but the others increase the downloads to the Drivers and Tools and OEM
ISO images while compressing and preserving space by using symlinks
where useful. I tend to use these options all the time. You need
--historical asthe vExpert portal does not have every version of
everything and --historical allows you to go back to earlier versions.

With these two logins and the appropriate flag certain options will be
made available to any vExpert.

How does LinuxVSM handle vExperts? By adding the correct flag, you will
then be prompted to put in your vExpert Portal username and password
and if saved (do not worry they are encrypted on disk) you can reuse
the tool as many times as you want. However a --clean will remove those
files as well as anything else temporary.

### Support
Email elh at astroarch dot com for assistance or if you want to add
for more items.

