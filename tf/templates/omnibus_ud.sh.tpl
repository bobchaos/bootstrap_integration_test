#!/bin/bash -e
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>/var/log/zero_package.sh.out 2>&1

mkdir -p /tmp/zero_package
cd /tmp/zero_package

# Get angrychef from omnitruck
curl -L https://omnitruck.chef.io/install.sh | sudo bash -s -- -P angrychef

# Get the zero package from S3
/usr/local/bin/aws s3 cp s3://${bucket_name}/${zero_package} .
tar -xf ./${zero_package}

# Run the package with angrychef, since it's building chef
CHEF_LICENSE="accept-no-persist" /opt/angrychef/bin/chef-client -z

# Get the server cert
/opt/chef/bin/knife ssl fetch --server_url https://${chef_server_dns}/organizations/fake

# Fetched certificates get installed under /tmp/zero_package/.chef/trusted_cert and there's 
# no way to tell knife to put it elsewhere, so we just move and chown it
mkdir -p /home/centos/.chef/
mv /tmp/zero_package/.chef/trusted_certs /home/centos/.chef/
chown -R centos:centos /home/centos/.chef
