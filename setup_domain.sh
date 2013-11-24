#!/bin/bash

##
# written by Tim Meusel, initial start 07.09.2013
# improved and audited by aibo
# this script has to be placed on a webserver to add new vhosts and dns records
# you can place a copy of this script on two servers and migrate websites from one host to another
##

# http://www.davidpashley.com/articles/writing-robust-shell-scripts/
set -e

setup_php() {
	if [ -z "${1}" ] || [ -z "${2}" ]; then
		exit 1
	fi
	local domain="${2}"
	local port="${1}"
	local root_path="${3}"
	local config="/etc/php5/fpm/pool.d/${domain}.conf"
	if [ ! -f "${config}" ]; then
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
php_admin_flag[log_errors] = on
php_admin_value[error_log] = ${root_path}/${domain}/logs/error.php.log
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
	if ! grep --quiet "${domain}" /etc/passwd; then
		adduser --force-badname --disabled-password --gecos "" --home "${root_path}/${domain}" --shell /bin/bash "${domain}"
		usermod --append --groups "${domain}" www-data
		usermod --append --groups www-data "${domain}"
	fi
}

create_directories() {
	# $1 is something like 'google.de /home'
	if [ -z "${1}" ]; then
		exit 1
	fi
	local domain=${1%% *}
	local root_path=${1#* }
	mkdir -p "${root_path}/${domain}/htdocs"
	mkdir -p "${root_path}/${domain}/tmp"
	mkdir -p "${root_path}/${domain}/config"
	mkdir -p "${root_path}/${domain}/logs"
	chown --recursive "${domain}:${domain}" "${root_path}/${domain}"
	chmod 755 --recursive "${root_path}/${domain}"
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
	let port++
	if [ ! -f "/etc/apache2/sites-available/${domain}" ]; then
cat >> "/etc/apache2/sites-available/${domain}" <<END
<VirtualHost *:80>
	DocumentRoot ${root_path}/${domain}/htdocs
	ServerName ${domain}
  ServerAdmin admin@${domain}
	<Directory ${root_path}/${domain}/htdocs>
		Options -Indexes
    Order allow,deny
    allow from all
    AllowOverride All
	</Directory>
	ErrorLog ${root_path}/${domain}/logs/error.apache.log
  LogLevel info
  CustomLog ${root_path}/${domain}/logs/access.log combined
  CustomLog /home/files.bastelfreak.de/logs/access.log combined
	# Set handlers for PHP files.
	# application/x-httpd-php                        phtml pht php
	# application/x-httpd-php3                       php3
	# application/x-httpd-php4                       php4
	# application/x-httpd-php5                       php
	<FilesMatch ".+\.ph(p[345]?|t|tml)$">
		SetHandler application/x-httpd-php
	</FilesMatch>
	# Define Action and Alias needed for FastCGI external server.
	Action application/x-httpd-php /fcgi-bin/php5-fpm virtual
	Alias /fcgi-bin/php5-fpm /fpm-${domain}
	<Location /fcgi-bin/php5-fpm>
		# here we prevent direct access to this Location url,
		# env=REDIRECT_STATUS will let us use this fcgi-bin url
		# only after an internal redirect (by Action upper)
		Order Deny,Allow
		Deny from All
		Allow from env=REDIRECT_STATUS
	</Location>
	<IfModule mod_fastcgi.c>
		# throws error, so disabled:
		# [warn] FastCGI: there is no fastcgi wrapper set, user/group options are ignored
		#FastCgiExternalServer /fpm-${domain} -host 127.0.0.1:${port} -pass-header Authorization -user ${domain} -group ${domain}
		FastCgiExternalServer /fpm-${domain} -host 127.0.0.1:${port} -pass-header Authorization
	</IfModule>
</VirtualHost>
END
		/usr/sbin/a2ensite "${domain}"
		service apache2 reload
	fi
	setup_php "${port}" "${domain}" "${root_path}"

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
	if [ -z "${DOMAIN}" ]; then
		echo "you also have to provide the domain for the new vhost (-d)"
		exit 1
	fi
	if [ -z "${NEWHOME}" ]; then
		echo "you have to provide the new root path for the website (-n)"
		exit 1
	fi
	# check for ssh key, if none then create one
	if [ ! -f "/root/.ssh/id_rsa.pub" ] || [ ! -f "/root/.ssh/id_rsa" ]; then
		ssh-keygen -b 8192 -N "" -f /root/.ssh/id_rsa -t rsa
	fi

	##
	# the following part has to be more beautiful, we have to handle exit codes
	##

	# copy ssh key
	echo "test if ssh via key works"
	set +e
	ssh -o BatchMode=yes -q "${REMOTE}" true
	code="${?}"
	set -e
	echo "exit code is ${code}"
	if [ "${code}" != 0 ]; then
		echo "now we copy the key"
		ssh-copy-id -i ~/.ssh/id_rsa.pub ${REMOTE}
	fi
	# check if ssh is working
	echo "we do another ssh test"
	set +e
	ssh -o BatchMode=yes -q "${REMOTE}" true
	code="${?}"
	set -e
	if [ ${code} != 0 ]; then
		echo "Remote Login via ssh didn't work"
		exit 1
	fi
	echo "ssh is working"
	# create remote user
	ssh "${REMOTE}" "/root/scripts/setup_domain.sh -a '${DOMAIN} ${NEWHOME}'"
	# create directories
	ssh "${REMOTE}" "/root/scripts/setup_domain.sh -c '${DOMAIN} ${NEWHOME}'"
	# create apache vhost, this also triggers setup_php
	ssh "${REMOTE}" "/root/scripts/setup_domain.sh -s '${DOMAIN} ${NEWHOME}'"
	# start the rsync
	rsync --itemize-changes --archive --stats "${DIR}/" -e 'ssh -i /root/.ssh/id_rsa' "root@${REMOTE}:${NEWHOME}/${DOMAIN}/htdocs"
	# set the permissions again
	ssh "${REMOTE}" "chown --recursive ${DOMAIN}:${DOMAIN} ${NEWHOME}/${DOMAIN}"
fi
