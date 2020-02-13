#
# Cookbook:: bob_omnibus
# Recipe:: default
#
# Copyright:: 2019, The Authors, All Rights Reserved.
include_recipe 'omnibus'

package 'git'

git "#{node['omnibus']['build_user_home']}/chef" do
  repository node['chef_omnibus']['chef_repo_address']
  depth 1
  revision node['chef_omnibus']['branch']
  user node['omnibus']['build_user']
end

execute 'fix bundler directory permissions' do
  command "chown -R #{node['omnibus']['build_user']} #{node['omnibus']['build_user_home']}/.bundle"
  only_if { Dir.exist? "#{node['omnibus']['build_user_home']}/.bundle" }
end

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
