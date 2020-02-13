#!/bin/bash -e
# redirect all output to file
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>/var/log/init.sh.out 2>&1

# Prerequisites for other scripts
# Check that we have connectivity.
echo -e "Checking for network connectivty\n"
until ping 8.8.8.8 -c 1
do
  sleep 5
done

echo -e "Network connectivity established\n"

# Run updates. Someday I'll setup a spacewalk or something
yum update -y

# Get AWS CLI. V2 is beta, but also 100% self-contained, making it 1000% less of a hassle
curl "https://d1vvhvl2y92vvt.cloudfront.net/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

# Extract and install aws2 + jq to parse it's output
yum install -y unzip jq
unzip awscliv2.zip
./aws/install
rm -f awscliv2.zip
