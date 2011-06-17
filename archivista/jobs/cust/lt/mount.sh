#!/bin/bash

type="cifs"
mpoint="/mnt/net"
server="192.168.0.98"
share="firma"
user="up"
passwd="***"

mkdir -p $mpoint

if [ "$type" = cifs ]; then
	# construct options variable
	append () {
		# inject , on demand
		options="$options${options:+,}$1"
	}
	[ "$user" ] && append "user=$user"
	[ "$passwd" ] && append "passwd=$passwd"
	[ "$domain" ] && append "domain=$domain"
	[ "$options" ] && options="-o $options"

	# make sure the share starts with a /, but does not end with one
	share="/${share#/}"
	share="${share%/}"

	mount -t $type //$server$share $mpoint $options
else
	# we need portmap running, otherwise NFS get's hickups
	rc portmap start > /dev/null
	mount -t $type $server:$share $mpoint
fi
error=$?
if [ $error -ne 0 ]; then
	echo "Error mouting network share: $error."
	return 1
fi

# stop portmap here - maybe we should later check if we needed to enable
# it ...
[ $type = nfs ] && rc portmap stop > /dev/null

if ! grep -q $mpoint /proc/mounts; then
	echo "Network share does not appear to be mounted correctly."
fi





