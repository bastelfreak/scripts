#!/bin/bash

##
# small snippet that increases the read and write cache of a md device
# written by Tim 'bastelfreak' Meusel
# http://h3x.no/2011/07/09/tuning-ubuntu-mdadm-raid56
##
echo 32768 > /sys/block/md4/md/stripe_cache_size
blockdev --setra 32768 /dev/md4

