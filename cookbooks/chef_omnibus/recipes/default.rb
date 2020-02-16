#
# Cookbook:: bob_omnibus
# Recipe:: default
#
# Copyright:: 2019, The Authors, All Rights Reserved.
include_recipe 'omnibus'

omnibus_build 'chef' do
  environment 'HOME' => node['omnibus']['build_user_home']
  project_dir node['omnibus']['build_dir']
  log_level :info
  config_overrides(
    append_timestamp: true
  )
  build_user node['omnibus']['build_user']
end

sudo 'centos' do
  defaults ['!requiretty', 'lecture="never"']
  nopasswd true
  user 'centos'
end
