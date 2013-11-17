#!/bin/bash

##
# written by Tim Meusel, 07.09.2013
# improved and audited from aibo
# this script has to be placed on a webserver to add new vhosts and dns records
# you can place a copy of this script on two servers and migrate websites from one host to another
##

# http://www.davidpashley.com/articles/writing-robust-shell-scripts/
set -e

setup_php() {
	# TODO: set suitable rights for the new config file
	# $1 is something like 9001 # the port for the fcgi
	# $2 is the domain name
	if [ -z "${1}" ] || [ -z "${2}" ]; then
		exit 1
	fi
	local domain="${2}"
	local port="${1}"
	local config="/etc/php5/fpm/pool.d/${domain}.conf"
	if [ ! -e "${config}" ]; then
		touch /etc/php5/fpm/pool.d/"${domain}".conf
cat >> "/etc/php5/fpm/pool.d/${domain}.conf" <<END
[${domain}]
user = ${domain}
group = ${domain}
listen = 127.0.0.1:${port}
pm = dynamic
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
chdir = /
END
		service php5-fpm force-reload
	fi
}

add_domain_to_dns() {
	# adds the domain to the powerdns db
	true
}

create_user() {
	# $1 is something lile 'google.de /home'
	if [ -z "${1}" ]; then
		exit 1
	fi
	local domain=${1%% *}
	local root_path=${1#* }
	# create password and echo it
	#local pw="$(openssl rand -hex 16)"
	#local pwhash="$(openssl passwd -crypt ${PW})"
	#echo "the new password is ${pw}"
	# create user, set pw, disable shell, create home and group
	#useradd --shell /bin/false --create-home --home=${root_path}/${domain} --user-group --password ${pwhash} ${domain}
	#useradd --shell /bin/false --create-home --home="${root_path}/${domain}" --user-group --disabled-password --gecos "" "${domain}"
	if ! grep -quiet "${domain}" /etc/passwd; then
		adduser --force-badname --disabled-password --group --gecos "" --home "${root_path}/${domain}" --shell /bin/bash "${domain}"
	fi
}

create_directories() {
	# $1 is something like 'google.de /home'
	if [ -z "${1}" ]; then
		exit 1
	fi
	local domain=${1%% *}
	local root_path=${1#* }
	mkdir -p "${root_path}/${domain}/{htdocs,logs,config,tmp}" > /dev/null
	chown --recursive "${domain}:${domain}" "${root_path}/${domain}"
	chown 755 --recursive "${root_path}/${domain}"
}

get_highest_fpm_port() {
	# the default port from the standard php-fpm config is 9000
	local max_port=9001
	local port=0

	for i in /etc/php5/fpm/pool.d/*.conf; do
  	port="$(awk 'BEGIN {FS=":"} /^listen/ {print $2}' ${i})"
  	[[ "${port}" =~ [0-9]+ ]] && [ "${port}" -gt "${max_port}" ] && max_port="${port}"
	done
	echo "${max_port}"
}

add_apache_vhost() {
	local port="$(get_highest_fpm_port)"
	# $1 is something like 'google.de /home'
	if [ -z "${1}" ] || [ -z "${port}" ]; then
		exit 1
	fi
	local domain=${1%% *}
	local root_path=${1#* }
	let PORT++
cat >> "/etc/apache2/sites-available/${domain}" <<END
<VirtualHost *:80>
	DocumentRoot ${root_path}/${domain}/htdocs
	ServerName ${domain}.de
  ServerAdmin admin@${domain}
	<Directory ${root_patch}/${domain}/htdocs>
		Options -Indexes
    Order allow,deny
    allow from all
    AllowOverride All
	</Directory>
	ErrorLog ${root_path}/${domain}/error.apache.log
  LogLevel info
  CustomLog ${root_path}/${domain}/logs/access.log combined
	php_flag log_errors on
	php_value error_log ${root_path}/${domain}/logs/error.php.log
<IfModule mod_fastcgi.c>
	AddHandler php5-fcgi .php
	Action php5-fcgi /php5-fcgi
	Alias /php5-fcgi /usr/lib/cgi-bin/php5-fcgi
	FastCgiExternalServer /usr/lib/cgi-bin/php5-fcgi -host 127.0.0.1:${port} -pass-header Authorization
</IfModule>
</VirtualHost>
END
	setup_php "${port}" "${domain}"
	/usr/sbin/a2ensite "${domain}"
}

add_lighttpd_vhost() {
	# this is for later usage, because someday.... we want to have apache and lighty working in awesome coexistence
	true
}

output_help() {
	echo "written by Tim 'bastelfreak' Meusel <tim@online-mail.biz>"
	echo "you are using my awesome script, thanks :)"
	echo "Usage is easy:"
	echo "-h ## prints this help"
	echo "-r new-server.de ## script will copy a website to this server, also needs -d, -n and -o"
	echo "-o /var/www ## local path to the root directory of the website that we want to copy, e.g. /var/www/"
	echo "-d example.com ## fqdn for the site to setup, this will be the linux user on the new system"
	echo "-n /home/awesomedirformanynewsites ## this will be the new home directory for our website. here we place the site itself, logs, configs"
	echo ""
}
##
# under this line, the real magic is gonna happen
##

## check here for every parameter
if [ -z "${1}" ]; then
	output_help
	exit 0
fi

while getopts ":h:r:o:d:n:w:a:s:c:" opt; do
	case "${opt}" in
		h ) output_help; exit 0;;
		r ) REMOTE="${OPTARG}";;
		o ) DIR="${OPTARG}";;
		d ) DOMAIN="${OPTARG}";;
		n ) NEWHOME="${OPTARG}";;
		w ) WEBSERVER="${OPTARG}";; # thats currently not supported, you have to use apache
		# define function calls
		a ) [ -z "${REMOTE}" ] && create_user "${OPTARG}" || exit 1;;
		s ) [ -z "${REMOTE}" ] && add_apache_vhost "${OPTARG}" || exit 1;;
		c ) [ -z "${REMOTE}" ] && create_directories "${OPTARG}" || exit 1;;
		: ) echo "something is wrong with the parameters"; exit 1;;
	esac
done
	
# check if we have to move a website to a new server
if [ ! -z "${REMOTE}" ]; then
	# output some help
	echo "what we do now:"
	echo "check for local ssh key, create one if necessary and copy it to the new server"
	echo "copy the provided path to new server"
	echo "(path has to be a local one like /var/www/ to the root of a website)"
	echo "Important: remote servers sshd has to be on port 22"
	# check for some vars
	if [ -z "${DIR}" ]; then
		echo "your have to provide a path like '-o /var/www', otherwise we can't copy anything"
		exit 1;
	elif [ ! -d "${DIR}" ]; then
		echo "your provided path is not valid"
		echo "${DIR}"
		exit 1
	fi 
	echo "your -o param seems valid, it is ${DIR}"
	if [ -z "${DOMAIN}" ]; then
		echo "you also have to provide the domain for the new vhost (-d)"
		exit 1
	fi
	echo "your -d param seems valid, it is ${DOMAIN}"
	if [ -z "${NEWHOME}" ]; then
		echo "you have to provide the new root path for the website (-n)"
		exit 1
	fi
	echo "your -n param seems valid, it is ${NEWHOME}"
	# check for ssh key, if none then create one
	if [ ! -f "/root/.ssh/id_rsa.pub" ] || [ ! -f "/root/.ssh/id_rsa" ]; then
		ssh-keygen -b 8192 -N "" -f /root/.ssh/id_rsa -t rsa
	fi

	##
	# the following part has to be more beautiful, we have to handle exit codes
	##

	# copy ssh key ## TODO: check if the key already exists on the destination
	ssh-copy-id -i ~/.ssh/id_rsa.pub ${REMOTE}
	# create remote user
	ssh "${REMOTE}" "/root/scripts/setup_domain.sh -a '${DOMAIN} ${NEWHOME}'"
	# create directories
	ssh "${REMOTE}" "/root/scripts/setup_domain.sh -c '${DOMAIN} ${NEWHOME}'"
	# create apache vhost, this also triggers setup_php
	ssh "${REMOTE}" "/root/scripts/setup_domain.sh -s '${DOMAIN} ${NEWHOME}'"
	# start the rsync
	rsync --itemize-changes --archive --stats "${DIR}/" -e 'ssh -i /root/.ssh/id_rsa' "root@${REMOTE}:${NEWHOME}/${DOMAIN}/${htdocs}"
	# set the permissions again
	ssh "${REMOTE}" "chown --recursive ${DOMAIN}:${DOMAIN} ${NEWHOME}:${NEWHOME}"
fi
