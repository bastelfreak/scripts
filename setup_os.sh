#!/bin/bash

##
# created by Tim 'bastelfreak' Meusel
# wrapper script to install basic tools that are usefull on every server
# supports Gentoo, Debian, CentOS
##
# for every server
logwatch pflogsumm git htop nload sysstat iftop facter nmap screen fail2ban postfix tcpdump zeyple mtr pciutils ethtool vim bash-completion ferm iptraf duply uptimed acpid vnstat munin-node bsd-mailx zabbix-agent puppet

# for every physical server
smartmontools sensors intel-microcode

# hardening sshd:
ssh-keygen -t rsa -b 8192 -f /etc/ssh/ssh_host_rsa_key
echo "Ciphers aes256-ctr,aes192-ctr,aes128-ctr" >> /etc/ssh/sshd_config
ServerKeyBits 8192
AllowAgentForwarding no
X11Forwarding no
HostKey /etc/ssh/ssh_host_rsa_key
#HostKey /etc/ssh/ssh_host_dsa_key
#HostKey /etc/ssh/ssh_host_ecdsa_key
#X11Forwarding yes


# server bei blocklist.de eintragen

echo "root: monitoring@bastelfreak.org" >> /etc/aliases
service postfix reload
# fuer gentoo: /etc/mail/aliases

# puppet repo
# https://docs.puppetlabs.com/guides/puppetlabs_package_repositories.html
# zabix repo
# http://repo.zabbix.com/
