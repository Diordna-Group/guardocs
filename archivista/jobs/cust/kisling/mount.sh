#!/bin/bash

cd /home/data/archivista/kis

# PATH and co
. /etc/profile

# include shared code
. ${0%/*}/net-backup.in

# shared function, included on top
mount_net /mnt/net

