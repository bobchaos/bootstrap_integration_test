require 'rake'
require 'rake/packagetask'
require 'chef-cli/policyfile_services/export_repo'
require 'chef-cli/policyfile_services/install'
require 'chef-cli/ui'
require 'ffi_yajl'
require 'zip'

policyfile_path = "#{__dir__}/cookbooks/chef_omnibus/Policyfile.rb"
policy_lockfile_path = "#{__dir__}/cookbooks/chef_omnibus/Policyfile.lock.json"
exported_policy_dir = "#{__dir__}/exported_policy"
tf_policy_artifacts = "#{__dir__}/tf/policy_artifacts"

# Export the policyfile of the omnibus cookbook and zip the results
# Older versions of Windows don't support tar (without shenanigans)
task :package_policy => %w(policy_update zip_policy)

# Remove all traces of the previous policy install/export
task :clean_policy do
  FileUtils.rm_f(policy_lockfile_path)
  FileUtils.rm_rf(exported_policy_dir)
  FileUtils.rm_rf(Dir.glob("#{tf_policy_artifacts}/*.zip"))
end

task :install_policy do
  install_zero_package = ChefCLI::PolicyfileServices::Install.new(
    policyfile: policyfile_path,
    ui: ChefCLI::UI.new
  )
  install_zero_package.run
end

task :policy_update => %w(clean_policy install_policy) do
  FileUtils.mkdir_p(exported_policy_dir)
  export_zero_package = ChefCLI::PolicyfileServices::ExportRepo.new(
    policyfile: policyfile_path,
    export_dir: exported_policy_dir,
    root_dir: __dir__,
    archive: false,
    force: true
  )
  export_zero_package.run
end

task :zip_policy do
  # Zip exported policy, then update it's value in auto.tfvars
  policy_data = FFI_Yajl::Parser.parse(IO.read(policy_lockfile_path))
  package_name = "#{tf_policy_artifacts}/#{policy_data["name"]}-#{policy_data["revision_id"]}.zip"

  Dir.chdir(exported_policy_dir) do
    zip_contents =  FileList["**"]
    Zip::File.open(package_name, Zip::File::CREATE) do |zipfile|
      zip_contents.each do |f|
        zipfile.add(f, f)
      end
    end
  end
  tfvars_path = 'tf/auto.tfvars'
  contents = File.read(tfvars_path)
  new_contents = contents.gsub(%r(omnibus_zero_package = .*), "omnibus_zero_package = \"#{package_name}\"")

  File.open(tfvars_path, "w") {|file| file.puts new_contents }
end
