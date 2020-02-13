#!/bin/bash -e
# Setup a quick and dirty Chef Server to test bootstraps and whatnot
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>/var/log/setup_chef_server.sh.out 2>&1

# Check that we have connectivity.
echo -e "Checking for network connectivty\n"
until ping 8.8.8.8 -c 1
do
  sleep 5
done
echo -e "Network connectivity established\n"

# Run updates. Someday I'll setup a spacewalk or something
yum update -y

# curl -L https://packages.chef.io/files/stable/chef-server/13.1.13/el/7/chef-server-core-13.1.13-1.el7.x86_64.rpm -o /tmp/chef-server-core-13.1.13-1.el7.x86_64.rpm
export CHEF_LICENSE=accept-no-persist
# yum install -y /tmp/chef-server-core-13.1.13-1.el7.x86_64.rpm
# mkdir -p /etc/opscode
#TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"` \
#&& export IP=`curl -H "X-aws-ec2-metadata-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/local-ipv4`
#echo "api_fqdn = \"$IP\"" > /etc/opscode/chef-server.rb

curl -L https://omnitruck.chef.io/install.sh | sudo bash -s -- -P chef-server

chef-server-ctl reconfigure
chef-server-ctl user-create fakedyfake Fakedy Fake fakedy@fake.tld 'FakeFake!'
chef-server-ctl org-create fake "Fakedy Fake" -a fakedyfake
chef-server-ctl add-user-key fakedyfake -p /tmp/chef_admin.pub
