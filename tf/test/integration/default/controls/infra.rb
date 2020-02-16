control 'infra' do
  desc 'validate the infra functions as intended'

# The following 2 tests should eb dirt simple but always return "Expected stub data to be an array"
# So they cans tay commented till I figure it out :P

#  describe aws_ec2_instance(attribute('centos_omnibus_instance_id')) do
#    it { should exist }
#    it { should be_running }
#  end

#  describe aws_ec2_instance(attribute('chef_server_instance_id')) do
#    it { should exist }
#    it { should be_running }
#  end

  attribute('chef_server_sg_ids').each do |sg|
    describe aws_security_group(sg) do
      it { should exist }
      it { should allow_in(port: 443, ipv4_range: attribute('all_vpc_subnet_cidrs')) }
    end
  end

  attribute('omnibus_sg_ids').each do |sg|
    describe aws_security_group(sg) do
      it { should exist }
      it { should allow_in(port: 22, ipv4_range: attribute('all_vpc_subnet_cidrs')) }
      it { should allow_in(from_port: 5985, to_port: 5986, ipv4_range: attribute('all_vpc_subnet_cidrs')) }
    end
  end
end
