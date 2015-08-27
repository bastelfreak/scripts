#!/usr/bin/env bash

##
# written bei canta, GPLv2
##

set -euo pipefail

mountpoint=$1

! [ "${mountpoint:0:1}" = "/" ] && echo Give absolute path && exit 1

size_in_G=$((`df --block-size=1G $mountpoint | grep $mountpoint\$ | tr -s \  | cut -d\  -f2` - 1))

echo Starting 1 GiB sequential Trim for: $mountpoint
echo Every Dot represents one trimmed GiB

seq 0 $(( $size_in_G - 1 )) | xargs -I NUM bash -c "ionice -c3 nice -n20 fstrim -o NUMG -l 1G $mountpoint; echo -n ."
ionice -c3 nice -n20 fstrim -o $size_in_G\G $mountpoint; echo .
