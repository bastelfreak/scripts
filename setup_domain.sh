#!/bin/bash

##
# written by Tim Meusel, 07.09.2013
# this script has to be placed on a webserver to add new vhosts and dns records
# you can place a copy of this script on two servers and migrate websites from one host to another
##

function setup_php {
	touch /etc/php5/fpm/pool.d/"${DOMAIN}"
}

function add_domain {
	# adds the domain to the powerdns db
	true
}

function create_user {
	# create password and echo it
	local PW=$(openssl rand -hex 16)
	local HASH=$(openssl passwd -crypt ${PW})
	local HOME="/home/${DOMAIN}"
	echo "the new password is ${PW}"
	unset PW
	# create user, set pw, disable shell, create home and group
	useradd --shell /bin/false --create-home --home=${HOME} --user-group --password ${HASH} ${DOMAIN}
	unset HASH

}

function create_directories {
	# $1 is something lile /home/google.de
	#	 TODO: set correct permissions (or at least set any permissions)
	local PATH="$1"
	mkdir -p "${PATH}/htdocs"
	mkdir -p "${PATH}/logs"
	mkdir -p "${PATH}/config"
	mkdir -p "${PATH}/tmp"
	unset PATH
}

function add_apache_vhost {
	# $1 is something like google.de // a complete domain without www
	local DOMAIN="${1}"
cat >> "/etc/apache2/sites-available/${DOMAIN}" <<END
<VirtualHost *:80>
	DocumentRoot /home/www/de/root
	ServerName www.${DOMAIN}.de
  ServerAdmin admin@${DOMAIN}
	<Directory /home/${DOMAIN}/htdocs>
		Options -Indexes
    Order allow,deny
    allow from all
    AllowOverride All
	</Directory>
	ErrorLog /home/${DOMAIN}/error.log
  LogLevel warn
  CustomLog /home/${DOMAIN}/logs/access.log combined
</VirtualHost>
END
	a2ensite "${DOMAIN}"
	unset DOMAIN
}

function add_lighttpd_vhost {
	# this is for later usage, because someday.... we want to have apache and lighty working in awesome coexistence
	true
}

function output_help {
	echo "written by Tim 'bastelfreak' Meusel <tim@online-mail.biz>"
	echo "you are using my awesome script, thanks :)"
	echo "Usage is easy:"
	echo "-h/--help ## prints this help"
	echo "-r/--remote new-server.de ## script will copy a website to this server, also needs --dir"
	echo ""
}

## check here for every parameter
while getopts "h:help:?:r:remote:dir:domain:webserver:owner" opt; do
	case ${opt} in
		h|help|?) output_help; exit 0;;
		r|remote) REMOTE="${OPTARG}";;
		dir) DIR="${OPTARG}";;
		domain) DOMAIN="${OPTARG}";;
		webserver) WEBSERVER="${OPTARG}";; # thats currently not supported, you have to use apache
		owner) OWNER="${OPTARG}";;
		# define function calls
		add-user) [ -z "${REMOTE}" ] && create_user "${OPTARG}" || exit 0;;
		setup_vhost) [ -z "${REMOTE}" ] && add_apache_vhost "${OPTARG}" || exit 0;;
		create-directories) [ -z "${REMOTE}" ] && create_directories "${OPTARG}" || exit 0;;
	esac
done
	
# check if we have to move a website to a new server
if [ ! -z "${REMOTE}" ]; then
	# output some help
	echo "what we do now:"
	echo "check for local ssh key, create one if necessary and copy it to the new server"
	echo "copy the provided path to new server"
	echo "(path has to be a local one like /var/ww/ to the root of a website)"
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
		echo "you also have to provide the domain for the new vhost"
		exit 1
	fi
	if [ -z "${OWNER}" ]; then
		echo "you have to provide '--owner test', this will be the owner of the website on the new server"
		exit 1
	fi
	# check for ssh key, if none then create one
	if [ ! -f "~/.ssh/id_rsa.pub" ]; then
		ssh-keygen -b 8192 -N "" -f ~/.ssh/id_rsa -t rsa
	fi
	# copy ssh key
	ssh-copy-id -i ~/.ssh/id_rsa.pub ${REMOTE}
	# create remote user
	ssh ${REMOTE} '/root/scripts/setup_domain.sh --add-user "${OWNER}"'
	# create directories
	ssh ${REMOTE} '/root/scripts/setup_domain.sh --create-directories "${OWNER}"'
fi
