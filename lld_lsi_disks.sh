#!/bin/bash

##
# written by TMU
# inspired by JSK
##
# this detects all disks + their enclosure and creates json output for zabbix LLD
##

/opt/MegaRAID/MegaCli/MegaCli64 -pdlist -a0|egrep "Enclosure Device ID:|Slot Number:" | awk -F ':' '
BEGIN{countSlot=0; countEnc=0; }
  /Slot Number:/ {
    gsub(/^[ \t]+/, "", $2);
    gsub(/[ \t]+$/, "", $2);
    slot[countSlot] = $2;
    countSlot++;
  }
  /Enclosure Device ID:/ {
    gsub(/^[ \t]+/, "", $2);
    gsub(/[ \t]+$/, "", $2);
    enc[countEnc] = $2;
    countEnc++;
  }
  END{printf "{\n" "\t\"data\":[\n";
  for (i = 0; i < int(countEnc); i++) {
    if (i < (int(countEnc) - 1) && length(slot[i + 1]) != 0) printf "\t{\n" "\t\t\"{#SLOT}\": " slot[i] ",\n" "\t\t\"{#ENC}\": " enc[1] "\n" "\t},\n";
    else printf "\t{\n" "\t\t\"{#SLOT}\": " slot[i] ",\n" "\t\t\"{#ENC}\": " enc[1] "\n" "\t}\n";
  }
  print "\t]\n}\n"
}
'
