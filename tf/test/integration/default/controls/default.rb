# Default controls for bob's infra experiments

# Notes on absent resources: Some resources are tested upstream, while others are tested
# implicitely by others; For example, the main VPC module is tested upstream, and retesting
# it here would provide little to no value.

control 'default' do
  desc 'Test bootstrap operations'

  attribute('nix_nodes').each do |node_ip|
    # I don't know why this second loop is required, but it is :/
    node_ip.each do |ip|
      describe command("CHEF_LICENSE=\"accept\" knife bootstrap --server_url https://#{attribute('server_private_dns')}/organizations/fake -U bootstraper -i /tmp/ephemeral.pem --sudo -u fakedyfake --ssh-verify-host-key never -k /tmp/chef_admin.pem -N node_#{ip} #{ip}") do
        its('exit_status') { should eq 0 }
      end
    end
  end
end
