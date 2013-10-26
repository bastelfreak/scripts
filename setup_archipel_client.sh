#!/bin/bash
cd /home/lighttpd/vhosts/bastelfreak/bastelfreakonline.de/htdocs
rm archipel -r
wget http://nightlies.archipelproject.org/latest-archipel-client.tar.gz
gunzip latest-archipel-client.tar.gz
tar xf latest-archipel-client.tar
rm latest-archipel-client.tar
mv Archipel archipel
chown bastelfreak:bastelfreak archipel
