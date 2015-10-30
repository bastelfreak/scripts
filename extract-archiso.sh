#!/bin/bash

##
# written by Bluewind
##

set -e

umask 022

iso="$(readlink -f "$1")"
http_base="http://mistral.server-speed.net/arch"

cd /srv/tftpboot/archiso/

rm -rf /srv/tftpboot/archiso/*

7z x "$iso"

rm -rf EFI isolinux loader "[BOOT]"

# allow booting without dhcp options
ln -sr arch/boot/syslinux/lpxelinux.0 arch/lpxelinux.0
mkdir arch/pxelinux.cfg

# menu
#ln -sr arch/boot/syslinux/archiso_px64.cfg arch/pxelinux.cfg/default

# default to 64bit
cat <<EOF >arch/pxelinux.cfg/default
DEFAULT install_arch64_http

TIMEOUT 50

UI menu.c32

LABEL install_arch64_http
MENU LABEL Install Arch Linux (x86_64) (HTTP)
LINUX $http_base/boot/x86_64/vmlinuz
INITRD $http_base/boot/intel_ucode.img,$http_base/boot/x86_64/archiso.img
APPEND archisobasedir=arch archiso_http_srv=http://\${pxeserver}/ nomodeset script=http://192.168.123.1/setup-arch-vm
IPAPPEND 3

LABEL install_arch32_http
MENU LABEL Install Arch Linux (i686) (HTTP)
LINUX $http_base/boot/i686/vmlinuz
INITRD $http_base/boot/intel_ucode.img,$http_base/boot/i686/archiso.img
APPEND archisobasedir=arch archiso_http_srv=http://\${pxeserver}/ nomodeset script=http://192.168.123.1/setup-arch-vm
IPAPPEND 3

LABEL arch64_http
MENU LABEL Boot Arch Linux (x86_64) (HTTP)
LINUX $http_base/boot/x86_64/vmlinuz
INITRD $http_base/boot/intel_ucode.img,$http_base/boot/x86_64/archiso.img
APPEND archisobasedir=arch archiso_http_srv=http://\${pxeserver}/ nomodeset
IPAPPEND 3

LABEL arch32_http
MENU LABEL Boot Arch Linux (i686) (HTTP)
LINUX $http_base/boot/i686/vmlinuz
INITRD $http_base/boot/intel_ucode.img,$http_base/boot/i686/archiso.img
APPEND archisobasedir=arch archiso_http_srv=http://\${pxeserver}/ nomodeset
IPAPPEND 3
EOF
ln -sr arch/pxelinux.cfg/default arch/pxelinux.cfg/C

# fix permissions
find . -type d -exec chmod 755 {} +
find . -type f -exec chmod 644 {} +


