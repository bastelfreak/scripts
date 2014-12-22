#!/bin/bash
##
# this is written by bluewind
# do a dd read with 1mb/s for all block devices. usefull for blinkenlights without performance impact
##
parallel -j 0 dd bs=1M iflag=direct if={} count=3000 \| pv -L1M >/dev/null ::: /dev/sd?
