#!/bin/bash
# created by Thore Boedecker <me@foxxx0.de>
# WTFGPL license
_INTERFACE="extern0"
_ID='my.fqdn.net'
_PW='secret!'
_IP=''
_DNS=''

function get_ip() {
  _IP=$(ip -4 -o addr show dev ${_INTERFACE} |awk '{print $4}' |sed 's/\/.*$//g' |tr '\n' '\0')
}

function get_dns() {
  _DNS=$(host ${_ID} |awk '{print $4}' |tr '\n' '\0')
}

function update_dns() {
  UPDATERESULT=$(curl https://www.dtdns.com/api/autodns.cfm\?id\=${_ID}\&pw\=${_PW}  |grep 'now points' 2>&1 > /dev/null)
  if [[ $UPDATERESULT -eq 0 ]]; then
    # update worked
    echo 'Success: Updated dtdns pointer'
  else
    echo 'Error: Failed to update dtdns pointer'
    exit 1
  fi
}

get_ip
get_dns
if [[ "${_IP}" == "${_DNS}" ]]; then
  exit 0
else
  update_dns
  exit 0
fi

