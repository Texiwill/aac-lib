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
vsm.sh -y --vexpertx --historical --patch --dts --oem  --symlink --compress
```

Actually, you could probably leave off everything after --historical
but the others increase the downloads to the Drivers and Tools and OEM
ISO images while compressing and preserving space by using symlinks
where useful. I tend to use these options all the time. You need
--historical asthe vExpert portal does not have every version of
everything and --historical allows you to go back to earlier versions.

With these two logins and the appropriate flag certain files will be
made available to any vExpert. Note, this is not all files. These files
are also updated weekly instead of daily. It may also take longer to
update with full releases versus older releases. I would count on N and
N-1 versions being available. However, this is subject to change as well.

How does LinuxVSM handle vExperts? By adding the correct flag, you will
then be prompted to put in your vExpert Portal username and password
and if saved (do not worry they are encrypted on disk) you can reuse
the tool as many times as you want. However a --clean will remove those
files as well as anything else temporary.

The vExpert bits work by first checking for correct login for the vExpert
Portal and if it finds an unentitled file in My VMware LinuxVSM will
fill that in with an available vExpert Portal file it finds. So in
essence, it goes to My VMware first then to the vExpert Portal in a
seamless fashion. When you run LinuxVSM I strongly suggest using the
-mr option to ensure your temporary files are refreshed every run,
else your available files will be out of date.

The vExpert Portal itself uses LinuxVSM to create the directory structure
presented so it is as complete as My VMware. The vExpert Portal does
not store the Drivers Tools section as you can get that from My VMware,
but does store the rest.

### Support
Email elh at astroarch dot com for assistance or if you want to add
for more items.

