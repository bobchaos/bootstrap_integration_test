control 'win_bootstrap_win_nodes' do
  desc 'Test bootstrap operations on win nodes'

  attribute('win_nodes').each do |ip, password|
    describe command("Command ; if($?) {$env:CHEF_LICENSE = \"accept\" knife bootstrap --server_url https://#{attribute('server_private_dns')}/organizations/fake -o winrm -U Administrator -P '#{password}' -u fakedyfake -k /tmp/chef_admin.pem -N node_#{ip}_from_win #{ip}}") do
      its('exit_status') { should eq 0 }
    end
  end
end
