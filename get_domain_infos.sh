#!/bin/bash

# path to the domain list
if [ "$2" ]; then
	DOMAINLIST="$2"
else
	DOMAINLIST="domainlist"
fi

# path to the NS list
NSLIST="nslist.txt"

# path to the MX list
MXLIST="mxlist.txt"

# path to the A list
ALIST="a.txt"

# $1 is expected and has to be a domain
get_MX_records(){
	if [ -e "$MXLIST" ]; then	
		rm $MXLIST
		touch $MXLIST
	fi
	for DOMAIN in $(cat $DOMAINLIST); do
		echo -n "${DOMAIN};" >> $MXLIST
		dig MX $DOMAIN +short | while read MAILSERVER; do
			MST=$(echo "${MAILSERVER};" | cut -d" " -f2)
			echo -n $MST >> $MXLIST
		done
		echo "" >> $MXLIST
	done
	#grep -v '^$' $MXLIST > $MXLIST
	grep -v '^$' $MXLIST > "/tmp/$MXLIST"
	rm $MXLIST
	mv "/tmp/$MXLIST" $MXLIST
}

get_NS_records(){
	if [ -e "$NSLIST" ]; then
		rm $NSLIST
		touch $NSLIST
	fi
	for DOMAIN in $(cat $DOMAINLIST); do
		echo -n "${DOMAIN};" >> $NSLIST
		dig NS $DOMAIN +short | while read NAMESERVER; do
			echo -n "${NAMESERVER};" >> $NSLIST
		done
		echo "" >> $NSLIST
	done
	#grep -v '^$' $MXLIST > $MXLIST
	grep -v '^$' $NSLIST > "/tmp/$NSLIST"
	rm $NSLIST
	mv "/tmp/$NSLIST" $NSLIST
}
	

get_A_records(){
	if [ -e "$ALIST" ]; then
		rm $ALIST
		touch $ALIST
	fi
	for DOMAIN in $(cat $DOMAINLIST); do
		echo -n "${DOMAIN};" >> $ALIST
		dig A $DOMAIN +short | while read NAMESERVER; do
			echo -n "${NAMESERVER};" >> $ALIST
		done
		echo "" >> $ALIST
	done
	#grep -v '^$' $MXLIST > $MXLIST
	grep -v '^$' $ALIST > "/tmp/$ALIST"
	rm $ALIST
	mv "/tmp/$ALIST" $ALIST
}

if [ "$1" ]; then 
	case $1 in
		ns|NS|Nameserver|NAMESERVER)
			get_NS_records
			;;
		mx|MX)
			get_MX_records
			;;
		a|A)
			get_A_records
			;;
		all|All|ALL)
			get_NS_records
			get_MX_records
			get_A_records
			;;
		*)
			echo "\$1 has to be ns, mx, a or all to get the suitable DNS records, \$2 can be a path to a domain list"
			;;
	esac
else
	echo "\$1 is not set, should be something"
	echo "\$1 has to be ns, mx, a or all to get the suitable DNS records, \$2 can be a path to a domain list"
fi
