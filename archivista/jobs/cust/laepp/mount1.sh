#!/bin/bash

# PATH and co
. /etc/profile

# include shared code
. ${0%/*}/net-backup1.in
. ${0%/*}/backup.in

# shared function, included on top
mount_net /home/data/archivista/cust/laepp/cold

