#!/bin/bash -e
# redirect all output to file
$ErrorActionPreference="SilentlyContinue"
Stop-Transcript | out-null
$ErrorActionPreference = "Continue"
Start-Transcript -path C:\cloud-init-log.txt -append

# A working dir
$workdir = "C:\cloud-init-workdir"
New-Item $workdir -itemtype directory -Force
Set-Location -Path $workdir

# Check that we have connectivity.
Write-Host "Checking for network connectivity"
retry_count = 60
do {
  Write-Host "waiting for network..."
  $retry_count ++
  sleep 5
} until((Test-NetConnection -ComputerName "www.google.com" | ? { $_.PingSucceeded } ) -or ($retry_count -eq 60))

if($retry_count -gt 35){
  Write-Error "Network still unreachable after 5 mins, aborting"
  exit 1
}

Write-Host "Network connectivity established"

# Enable WinRM; TF provisioners will need it
Enable-PSRemoting -SkipNetworkProfileCheck -Force
Set-NetFirewallRule -Name 'WINRM-HTTP-In-TCP-PUBLIC' -RemoteAddress Any

# Get choco, cuz who wants to mess around with MSIs? :P
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Get AWS CLI. V2 is beta, but also 100% self-contained, making it 1000% less of a hassle
#$awscliv2_url = "https://awscli.amazonaws.com/AWSCLIV2.msi"
#$output_msi = "C:\$workdir\AWSCLIV2.msi
#(New-Object System.Net.WebClient).DownloadFile($awscliv2_url, $output_msi)

# Install AWSCLIV2 and reload profile
#msiexec /i /qn /l*v "$workdir\awscliv2_install_log.txt"

choco install awscli
choco install git

# Get angrychef from omnitruck
. { iwr -useb https://omnitruck.chef.io/install.ps1 } | iex; install -project angrychef

. $profile

# Get the zero package from S3
aws s3 cp s3://${bucket_name}/${zero_package} .
Expand-Archive -LiteralPath "$workdir\${zero_package}" -DestinationPath $workdir

# Run the package with angrychef, since it's building chef
$env:CHEF_LICENSE="accept-no-persist"
chef-client -z

# Get the server cert
knife ssl fetch --server_url https://${chef_server_dns}/organizations/fake

# Set the Windows Admin password since we can't pass it from tf outputs to inspec in kitchen-tf (yet)
$UserAccount = Get-LocalUser -Name "Administrator"
$UserAccount | Set-LocalUser -Password '${win_omnibus_override_pw}'

# Clone the repo to build
git clone --depth 1 -b ${chef_repo_branch} ${chef_repo_url} C:\\chef_source

echo $null > $workdir\boot-finished

Stop-Transcript
