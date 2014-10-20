#!/bin/bash
set -e
set -u
Guest_name="alex_vserver"
host_tports=( '222' '8090' )
host_uports=( '11194' )
Guest_ipaddr=10.100.23.23
guest_tports=( '22' '80' )
guest_uports=( '1194' )

if [ $1 = $Guest_name ]
then
  tlength=$(( ${#host_tports[@]} - 1 ))
  ulength=$(( ${#host_uports[@]} - 1 ))
    if [[ $2 = "stopped" || $2 = "reconnect" ]]
    then
    # TCP ports
    for i in $(seq 0 $tlength); do
            iptables -t nat -D PREROUTING -p tcp --dport ${host_tports[$i]} -j DNAT --to $Guest_ipaddr:${guest_tports[$i]}
            iptables -D FORWARD -d $Guest_ipaddr/32 -p tcp -m state --state NEW,RELATED,ESTABLISHED -m tcp --dport ${guest_tports[$i]} -j ACCEPT

      #- allows port forwarding from localhost but 
      #  only if you use the ip (e.g http://192.168.1.20:8888/)
      iptables -t nat -D OUTPUT -p tcp -o lo --dport ${host_tports[$i]} -j DNAT --to $Guest_ipaddr:${guest_tports[$i]}
    done
    # UDP ports
    for i in $(seq 0 $ulength); do
            iptables -t nat -D PREROUTING -p udp --dport ${host_uports[$i]} -j DNAT --to $Guest_ipaddr:${guest_uports[$i]}
            iptables -D FORWARD -d $Guest_ipaddr/32 -p udp -m state --state NEW,RELATED,ESTABLISHED -m udp --dport ${guest_uports[$i]} -j ACCEPT

      #- allows port forwarding from localhost but 
      #  only if you use the ip (e.g http://192.168.1.20:8888/)
      iptables -t nat -D OUTPUT -p udp -o lo --dport ${host_uports[$i]} -j DNAT --to $Guest_ipaddr:${guest_uports[$i]}
    done
    fi
    if [[ $2 = "start" || $2 = "reconnect" ]]
    then
    # TCP ports
    for i in $(seq 0 $tlength); do
            iptables -t nat -I PREROUTING -p tcp --dport ${host_tports[$i]} -j DNAT  --to $Guest_ipaddr:${guest_tports[$i]}
            iptables -I FORWARD -d $Guest_ipaddr/32 -p tcp -m state --state NEW,RELATED,ESTABLISHED -m tcp --dport ${guest_tports[$i]} -j ACCEPT

          #- allows port forwarding from localhost but 
        #  only if you use the ip (e.g http://192.168.1.20:8888/)
      iptables -t nat -I OUTPUT -p tcp -o lo --dport ${host_tports[$i]} -j DNAT --to $Guest_ipaddr:${guest_tports[$i]}
    done
    # UDP ports
    for i in $(seq 0 $ulength); do
            iptables -t nat -I PREROUTING -p udp --dport ${host_uports[$i]} -j DNAT  --to $Guest_ipaddr:${guest_uports[$i]}
            iptables -I FORWARD -d $Guest_ipaddr/32 -p udp -m state --state NEW,RELATED,ESTABLISHED -m udp --dport ${guest_uports[$i]} -j ACCEPT

          #- allows port forwarding from localhost but 
        #  only if you use the ip (e.g http://192.168.1.20:8888/)
      iptables -t nat -I OUTPUT -p udp -o lo --dport ${host_uports[$i]} -j DNAT --to $Guest_ipaddr:${guest_uports[$i]}
    done
    fi
fi
