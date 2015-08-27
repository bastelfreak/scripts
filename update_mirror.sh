#!/bin/bash
##
# small script to mirror some stuff
# created by Tim 'bastelfreak' Meusel
##
rsync --archive --quiet --recursive --links --perms --times --hard-links --delete rsync://rpms.famillecollet.com/fedora/ /var/www/remi/fedora/
rsync --archive --quiet --recursive --links --perms --times --hard-links --delete rsync://rpms.famillecollet.com/enterprise/ /var/www/remi/enterprise
rsync --archive --quiet --recursive --links --perms --times --hard-links --delete rsync://mirror.de.leaseweb.net/videolan /var/www/videolan/
rsync --quiet --recursive --links --times --hard-links --delay-updates --safe-links rsync://mirror.23media.de/archlinux/ /var/www/archlinux/
wget --quiet http://rpms.famillecollet.com/index.html -O /var/www/remi/index.html

