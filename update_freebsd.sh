#!/bin/sh
freebsd-update fetch; freebsd-update install; pkg update; pkg upgrade; pkg autoremove; pkg clean
