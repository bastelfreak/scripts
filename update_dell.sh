#!/bin/bash

##
# this script connects to every given host and updates several firmwares
# written by Tim 'bastelfreak' Meusel
##

# some vars
idrac_firmware="ESM_Firmware_XH6FX_WN32_1.57.57_A00.EXE"
lcc_firmware="Lifecycle-Controller_Application_C19M0_WN32_1.4.2.12_A00.EXE"
nic_firmware="Network_Firmware_HKK1W_WN32_15.0.28_A00.EXE"
bios_firmware="BIOS_T5GGG_WN32_2.2.2.EXE"
mirror="http://downloads.dell.com/Pages/Drivers/poweredge-r720.html"

# connects via ssh to $1 and installs the racadm tool
install_racadm() {
  local fqdn="${1}"
  echo "installing racadm on node ${fqdn}";
  ssh -p 222 -o 'StrictHostKeyChecking no' "${fqdn}" "iptables -A INPUT -p tcp --sport 11371 -j ACCEPT; \
    ip6tables -A INPUT -p tcp --sport 11371 -j ACCEPT; \
    apt-key adv --recv-keys --keyserver pool.sks-keyservers.net 1285491434D8786F; \ 
  if ! [ -f /etc/apt/sources.list.d/dell.list ]; then echo 'deb http://linux.dell.com/repo/community/ubuntu precise openmanage' > /etc/apt/sources.list.d/dell.list; fi; \
    aptitude update; aptitude install -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' srvadmin-idracadm7 srvadmin-hapi; \
    /etc/init.d/instsvcdrv start;"
}

update() {
  local fqdn="${1}"
  local firmware="${2}"
  echo "updating ${firmware} on node ${fqdn}";
  ssh -p 222 -o 'StrictHostKeyChecking no' "${fqdn}" "if ! [ -f \"/tmp/${firmware}\" ]; then wget --quiet \"${mirror}/${firmware}\" -O \"/tmp/${firmware}\"; fi; \
    /opt/dell/srvadmin/sbin/racadm update -f \"/tmp/${firmware}\""
}

update_everything() {
  local fqdn="${1}"
  for firmware in "${lcc_firmware}" "${nic_firmware}" "${bios_firmware}" "${idrac_firmware}"; do
    update "${fqdn}" "${firmware}"
    disable_snmp "${fqdn}"
  done
}

update_all() {
  for fqdn in $(cat hosts); do
    update_everything "${fqdn}"
  done
}

if [ -n "${1}" ]; then
  if [ -n "${2}" ]; then
    update "${1}" "${2}"
  else
    update_everything "${1}"
  fi
else
  update_all
fi
