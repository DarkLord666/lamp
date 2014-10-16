About
====

Designed for Debian OS only! (at the moment)

```bash
+-------------------------------------+
| An interactive LAMP Installer will  |
| automatically setup and configure : |
| Apache (with Nginx - optional)      |
| MySQL                               |
| PHP (additional modules - optional) |
| Other system programs (vim,mc,etc.) |
+-------------------------------------+
```

Usage:
====

1. Download install.bin
2. chmod +x install.bin
3. ./install.bin

How to modify?
====

1. Download lamp-install.sh and files.tar.gz
2. Edit lamp-install.sh as you wish

For example, if you need to add some new system components to be installed with this script, change
```bash
apt-get -q -y install mc vim update-sun-jre subversion lftp rar zip unzip sudo atop iotop bash memcached sphinxsearch rsync redis-server
```
or any other part of lamp-install.sh

3. Perform 
```bash
$ cat lamp-install.sh files.tar.gz > install.bin
```

4. Run ./install.bin
