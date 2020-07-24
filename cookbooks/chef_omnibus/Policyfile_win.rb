# Policyfile.rb - Describe how you want Chef Infra Client to build your system.
#
# For more information on the Policyfile feature, visit
# https://docs.chef.io/policyfile.html

# A name that describes what the system you're building with Chef does.
name 'chef_omnibus_builder'

# Where to find external cookbooks:
default_source :supermarket

# run_list: chef-client will run these recipes in the order specified.
run_list 'chef_omnibus::default'

# Specify a custom source for a single cookbook:
cookbook 'chef_omnibus', path: '.'
cookbook 'omnibus', '~> 5.7.2'
cookbook 'build-essential'
cookbook 'winrm', '~> 3.0.1'

default['chef_omnibus']['chef_repo_address'] = 'https://gitlab.com/cinc-project/chef.git'
default['chef_omnibus']['branch'] = 'dist_bootstrap'
default['omnibus']['build_dir'] = 'C:\\chef_source\\omnibus'
default['omnibus']['build_user_home'] = 'C:\\'
default['omnibus']['build_user'] = 'Administrator'
