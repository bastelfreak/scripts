#!/bin/bash
aptitude update
aptitude safe-upgrade
aptitude dist-upgrade
sed -i 's/squeeze/wheezy/g' /etc/apt/sources.list
aptitude update
aptitude upgrade
aptitude dist-upgrade
echo "Now you should reboot"
