#!/bin/bash
##
# written by Tim Meusel
# reviewed by Tobias Boehm
# gets all hdd models from an adaptec or lsi controller
# this is tested for Adaptec 5405, LSI 9260 (LSI's 2108 chip) and Dell Perc H710 (LSI's 2208 chip)
##
# 1-10-2014 extended by Tim Meusel
# added params 'hdd' and 'ssd'
# added support for more types
##
MEGACLI="/opt/MegaRAID/MegaCli/MegaCli64"
get_raid() {
  RAID_CTL="$(lspci | grep --ignore-case --extended-regexp '(LSI Logic / Symbios Logic (LSI MegaSAS 9260|MegaRAID SAS (2108|2208))|RAID bus controller: Adaptec AAC-RAID)')"
  echo "${RAID_CTL}"
}

get_lsi_ids() {
  NUMBERS="$(${MEGACLI} -pdlist -aAll | awk 'BEGIN {FS=":"} /Device Id:/ {print $2}' | sed ':a;N;$!ba;s/ *\n */ /g')"
  echo $NUMBERS
}

get_lsi_types() {
  declare -a TYPES
  for i in $(get_lsi_ids); do
    TYPE="$(smartctl -d sat+megaraid,$i -i /dev/sda | awk 'BEGIN {FS=":"} /Device Model/ {print $2}')"
    SPEED="$(get_link_speed_lsi $i)"
    TYPES+=($(fancy_output "${TYPE}" "${SPEED}"))
    fancy_output "${TYPE}" "${SPEED}"
  done
}

get_link_speed_lsi() {
  SPEED="$(${MEGACLI} -Pdinfo -physdrv [32:${1}] -aall | awk '{FS=":"} /Device Speed/ {print $2}')"
  SPEED="$(echo ${SPEED} | tr -d ' ')"
  echo "${SPEED}"
}

get_ip() {
  dig +short $(hostname)
}
fancy_output() {
  STRING="${1}"
  SPEED="${2}"
  IP=$(get_ip)
  case "${STRING}" in
    *"ST3000DM001"*     ) ;;
    *"ST33000651AS"*    ) ;;  
    *"DT01ACA300"*      ) ;;  
    *"WD1502FAEX"*      ) ;;  
    *"WD15EARS"*        ) ;;  
    *"ST31500341AS"*    ) ;;  
    *"HDS723015BLA642"* ) ;;
    *"HDS723020BLA642"* ) ;;
    *"ST2000NM0033"*    ) ;;
    *"ST33000650NS"*    ) ;;
    *"ST3600057SS"*     ) ;;
    *"HUS156060VLS600"* ) ;;
    *"WD2000FYYZ"*      ) ;;
    *"ST91000640NS"*    ) ;;
    *"MZ7WD480HAGM-"*   ) echo "MZ7WD480HAGM;Samsung Enterprise;${SPEED};${IP};Linux;";;
    *                   ) echo "${i};Unkown Vendor;${SPEED};${IP};Linux";;
  esac
}

give_me_smartmon() {
  if [ ! -f "/usr/sbin/smartctl" ]; then
    yum install --assumeyes --quiet smartmontools
  fi  
}


get_disk_types() {
  #shopt -s extglob
  case "$(get_raid)" in
    *"2208"* ) get_lsi_types;;
  esac
}
give_me_smartmon
get_disk_types
