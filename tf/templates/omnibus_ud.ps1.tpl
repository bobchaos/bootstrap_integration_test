<powershell>
# Some functions
# A method for extracting zip files that should work on older powershell
# I probably should have just put more effort into tar support at this point :P
# The rakefile would look a lot less insane too
Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip
{
    param([string]$zipfile, [string]$outpath)

    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}

# redirect all output to file
$ErrorActionPreference="SilentlyContinue"
Stop-Transcript | out-null
$ErrorActionPreference = "Stop"
Start-Transcript -path C:\cloud-init-log.txt -append

# A working dir
$workdir = "C:\cloud-init-workdir"
New-Item $workdir -itemtype directory -Force
Set-Location -Path $workdir

# Check that we have connectivity.
Write-Host "Checking for network connectivity"
$retry_count = 0
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
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))

# Make Choco available. Solution based on https://stackoverflow.com/questions/46758437/how-to-refresh-the-environment-of-a-powershell-session-after-a-chocolatey-instal
$env:ChocolateyInstall = Convert-Path "$((Get-Command choco).Path)\..\.."
Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"

choco install awscli -y
choco install git -y

# Get angrychef from omnitruck
. { iwr -useb https://omnitruck.chef.io/install.ps1 } | iex; install -project angrychef

refreshenv

# Get the zero package from S3
aws s3 cp s3://${bucket_name}/${zero_package} .
Unzip "$workdir\${zero_package}" "$workdir"

# Clone the repo to build
git clone --depth 1 -b ${chef_repo_branch} ${chef_repo_url} C:\\chef_source

# Run the package with angrychef, since it's building chef
$env:CHEF_LICENSE="accept-no-persist"
chef-client -z

# Get the server cert
knife ssl fetch --server_url https://${chef_server_dns}/organizations/fake

# Set the Windows Admin password since we can't pass it from tf outputs to inspec in kitchen-tf (yet)
([adsi]"WinNT://$env:ComputerName/Administrator").SetPassword('${win_omnibus_override_pw}')

echo $null > $workdir\boot-finished

Stop-Transcript
</powershell>
