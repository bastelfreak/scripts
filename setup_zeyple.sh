#!/bin/bash

##
# written by Tim 'bastelfreak' Meusel (https://bastelfreak.de)
# insalls zeyple (https://github.com/infertux/zeyple)
# encrypts outgoing mails to $EXT_ADDRESS from $INT_ADDRESS with a public GPG Key. 
# Usefull for sending e.g. cron mail
# some more infos aren't available at my blog https://blog.bastelfreak.de
##

# Hier die interne Adresse eintragen, an welche die System-Mails normalerweise gehen
INT_ADDRESS=$(whoami)@$(hostname -f)
# EXT_ADDRESS definiert die externe Adresse, an die der Server die verschluesselten System-Mails versenden soll. 
# Wichtig: Fuer diese Adresse muss ein oeffentlicher GPG-Schluessel auf dem Keyserver ($KEYSERVER_ADDRESS, siehe Zeile 9) zu finden sein
EXT_ADDRESS=monitoring@bastelfreak.org
# Die URL des Keyservers
KEYSERVER_ADDRESS=pool.sks-keyservers.net

# Abhaengigkeiten installieren
aptitude update 1>/dev/null && aptitude install -y sudo gpg python-gpgme 1>/dev/null
echo "sudo, gpg und python-gpgme wurden installiert"

# Anlegen des Systembenutzers, ohne Home-Directory und ohne Login- Erlaubnis
adduser --system --no-create-home --disabled-login zeyple >/dev/null
echo "Benutzer zeyple wurde angelegt"

# Ein Verzeichnis unter /etc fuer Konfigurationsdatei und die Schluesselverwaltung einrichten
mkdir -p /etc/zeyple/keys && chmod 700 /etc/zeyple/keys && chown zeyple: /etc/zeyple/keys
echo "Verzeichnisse wurden angelegt"

# Das Python-Skript zeyple.py herunterladen
if [ ! -e /usr/local/bin/zeyple.py ]; then
	wget --quiet --output-document=/usr/local/bin/zeyple.py https://raw.github.com/infertux/zeyple/master/zeyple/zeyple.py;
	chmod 744 /usr/local/bin/zeyple.py && chown zeyple: /usr/local/bin/zeyple.py;
fi
# Konfigurationsdatei herunterladen und Rechte setzen
if [ ! -e /etc/zeyple/zeyple.conf ]; then
	wget --quiet --output-document=/etc/zeyple/zeyple.conf https://raw.github.com/infertux/zeyple/master/zeyple/zeyple.conf.example;
	echo "Binary und Konfigurationsdatei wurden installiert";
fi

# Den oeffentlichen Schluessel fuer EXT_ADDRESS vom Keyserver holen und mit gpg importieren
sudo -u zeyple gpg --homedir /etc/zeyple/keys --keyserver $KEYSERVER_ADDRESS --search $EXT_ADDRESS

# Logdatei anlegen und Benutzerrechte setzen
if [ ! -e /var/log/zeyple.log ]; then
	touch /var/log/zeyple.log && chown zeyple: /var/log/zeyple.log
fi

if [ ! -e /etc/logrotate.d/zeyple ]; then
cat >> /etc/logrotate.d/zeyple <<END
/var/log/zeyple.log
{
        rotate 7
        daily
        missingok
        notifempty
        delaycompress
        compress
}
END
fi

# Postfix fuer zeyple vorbereiten: master.cf und main.cf um die Filtereintraege rweitern
if ! grep -quiet zeyple /etc/postfix/master.cf; then
cat >> /etc/postfix/master.cf <<END
zeyple  unix  -  n  n  -  -  pipe
  user=zeyple argv=/usr/local/bin/zeyple.py
localhost:10026  inet  n  -  n  -  10  smtpd
  -o content_filter=
  -o receive_override_options=no_unknown_recipient_checks,no_header_body_checks,no_milters
  -o smtpd_helo_restrictions=
  -o smtpd_client_restrictions=
  -o smtpd_sender_restrictions=
  -o smtpd_recipient_restrictions=permit_mynetworks,reject
  -o mynetworks=127.0.0.0/8
  -o smtpd_authorized_xforward_hosts=127.0.0.0/8
END
echo "/etc/postfix/master.cf wurde angepasst"
fi

# Damit Zeyple die Schluessel richtig zuordnet, empfiehlt es sich, die interne Mail-Adresse fuer eingehende Mails auf die externe umzuleiten
if ! grep -quiet "^$INT_ADDRESS\ $EXT_ADDRESS" /etc/postfix/recipient_canonical; then
	echo "$INT_ADDRESS $EXT_ADDRESS" >> /etc/postfix/recipient_canonical
	# Die Postfix-Empfaengerdatenbank neu erstellen
	postmap /etc/postfix/recipient_canonical
fi


# Datenbank in der Postfix-Adressenumschreibung bekannt machen und den Contentfilter eintragen
if ! grep -quiet zeyple /etc/postfix/main.cf; then
	echo "recipient_canonical_maps = hash:/etc/postfix/recipient_canonical" >> /etc/postfix/main.cf
	echo "content_filter = zeyple" >> /etc/postfix/main.cf
	echo "/etc/postfix/main.cf wurde angepasst"
fi

# Postfix-Konfiguration neu laden
/etc/init.d/postfix reload 1>/dev/null
echo "postfix wurde reloaded"

if [ $(pgrep -f /usr/lib/postfix/master) ]; then 
	echo "alles war erfolgreich"
else
	echo "postfix laeuft nicht, ich hab was kaputt gemacht. Bitte fix das schnell weil du grad keine mails verschicken kannst"
fi
