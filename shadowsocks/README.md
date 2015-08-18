#Shadowsocks#
A fast tunnel proxy that helps you bypass firewalls.

#INSTALL#
##CentOS Server##

```
yum install python-setuptools && easy_install pip
pip install shadowsocks
```

#Start#

```
ssserver -p 443 -k password -m aes-256-cfb -d start
```

#Stop#

```
sserver -d stop
```

#Linux client#

```
sslocal -s srvip -p 443 -b 0.0.0.0 -l 1080 -k password -t 600 -m aes-256-cfb
```
