#!/bin/sh
freebsd-update fetch
freebsd-update install
pkg update
pkg upgrade
pkg autoremove
pkg clean
# same as:
#  portsnap fetch; portsnap update
portsnap fetch update
portmaster -ai
