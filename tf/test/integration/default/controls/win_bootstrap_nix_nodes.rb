# Default controls for bootstrap tests

control 'win_bootstrap_nix_nodes' do
  desc 'Test bootstrap operations on nix nodes'

  attribute('nix_nodes').each do |node_ip|
    # I don't know why this second loop is required, but it is :/
    node_ip.each do |ip|
      describe command("CHEF_LICENSE=\"accept\" knife bootstrap --server_url https://#{attribute('server_private_dns')}/organizations/fake -U bootstraper -i /tmp/ephemeral.pem --sudo -u fakedyfake --ssh-verify-host-key never -k /tmp/chef_admin.pem -N node_#{ip}_from_win #{ip}") do
        its('exit_status') { should eq 0 }
      end
    end
  end
end
