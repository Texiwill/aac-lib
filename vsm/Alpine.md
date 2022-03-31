# aac-lib
AAC Library of Tools

- <a href=https://github.com/Texiwill/aac-lib/tree/master/>List of Tools</a>

## vsm
Linux Version of VMware Software Manager (MacOS Install)
- <a href=https://github.com/Texiwill/aac-lib/tree/master/>List of Tools</a>

### Description
An Alpine Linux and slightly more intelligent version of VSM. See README.md for more information:
- <a href=https://github.com/Texiwill/aac-lib/tree/master/vsm>LinuxVSM README</a>

### Installation
Before you install LinuxVSM on Alpine Linux you need to do the following:

```
apk add bash sudo ncurses
adduser -s /bin/bash <username> wheel
echo '%wheel ALL=(ALL) ALL' > /etc/sudoers.d/wheel
```

Now you can run the LinuxVSM installer.
