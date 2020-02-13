#!/bin/bash -e
# Creates a user and grants him passwordless sudo privis
# This is done to allow inspec to connect reliably to all *nix systems
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>/var/log/add_sudo_user.sh.out 2>&1

useradd bootstraper -d /home/bootstraper --create-home --shell /bin/bash
mkdir -p /home/bootstraper/.ssh
echo '${public_key}' > /home/bootstraper/.ssh/authorized_keys
chown -R bootstraper:bootstraper /home/bootstraper/.ssh
chmod 0700 /home/bootstraper/.ssh
chmod 0600 /home/bootstraper/.ssh/authorized_keys
echo "bootstraper ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
echo "Defaults:bootstraper !requiretty" >> /etc/sudoers
echo "Defaults:bootstraper lecture=\"never\"" >> /etc/sudoers
