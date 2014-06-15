#!/bin/bash
#----------------------------------------------------
# File: hfsc_shaper.sh
# Version: 0.1
# Edited: Florian "Bluewind" Pritz <f-p@gmx.at>
# Author: Maciej Blizi.ski, http://automatthias.wordpress.com/
#----------------------------------------------------
#
# Special Thanks to 
# Maciej Blizi.ski, http://automatthias.wordpress.com/
#
# References:
# http://www.voip-info.org/wiki/view/QoS+Linux+with+HFSC
# http://www.nslu2-linux.org/wiki/HowTo/EnableTrafficShaping
# http://www.cs.cmu.edu/~hzhang/HFSC/main.html

########################################################################
# CONFIGURATION
########################################################################

# Uplink and downlink speeds
# Normally use a bit lower values than your real speed, but
# you should experiment a bit
# downlink is unused
#DOWNLINK=20480
UPLINK=3900

# Device that connects you to the Internet
DEV="enp1s0"

# IP addresses of the VoIP phones,
# if none, set VOIPIPS=""
VOIPIPS="192.168.4.76"

# Interactive class: SSH Terminal, DNS and gaming (Quake)
INTERACTIVEPORTS="22 23 53 3389 5900 22222 6667 7000 44400 7776 4949 11030 11239 143 445 25765"

# VoIP telephony
#VOIPPORTS="5060:5100 10000:11000 5000:5059 8000:8016 5004 1720 1731"
VOIPPORTS="7977 9987"

# WWW, jabber and IRC
BROWSINGPORTS="80 443 8080 993"

# Everything unspecified will be here (inbetween Browsing and Data)

# FTP, Mail...
DATAPORTS="110 25 21 137:139 4662 4664 "

# The lowest priority traffic: eDonkey, Bittorrent, etc.
#P2PPORTS="6881:6999 36892 8333"
P2PPORTS=""

########################################################################
# CONFIGURATION ENDS HERE
########################################################################

function check_device() {
        if [ -z "$DEV" ] ; then
                echo "$0: stop requires a device, aborting."
                exit -1
        fi
}

function stop() {
  check_device
  # Reset everything to a known state (cleared)
  tc qdisc del dev $DEV root    &> /dev/null
  tc qdisc del dev $DEV ingress &> /dev/null

  # Flush and delete tables
  iptables -t mangle --delete POSTROUTING -o $DEV -j THESHAPER &> /dev/null
  iptables -t mangle --flush        THESHAPER &> /dev/null
  iptables -t mangle --delete-chain THESHAPER &> /dev/null
  #echo "Shaping removed on $DEV."
}

