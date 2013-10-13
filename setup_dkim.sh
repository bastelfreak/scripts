#!/bin/bash

##
# written by Tim 'bastelfreak' Meusel (https://bastelfreak.de)
# installs opendkim
# creates keys for every domain and every used email address. 
# These infos are fetched from a mysql DB
# schema is based on the mailserver tutorial at workaround.org/ispmail/squeeze
# some more infos are available at my blog https://blog.bastelfreak.de/?p=721
##

MYSQLFILE="/etc/postfix/mysql-virtual-alias-maps.cf"
USER=$(awk '/^user/ {print $3}' ${MYSQLFILE})
PASS=$(awk '/^password/ {print $3}' ${MYSQLFILE})
HOST=$(awk '/^hosts/ {print $3}' ${MYSQLFILE})
PASS=$(awk '/^dbname/ {print $3}' ${MYSQLFILE})
QUERY="(SELECT virtual_aliases.source as subject FROM \`virtual_aliases\`) UNION DISTINCT (SELECT virtual_aliases.destination as subject FROM \`virtual_aliases\`) UNION DISTINCT (SELECT virtual_users.email as subject FROM \`virtual_users\`) ORDER BY \`SUBJECT\` ASC"
CONF_DIR="/etc/opendkim"
SENDER_MAP="${CONF_DIR}/SigningTable"
KEY_MAP="${CONF_DIR}/KeyTable"
CONF_FILE="/etc/opendkim.conf"
DEF_FILE="/etc/default/opendkim"
KEY_DIR="${CONF_DIR}/keys"
POSTFIX="/etc/postfix/main.cf"
TOTAL=0
NEW=0
green="\e[0;32m"
orange="\e[0;33m"
endColor="\e[0m"
aptitude install -y opendkim mysql-client 1> /dev/null
mkdir "${CONF_DIR}"
if [ ! -e "${SENDER_MAP}" ]; then
	touch "${SENDER_MAP}"
fi
if [ ! -e "${KEY}" ]; then
	touch "${KEY_MAP}"
fi
if ! grep --quiet "^KeyTable" "${CONF_FILE}"; then
	echo "KeyTable ${KEY_MAP}" >> "${CONF_FILE}"
fi
if ! grep --quiet "^SigningTable" "${CONF_FILE}"; then
	echo "SigningTable refile:${SENDER_MAP}" >> "${CONF_FILE}"
fi
if ! grep --quiet "^SOCKET" "${DEF_FILE}"; then
	echo "SOCKET=\"inet:8891@localhost\"" >> "${DEF_FILE}"
fi
if ! grep --quiet "^milter_default_action" "${POSTFIX}"; then
	echo "milter_default_action = accept" >> "${POSTFIX}"
fi
if ! grep --quiet "^milter_protocol" "${POSTFIX}"; then
	echo "milter_protocol = 2" >> "${POSTFIX}"
fi
if ! grep --quiet "^smtpd_milters" "${POSTFIX}"; then
	echo "smtpd_milters = inet:localhost:8891" >> "${POSTFIX}"
fi
if ! grep --quiet "^non_smtpd_milters" "${POSTFIX}"; then
	echo "non_smtpd_milters = inet:localhost:8891" >> "${POSTFIX}"
fi
for SUBJECT in $(mysql --user="${USER}" --host="${HOST}" --password="${PASS}" "${DB}" --execute "${QUERY}" | awk '{print $1}' | grep -v ^subject$); do
	(( TOTAL++ ))
	if [ "${SUBJECT:0:1}" == "@" ]; then
		STRING=$(grep "^*${SUBJECT} " "${SENDER_MAP}")
		KEYNAME="default"
	else
		STRING=$(grep "^${SUBJECT} " "${SENDER_MAP}")
		KEYNAME=$(echo "${SUBJECT}" | cut -d'@' -f1)
	fi
	if [ -z "${STRING}" ]; then
		(( NEW++ ))
		DOMAIN=$(echo "${SUBJECT}" | cut -d'@' -f2)
		mkdir -p "${KEY_DIR}/${DOMAIN}"
		opendkim-genkey -S -r -s "${KEYNAME}" -b 2048 -d ${DOMAIN} -D "${KEY_DIR}/${DOMAIN}"
		SUM=$(echo -n "${SUBJECT}" | sha512sum)
		TXT_RECORD="${SUM:16:32}"
		echo "${TXT_RECORD} ${DOMAIN}:${KEYNAME}:${KEY_DIR}/${DOMAIN}:${KEYNAME}" >> "${KEY_MAP}"
		if [ "${SUBJECT:0:1}" == "@" ]; then
			echo "*${SUBJECT} ${TXT_RECORD}" >> "${SENDER_MAP}"
		else
			echo "${SUBJECT} ${TXT_RECORD}" >> "${SENDER_MAP}"
		fi
		echo -e "${green}Done with ${DOMAIN} ${endColor}"
	fi
done
chown opendkim:opendkim /etc/dkim/keys/* -R
/etc/init.d/postfix reload 1> /dev/null
echo -e "${green}Processed ${TOTAL} subjects, ${NEW} are new${endColor}"
if [ $(pgrep -f /usr/lib/postfix/master) ]; then
	echo -e "${green}Postfix reload was also successfull. Postfix will now sign outgoing mails via opendkim. You have to add the TXT records to your zone file to allow other mailserver to verify your signature${endColor}"
else 
	echo -e "${orange}Postfix reload failed. Please view these logs:${endColor}"
	tail -n10 /var/log/mail.log
fi
