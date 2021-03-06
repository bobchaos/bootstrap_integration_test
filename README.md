# Chef Infra integration testing

This repo contains everything needed to create an ephemeral environment on AWS containing a Chef Infra Server, an omnibus builder, and multiple sample nodes. All of this is secured in a VPC, and the only way in is a dedicated bastion instance.

It should be treated as a prototype at this time.

## Usage

Before you begin, ensure you have configured ~/.aws/credentials with an IAM user with R/W prvileges over EC2, IAM, STS:AssumeRole, Route53 and S3.

All the following instructions are assumed to use the repo's root as starting CWD.

Everything is wrapped by test kitchen. To get it and other dependencies:

```ruby
cd tf
bundle install
```

Next, we need to create `./tf/priv.tfvars` with your `r53_zone_id`. You can also set `omnibus_policy_artifact` if you want to run your own omnibus builder cookbook, or even s cookbook that substitutes the build with pulling and installing a pre-built artifact.

If need be, you can also set your `chef_repo_url` and `chef_repo_branch` in `./tf/priv.tfvars` to build from your desired ref.

Finally, in a kitchen.local.yml, override the bastion's domain to match your `r53_zone_id`. That value sadly cannot be imported from TF State by kitchen-tf, so we generate a predictable record for it.

With this one-time setup complete, you can then run:

```shell
cd ./tf
bundle exec kitchen test
```

## Adding new test nodes

The nodes are generated by looping over `local.nix_ami_ids` and `local.win_ami_ids`, so in theory it's as simple as adding new AMIs for new systems.

In practice, you're likely to have to setup a `data.aws_ami` TF resource to locate fresh AMIs for each new OS, and while the nodes' user\_data is restricted to creating a user/opening WinRM this is accomplished by scripts that may prove to be less-than-universal.

## Adding new omnibus nodes

The omnibus nodes are managed by (angry)chef and therefor should function pretty universally on new OSes. The script setting up angrychef and fetching the zero package may require adjustements for other *nix systems. There is currently no powershell equivalent to that script.

## Known issues, caveats, TODOs, etc...

As of this writting it only spawns 2 sample Linux nodes, and a single Windows node.

Similarly, we only build Chef Infra Client on CentOS, having additional omnibus builders on other OS could have value.

The current code is very inflexible, but making more parameters into variables can address a lot of that.

The chef-server and chef_omnibus nodes rely heavily on inflexible bash scripts fed to cloud-init. Borrowing some tricks from Chef's bash scripts could help (like the do_download function and it's "childs" in mixlib-install's install.sh).

Adding new test nodes requires lots of nasty copy/pasting, a better system could be designed using TF12's new features, or simply by managing the AMI list externally or manually.

It was designed to test bootstraps, but could easily be extended to include other operations in live, ephemeral environments. Server-client interactions come to mind.
