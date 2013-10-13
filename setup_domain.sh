#!/bin/bash

##
# written by Tim Meusel, 07.09.2013
# $1 has to be the new domain that we want to create
##

function setup_php {
	touch /etc/php5/fpm/pool.d/"${DOMAIN}"
}

function add_domain {
 true
}

function create_directories_and_user {
	# create password and echo it
	local PW=$(openssl rand -hex 16)
	local HASH=$(openssl passwd -crypt ${PW})
	local HOME="/home/${DOMAIN}"
	echo "the new password is ${PW}"
	unset ${PW}
	# create user, set pw, disable shell, create home and group
	useradd --shell /bin/false --create-home --home=${HOME} --user-group --password ${HASH} ${DOMAIN}
	unset ${HASH}
	mkdir -p "${HOME}/htdocs"
	mkdir -p "${HOME}/logs"
	mkdir -p "${HOME}/config"
	mkdir -p "${HOME}/tmp"
}

function add_apache_vhost {
cat >> "/etc/apache2/sites-available/${DOMAIN}" <<END
<VirtualHost *:80>
	DocumentRoot /home/www/de/root
	ServerName www..de
  ServerAdmin me@
	<Directory /home/www/kaltmae/root/>
		Options -Indexes
    Order allow,deny
    allow from all
    AllowOverride All
	</Directory>
	ErrorLog /var/log/apache2/.de.error.log
  LogLevel warn
  CustomLog /var/log/apache2/r.de.access.log combined
  CustomLog /var/log/apache2/access.log combined
</VirtualHost>
END
}

function add_lighttpd_vhost {
# this is for later usage, because someday.... we want to have apache and lighty working in awesome coexistence
	true
}

if [ ! -z "${1}" ]; then
	echo "seems to be a valid domain, we are starting to make magic"
	DOMAIN="${1}"
	create_directories_and_user

fi
