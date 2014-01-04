#!/bin/bash
emerge -q findlib dev-ml/extlib
cd /usr/src
http://libvirt.org/sources/ocaml/ocaml-libvirt-0.6.1.2.tar.gz
tar xfz ocaml-libvirt-0.6.1.2.tar.gz
rm ocaml-libvirt-0.6.1.2.tar
cd ocaml-libvirt-0.6.1.2
./configure --prefix=/usr
make all
make install

wget https://people.redhat.com/~rjones/virt-top/files/virt-top-1.0.8.tar.gz
tar xfz virt-top-1.0.8.tar.gz
rm virt-top-1.0.8.tar
cd virt-top-1.0.8
./configure
