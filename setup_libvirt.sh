#!/bin/bash

##
# written by Tim 'bastelfreak' Meusel (https://bastelfreak.de)
# compiles libvirt under debian/ubuntu
# some more infos are available at my blog https://blog.bastelfreak.de/?p=659
##
aptitude update
aptitude install -y libvirt-bin libyajl-dev libxml2-dev libdevmapper-dev python-dev make
mv /etc/libvirt/libvirtd.conf /etc/libvirt/libvirtd.conf.bak
cd /usr/src
wget ftp://libvirt.org/libvirt/libvirt-1.1.3.tar.gz
tar xzf libvirt-1.1.3.tar.gz
rm libvirt-1.1.3.tar
cd libvirt-1.1.3
./configure --prefix=/usr --with-storage-disk=no --without-selinux --with-qemu-group=libvirtd --with-qemu-user=libvirt-qemu --without-macvtap
make -j8 && make install
mv /etc/libvirt/libvirtd.conf.bak /etc/libvirt/libvirtd.conf
service libvirt-bin restart

