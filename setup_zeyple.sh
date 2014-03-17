#!/bin/bash

##
#	   This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
##

##
# written by Tim 'bastelfreak' Meusel (http://bastelfreak.de)
# installs zeyple (https://github.com/infertux/zeyple)
# encrypts outgoing mails to $EXT_ADDRESS from $INT_ADDRESS with a public GPG Key. 
# Usefull for sending e.g. cron mail
# some more infos aren't available at my blog http://blog.bastelfreak.de
# $INT_ADDRESS is currently root
##

INT_ADDRESS="root@$(hostname -f)"
# zeyple looks for emails from INT_ADDRESS to EXT_ADRESS and crypts them with the public from from EXT_ADDRESS
# the key for EXT_ADDRESS has to be on KEY_SERVER_ADDRESS
EXT_ADDRESS=monitoring@bastelfreak.org
# URL to the public keyserver
KEYSERVER_ADDRESS=pool.sks-keyservers.net

# installing dependencies
aptitude update 1>/dev/null && aptitude install -y sudo gpg python-gpgme 1>/dev/null
echo "sudo, gpg and python-gpgme were already installed or got installed"

# adding user for zeyple
adduser --system --no-create-home --disabled-login zeyple >/dev/null
echo "added uer zeyple"

# create the configuration directory and set corret permissions
mkdir -p /etc/zeyple/keys
chmod 700 /etc/zeyple/keys
chown zeyple: /etc/zeyple/keys
echo "directories got created"

# Now we download zeyple itself and the config file and overwrite older local versions
#if [ ! -e /usr/local/bin/zeyple.py ]; then
	wget --quiet --output-document=/usr/local/bin/zeyple.py https://raw.github.com/infertux/zeyple/master/zeyple/zeyple.py
	chmod 744 /usr/local/bin/zeyple.py && chown zeyple: /usr/local/bin/zeyple.py
#fi
if [ ! -e /etc/zeyple/zeyple.conf ]; then
	wget --quiet --output-document=/etc/zeyple/zeyple.conf https://raw.github.com/infertux/zeyple/master/zeyple/zeyple.conf.example;
fi
echo "downloaded zeyple binary"
# getting the public key that we need for crypting
sudo -u zeyple gpg --homedir /etc/zeyple/keys --keyserver $KEYSERVER_ADDRESS --search $EXT_ADDRESS

# creating logfile and logrotate config
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
if ! grep --quiet "^zeyple" /etc/postfix/master.cf; then
cat >> /etc/postfix/master.cf <<END
zeyple    unix  -       n       n       -       -       pipe
  user=zeyple argv=/usr/local/bin/zeyple.py \${recipient}

localhost:10026 inet  n       -       n       -       10      smtpd
  -o content_filter=
  -o receive_override_options=no_unknown_recipient_checks,no_header_body_checks,no_milters
  -o smtpd_helo_restrictions=
  -o smtpd_client_restrictions=
  -o smtpd_sender_restrictions=
  -o smtpd_recipient_restrictions=permit_mynetworks,reject
  -o mynetworks=127.0.0.0/8
  -o smtpd_authorized_xforward_hosts=127.0.0.0/8
END
echo "modified /etc/postfix/master.cf"
fi

# map the INT_ADDRESS to the EXT_ADDRESS
if ! grep --quiet "^$INT_ADDRESS\ $EXT_ADDRESS" /etc/postfix/recipient_canonical; then
	echo "$INT_ADDRESS $EXT_ADDRESS" >> /etc/postfix/recipient_canonical
	postmap /etc/postfix/recipient_canonical
fi


# tell postfix to use our mapping and zeyple
if ! grep --quiet zeyple /etc/postfix/main.cf; then
	echo "recipient_canonical_maps = hash:/etc/postfix/recipient_canonical" >> /etc/postfix/main.cf
	echo "content_filter = zeyple" >> /etc/postfix/main.cf
	echo "modifed /etc/postfix/main.cf"
fi

/etc/init.d/postfix reload 1>/dev/null
echo "postfix wurde reloaded"

if [ $(pgrep -f /usr/lib/postfix/master) ]; then 
	echo "we are done and postfix is running"
else
	echo "postfix failed after the reload, please view mail.log:"
	tail /var/log/mail.log
fi
