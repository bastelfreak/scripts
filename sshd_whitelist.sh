 #!/bin/bash

# this comes from the great bluewind
case "$SSH_ORIGINAL_COMMAND" in
	*\&*) echo "Rejected" ;;
	*\(*) echo "Rejected" ;;
	*\{*) echo "Rejected" ;;
	*\;*) echo "Rejected" ;;
	*\<*) echo "Rejected" ;;
	*\>*) echo "Rejected" ;;
	*\`*) echo "Rejected" ;;
	*\|*) echo "Rejected" ;;
	rsync\ --server*) exec /usr/lib/rsync/rrsync -ro /;;
	/root/create-dovecot-backup.sh) exec $SSH_ORIGINAL_COMMAND;;
	*) echo "Rejected";;
esac
