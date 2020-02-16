# InSpec test for recipe bob_omnibus::default

# The InSpec reference, with examples and extensive documentation, can be
# found at https://www.inspec.io/docs/reference/resources/

# Explicitely call /opt/chef/bin to avoid false positives from angrychef
describe command('/opt/chef/bin/chef-client -v') do
  its('exit_status') { should eq 0 }
end
