#!/bin/bash

##
# written by Tim Meusel, 07.09.2013
# this script has to be placed on a webserver to add new vhosts and dns records
# you can place a copy of this script on two servers and migrate websites from one host to another
##

setup_php() {
	# $1 is the new port that we have to set in this config file
	# $2 is the fqdn for the site
	local port="${1}"
	local domain="${2}"
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
}

add_domain_to_dns() {
	# adds the domain to the powerdns db
	true
}

create_user() {
	# $1 is something lile google.de
	# $2 is the root dir, like /home
	local domain="${1}"
	local root_path="${2}"
	# create password and echo it
	local pw="$(openssl rand -hex 16)"
	local pwhash="$(openssl passwd -crypt ${PW})"
	echo "the new password is ${pw}"
	# create user, set pw, disable shell, create home and group
	useradd --shell /bin/false --create-home --home=${root_path}/${domain} --user-group --password ${pwhash} ${domain}
}

create_directories() {
	# $1 is something lile google.de
	# $2 is the root dir, like /home
	#	 TODO: set correct permissions (or at least set any permissions)
	local domain="${1}"
	local root_path="${2}"
	mkdir -p "${root_path}/${domain}/{htdocs,logs,config,tmp}"
}

get_highest_fpm_port() {
	local max_port=0
	local port=0

	for i in /etc/php5/fpm/pool.d/*.conf; do
  	port="$(awk 'BEGIN {FS=":"} /^listen/ {print $2}' ${i})"
  	[[ "${port}" =~ [0-9]+ ]] && [ "${port}" -gt "${max_port}" ] && max_port="${port}"
	done
	echo "${max_port}"
}

add_apache_vhost() {
	# $1 is something like google.de // a complete domain without www
	# $2 is the root dir, like /home
	local domain="${1}"
	local root_path="${2}"
	local port="$(get_highest_fpm_port)"
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
	echo "-h/--help ## prints this help"
	echo "-r/--remote new-server.de ## script will copy a website to this server, also needs --dir and --domain"
	echo "-d/--dir ## local path to the root directory of the website that we want to copy, e.g. /var/www/"
	echo "--domain ## fqdn for the site to setup, this will be the linux user on the new system"
	echo "-n/--newhome ## this will be the new home directory for our website. here we place the site itself, logs, configs"
	echo ""
}
##
# under this line, the real magic is gonna happen
##

## check here for every parameter
while getopts "h:help:?:r:remote:d:dir:domain:n:newhome:webserver:add-user:setup-vhost:create-directories:" opt; do
	case ${opt} in
		h|help|?) output_help; exit 0;;
		r|remote) REMOTE="${OPTARG}";;
		d|dir) DIR="${OPTARG}";;
		domain) DOMAIN="${OPTARG}";;
		n|newhome) NEWHOME="${OPTARG}";;
		webserver) WEBSERVER="${OPTARG}";; # thats currently not supported, you have to use apache
		#owner) OWNER="${OPTARG}";;
		# define function calls
		add-user) [ -z "${REMOTE}" ] && create_user "${OPTARG}" || exit 1;;
		setup-vhost) [ -z "${REMOTE}" ] && add_apache_vhost "${OPTARG}" || exit 1;;
		create-directories) [ -z "${REMOTE}" ] && create_directories "${OPTARG}" || exit 1;;
	esac
done
	
# check if we have to move a website to a new server
if [ ! -z "${REMOTE}" ]; then
	# output some help
	echo "what we do now:"
	echo "check for local ssh key, create one if necessary and copy it to the new server"
	echo "copy the provided path to new server"
	echo "(path has to be a local one like /var/www/ to the root of a website)"
	echo "Important: remote servers ssh has to be on port 22"
	# check for some vars
	if [ -z "${DIR}" ]; then
		echo "your have to provide a path like '--dir /var/www', otherwise we can't copy anything"
		exit 1;
	elif [ ! -d "${DIR}" ]; then
		echo "your provided path is not valid"
		exit 1
	fi 
	if [ -z "${DOMAIN}" ]; then
		echo "you also have to provide the domain for the new vhost (--domain)"
		exit 1
	fi
	if [ -z "${NEWHOME}" ]; then
		echo "you have to provide the new root path for the website (-n/--newhome)"
	fi
	#if [ -z "${OWNER}" ]; then
		#echo "you have to provide '--owner test', this will be the owner of the website on the new server"
		#exit 1
	#fi
	# check for ssh key, if none then create one
	if [ ! -f "~/.ssh/id_rsa.pub" ]; then
		ssh-keygen -b 8192 -N "" -f /root/.ssh/id_rsa -t rsa
	fi

	##
	# the following part has to be more beautiful, we have to handle exit codes
	##

	# copy ssh key
	ssh-copy-id -i ~/.ssh/id_rsa.pub ${REMOTE}
	# create remote user
	ssh "${REMOTE}" '/root/scripts/setup_domain.sh --add-user "${DOMAIN}" "${NEWHOME}"'
	# create directories
	ssh "${REMOTE}" '/root/scripts/setup_domain.sh --create-directories "${DOMAIN}" "${NEWHOME}"'
	# create apache vhost, this also triggers setup_php
	ssh "${REMOTE}" '/root/scripts/setup_domain.sh --setup-vhost "${DOMAIN}" "${NEWHOME}"'
	# start the rsync
	rsync -a --stats "${DIR}" -e 'ssh -i /root/.ssh/id_rsa root@${REMOTE}' 
fi
