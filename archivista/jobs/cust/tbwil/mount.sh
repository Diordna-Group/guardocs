#!/bin/bash

# PATH and co
. /etc/profile

# Xdialog and friends
export DISPLAY=:0

# include shared code
. ${0%/*}/net-backup.in
. ${0%/*}/backup.in

mount_net /home/data/archivista/cust/tbwil/net