function start() {
  check_device
        #if [ -z "$DOWNLINK" ] ; then
                #echo "$0: start requires a downlink speed, aborting."
                #exit -1
        #fi
        if [ -z "$UPLINK" ] ; then
                echo "$0: start requires an uplink speed, aborting."
                exit -1
        fi

        # Traffic classes:
    # 1:2 Interactive (SSH, DNS, ACK, Quake)
    # 1:3 Low latency (VoIP)
    # 1:4 Browsing (HTTP, HTTPs)
    # 1:5 Default
    # 1:6 Middle-low priority 
    # 1:7 Lowest priority

    # add HFSC root qdisc
    tc qdisc add dev $DEV root handle 1: hfsc default 5

    # add main rate limit class
    tc class add dev $DEV parent 1: classid 1:1 hfsc \
      sc rate ${UPLINK}kbit ul rate ${UPLINK}kbit

    # Interactive traffic: guarantee full uplink for 50ms, then
    # 5/10 of the uplink

    tc class add dev $DEV parent 1:1  classid 1:2 hfsc \
      sc m1   ${UPLINK}kbit d  50ms m2 $((5*$UPLINK/10))kbit \
      ul rate ${UPLINK}kbit

    # VoIP: guarantee full uplink for 200ms, then 3/10
    tc class add dev $DEV parent 1:1  classid 1:3 hfsc \
      sc m1 ${UPLINK}kbit d 200ms m2 $((3*$UPLINK/10))kbit \
      ul rate ${UPLINK}kbit

    # Browsing: guarantee 3/10 uplink for 200ms, then
    # guarantee 1/10

    tc class add dev $DEV parent 1:1  classid 1:4 hfsc \
      sc m1 $((3*$UPLINK/10))kbit d 200ms m2 $((1*$UPLINK/10))kbit \
      ul rate ${UPLINK}kbit

    # Default traffic: guarantee 1/10 uplink for 100ms,
    # then guarantee 3/20

    tc class add dev $DEV parent 1:1  classid 1:5 hfsc \
      sc m1 $((1*$UPLINK/10))kbit d 100ms m2 $((3*$UPLINK/20))kbit \
      ul rate ${UPLINK}kbit

    # Middle-low taffic: don't guarantee anything for the first 5 seconds,
    # then guarantee 1/10

    tc class add dev $DEV parent 1:1  classid 1:6 hfsc \
      sc m1         0 d   5s m2 $((1*$UPLINK/10))kbit \
      ul rate ${UPLINK}kbit

    # Lowest taffic: don't guarantee anything for the first 10 seconds,
    # then guarantee 1/20
      #ls m2 $((1*$UPLINK/200))kbit \

    tc class add dev $DEV parent 1:1  classid 1:7 hfsc \
      ls m2 10kbit \
          ul rate $((UPLINK-100))kbit

    # add THESHAPER chain to the mangle table in iptables

    iptables -t mangle --new-chain THESHAPER
    iptables -t mangle --insert POSTROUTING -o $DEV -j THESHAPER
    
    # Type of serive filters (see /etc/iproute2/rt_dsfield)
    iptables -t mangle -A THESHAPER \
      -m tos --tos 0x10 \
      -j CLASSIFY --set-class 1:2

    iptables -t mangle -A THESHAPER \
      -m tos --tos 0x08 \
      -j CLASSIFY --set-class 1:7

    # To speed up downloads while an upload is going on, put short ACK
    # packets in the interactive class:

    iptables -t mangle -A THESHAPER \
      -p tcp \
      -m tcp --tcp-flags FIN,SYN,RST,ACK ACK \
      -m length --length :64 \
      -j CLASSIFY --set-class 1:2

    # put large (512+) icmp packets in default category
    iptables -t mangle -A THESHAPER \
      -p icmp \
      -m length --length 512: \
      -j CLASSIFY --set-class 1:5

    # ICMP (ip protocol 1) in the interactive class
    iptables -t mangle -A THESHAPER \
      -p icmp  \
      -m length --length :512 \
      -j CLASSIFY --set-class 1:2

    setclassbyport() {
      port=$1
      CLASS=$2
      iptables -t mangle -A THESHAPER -p udp --sport $port -j CLASSIFY --set-class $CLASS
      iptables -t mangle -A THESHAPER -p udp --dport $port -j CLASSIFY --set-class $CLASS
      iptables -t mangle -A THESHAPER -p tcp --sport $port -j CLASSIFY --set-class $CLASS
      iptables -t mangle -A THESHAPER -p tcp --dport $port -j CLASSIFY --set-class $CLASS
    }

    for port in $INTERACTIVEPORTS;  do setclassbyport $port 1:2; done
    for port in $VOIPPORTS;         do setclassbyport $port 1:3; done
    for port in $BROWSINGPORTS;     do setclassbyport $port 1:4; done
    for port in $DATAPORTS;         do setclassbyport $port 1:6; done
    for port in $P2PPORTS;          do setclassbyport $port 1:7; done

    for VOIP in $VOIPIPS
    do
      iptables -t mangle -A THESHAPER --src $VOIP -j CLASSIFY --set-class 1:3
      iptables -t mangle -A THESHAPER --dst $VOIP -j CLASSIFY --set-class 1:3
    done

    # put large (1024+) https packets in default category
    iptables -t mangle -A THESHAPER \
      -p tcp --dport 443 \
      -m length --length 1024: \
      -j CLASSIFY --set-class 1:6

    # put large (1024+) http packets in default category
    iptables -t mangle -A THESHAPER \
      -p tcp --dport 80 \
      -m length --length 1024: \
      -j CLASSIFY --set-class 1:6

    # put large (1024+) packets in default category
    #iptables -t mangle -A THESHAPER \
      #-p tcp \
      #-m length --length 1024: \
      #-j CLASSIFY --set-class 1:6

    # put large (1024+) ssh packets in default category
    iptables -t mangle -A THESHAPER \
      -p tcp --dport 22 \
      -m length --length 1024: \
      -j CLASSIFY --set-class 1:6

    # put all traffic from user torrent into p2p category (only works for the host this script runs on)
    iptables -t mangle -A THESHAPER \
      --match owner --uid-owner 169 -j CLASSIFY --set-class 1:7

    # Try to control the incoming traffic as well.
    # Set up ingress qdisc
    #tc qdisc add dev $DEV handle ffff: ingress

    # Filter everything that is coming in too fast
    # It's mostly HTTP downloads that keep jamming the downlink, so try to restrict
    # them to 95/100 of the downlink.

    # FIXME: slows down too much
#     tc filter add dev $DEV parent ffff: protocol ip prio 50 \ 
#        u32 match ip src 0.0.0.0/0 \ 
#        match ip protocol 6 0xff \ 
#        match ip sport 80 0xffff \ 
#        police rate $((95*${DOWNLINK}/100))kbit \ 
#        burst 10k drop flowid :1 
#  
#     tc filter add dev $DEV parent ffff: protocol ip prio 50 \
#        u32 match ip src 0.0.0.0/0 \
#        police rate $((95*${DOWNLINK}/100))kbit \
#                               burst $((95*${DOWNLINK}/100*2)) drop flowid :1 
}

function status() {
        check_device

        echo "[qdisc]"
    tc -s qdisc show dev $DEV

  echo ""
  echo "[class]"
    tc -s class show dev $DEV

  echo ""
  echo "[filter]"
    tc -s filter show dev $DEV

  echo ""
  echo "[iptables]"
    iptables -n -t mangle -L THESHAPER -v -x 2> /dev/null
}

case "$1" in
  status)
    status
  ;;
  stop) 
    stop 
  ;;
  start) 
    start
  ;;
  restart)
    stop
    start
  ;;
  *)
    echo "$0 [ACTION] [device]"
    echo "ACTION := { start | stop | status | restart }"
    exit
  ;;
esac
