# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-
# stub: corl 0.5.17 ruby lib

Gem::Specification.new do |s|
  s.name = "corl"
  s.version = "0.5.17"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Adrian Webb"]
  s.date = "2015-04-25"
  s.description = "Framework that provides a simple foundation for growing organically in the cloud"
  s.email = "adrian.webb@coralnexus.com"
  s.executables = ["corl"]
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.rdoc"
  ]
  s.files = [
    ".gitignore",
    ".gitmodules",
    "Gemfile",
    "Gemfile.lock",
    "LICENSE.txt",
    "README.rdoc",
    "Rakefile",
    "VERSION",
    "bin/corl",
    "bootstrap/bootstrap.sh",
    "bootstrap/lib/shell/LICENSE.txt",
    "bootstrap/lib/shell/command.sh",
    "bootstrap/lib/shell/filesystem.sh",
    "bootstrap/lib/shell/load.sh",
    "bootstrap/lib/shell/os.sh",
    "bootstrap/lib/shell/script.sh",
    "bootstrap/lib/shell/starter.sh",
    "bootstrap/lib/shell/validators.sh",
    "bootstrap/os/ubuntu/00_base.sh",
    "bootstrap/os/ubuntu/01_git.sh",
    "bootstrap/os/ubuntu/02_editor.sh",
    "bootstrap/os/ubuntu/05_ruby.sh",
    "bootstrap/os/ubuntu/06_puppet.sh",
    "bootstrap/os/ubuntu/09_nucleon.sh",
    "bootstrap/os/ubuntu/10_corl.sh",
    "corl.gemspec",
    "info/AUTOMATION.rdoc",
    "info/INSTALLATION.rdoc",
    "info/PACKAGING.rdoc",
    "info/PLUGINS.rdoc",
    "info/TODO.rdoc",
    "lib/CORL/builder/identity.rb",
    "lib/CORL/builder/package.rb",
    "lib/CORL/builder/project.rb",
    "lib/CORL/configuration/file.rb",
    "lib/CORL/machine/AWS.rb",
    "lib/CORL/machine/physical.rb",
    "lib/CORL/machine/rackspace.rb",
    "lib/CORL/machine/raspberrypi.rb",
    "lib/CORL/machine/vagrant.rb",
    "lib/CORL/network/CORL.rb",
    "lib/CORL/node/AWS.rb",
    "lib/CORL/node/local.rb",
    "lib/CORL/node/rackspace.rb",
    "lib/CORL/node/raspberrypi.rb",
    "lib/CORL/node/vagrant.rb",
    "lib/CORL/provisioner/puppetnode.rb",
    "lib/core/build.rb",
    "lib/core/errors.rb",
    "lib/core/facade.rb",
    "lib/core/mixin/action/keypair.rb",
    "lib/core/mixin/action/registration.rb",
    "lib/core/mixin/builder.rb",
    "lib/core/mixin/lookup.rb",
    "lib/core/mixin/machine/ssh.rb",
    "lib/core/mixin/macro/network_settings.rb",
    "lib/core/mod/fog_aws_server.rb",
    "lib/core/mod/fog_rackspace_server.rb",
    "lib/core/mod/hiera_backend.rb",
    "lib/core/plugin/agent.rb",
    "lib/core/plugin/agent_wrapper.rb",
    "lib/core/plugin/builder.rb",
    "lib/core/plugin/cloud_action.rb",
    "lib/core/plugin/cloud_action_wrapper.rb",
    "lib/core/plugin/configuration.rb",
    "lib/core/plugin/fog_machine.rb",
    "lib/core/plugin/fog_node.rb",
    "lib/core/plugin/machine.rb",
    "lib/core/plugin/network.rb",
    "lib/core/plugin/node.rb",
    "lib/core/plugin/provisioner.rb",
    "lib/core/util/puppet.rb",
    "lib/core/util/puppet/resource.rb",
    "lib/core/util/puppet/resource_group.rb",
    "lib/core/vagrant/action.rb",
    "lib/core/vagrant/actions/delete_cache.rb",
    "lib/core/vagrant/actions/init_keys.rb",
    "lib/core/vagrant/actions/link_network.rb",
    "lib/core/vagrant/commands/launcher.rb",
    "lib/core/vagrant/config.rb",
    "lib/core/vagrant/plugins.rb",
    "lib/core/vagrant/provisioner/config.rb",
    "lib/core/vagrant/provisioner/provisioner.rb",
    "lib/corl.rb",
    "lib/facter/corl_build.rb",
    "lib/facter/corl_config_ready.rb",
    "lib/facter/corl_network.rb",
    "lib/facter/custom_facts.rb",
    "lib/facter/vagrant_exists.rb",
    "lib/hiera/corl_logger.rb",
    "lib/nucleon/action/agent/manager.rb",
    "lib/nucleon/action/network/config.rb",
    "lib/nucleon/action/network/create.rb",
    "lib/nucleon/action/network/images.rb",
    "lib/nucleon/action/network/inspect.rb",
    "lib/nucleon/action/network/machines.rb",
    "lib/nucleon/action/network/regions.rb",
    "lib/nucleon/action/network/remote.rb",
    "lib/nucleon/action/network/settings.rb",
    "lib/nucleon/action/network/vagrantfile.rb",
    "lib/nucleon/action/node/IP.rb",
    "lib/nucleon/action/node/SSH.rb",
    "lib/nucleon/action/node/agent/status.rb",
    "lib/nucleon/action/node/agent/stop.rb",
    "lib/nucleon/action/node/agents.rb",
    "lib/nucleon/action/node/authorize.rb",
    "lib/nucleon/action/node/bootstrap.rb",
    "lib/nucleon/action/node/build.rb",
    "lib/nucleon/action/node/cache.rb",
    "lib/nucleon/action/node/destroy.rb",
    "lib/nucleon/action/node/download.rb",
    "lib/nucleon/action/node/exec.rb",
    "lib/nucleon/action/node/fact.rb",
    "lib/nucleon/action/node/facts.rb",
    "lib/nucleon/action/node/group.rb",
    "lib/nucleon/action/node/groups.rb",
    "lib/nucleon/action/node/identity.rb",
    "lib/nucleon/action/node/image.rb",
    "lib/nucleon/action/node/keypair.rb",
    "lib/nucleon/action/node/lookup.rb",
    "lib/nucleon/action/node/provision.rb",
    "lib/nucleon/action/node/reboot.rb",
    "lib/nucleon/action/node/revoke.rb",
    "lib/nucleon/action/node/seed.rb",
    "lib/nucleon/action/node/spawn.rb",
    "lib/nucleon/action/node/start.rb",
    "lib/nucleon/action/node/status.rb",
    "lib/nucleon/action/node/stop.rb",
    "lib/nucleon/action/node/upload.rb",
    "lib/nucleon/action/plugin/create.rb",
    "lib/nucleon/action/plugin/list.rb",
    "lib/nucleon/action/plugins.rb",
    "lib/nucleon/event/puppet.rb",
    "lib/nucleon/extension/corl_config.rb",
    "lib/nucleon/extension/corl_executable.rb",
    "lib/nucleon/extension/vagrant.rb",
    "lib/nucleon/template/environment.rb",
    "lib/puppet/indirector/corl.rb",
    "lib/puppet/indirector/data_binding/corl.rb",
    "lib/puppet/parser/functions/corl_include.rb",
    "lib/puppet/parser/functions/corl_initialize.rb",
    "lib/puppet/parser/functions/corl_merge.rb",
    "lib/puppet/parser/functions/corl_resources.rb",
    "lib/puppet/parser/functions/ensure.rb",
    "lib/puppet/parser/functions/file_exists.rb",
    "lib/puppet/parser/functions/global_array.rb",
    "lib/puppet/parser/functions/global_hash.rb",
    "lib/puppet/parser/functions/global_options.rb",
    "lib/puppet/parser/functions/global_param.rb",
    "lib/puppet/parser/functions/interpolate.rb",
    "lib/puppet/parser/functions/is_false.rb",
    "lib/puppet/parser/functions/is_true.rb",
    "lib/puppet/parser/functions/module_array.rb",
    "lib/puppet/parser/functions/module_hash.rb",
    "lib/puppet/parser/functions/module_options.rb",
    "lib/puppet/parser/functions/module_param.rb",
    "lib/puppet/parser/functions/name.rb",
    "lib/puppet/parser/functions/render.rb",
    "lib/puppet/parser/functions/value.rb",
    "locales/en.yml",
    "spec/spec_helper.rb"
  ]
  s.homepage = "http://github.com/coralnexus/corl"
  s.licenses = ["Apache License, Version 2.0"]
  s.rdoc_options = ["--title", "Coral Orchestration and Research Library", "--main", "README.rdoc", "--line-numbers"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.1")
  s.rubyforge_project = "corl"
  s.rubygems_version = "2.4.5"
  s.summary = "Coral Orchestration and Research Library"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<nucleon>, [">= 0.2.2", "~> 0.2"])
      s.add_runtime_dependency(%q<net-ping>, ["~> 1.7"])
      s.add_runtime_dependency(%q<fog>, ["~> 1.23"])
      s.add_runtime_dependency(%q<unf>, ["~> 0.1"])
      s.add_runtime_dependency(%q<facter>, ["~> 2.3"])
      s.add_runtime_dependency(%q<hiera>, ["~> 1.3"])
      s.add_runtime_dependency(%q<puppet>, ["~> 3.7"])
      s.add_development_dependency(%q<bundler>, ["~> 1.7"])
      s.add_development_dependency(%q<jeweler>, ["~> 2.0"])
      s.add_development_dependency(%q<rspec>, ["~> 3.1"])
      s.add_development_dependency(%q<rdoc>, ["~> 3.12"])
      s.add_development_dependency(%q<github-markup>, ["~> 1.3"])
    else
      s.add_dependency(%q<nucleon>, [">= 0.2.2", "~> 0.2"])
      s.add_dependency(%q<net-ping>, ["~> 1.7"])
      s.add_dependency(%q<fog>, ["~> 1.23"])
      s.add_dependency(%q<unf>, ["~> 0.1"])
      s.add_dependency(%q<facter>, ["~> 2.3"])
      s.add_dependency(%q<hiera>, ["~> 1.3"])
      s.add_dependency(%q<puppet>, ["~> 3.7"])
      s.add_dependency(%q<bundler>, ["~> 1.7"])
      s.add_dependency(%q<jeweler>, ["~> 2.0"])
      s.add_dependency(%q<rspec>, ["~> 3.1"])
      s.add_dependency(%q<rdoc>, ["~> 3.12"])
      s.add_dependency(%q<github-markup>, ["~> 1.3"])
    end
  else
    s.add_dependency(%q<nucleon>, [">= 0.2.2", "~> 0.2"])
    s.add_dependency(%q<net-ping>, ["~> 1.7"])
    s.add_dependency(%q<fog>, ["~> 1.23"])
    s.add_dependency(%q<unf>, ["~> 0.1"])
    s.add_dependency(%q<facter>, ["~> 2.3"])
    s.add_dependency(%q<hiera>, ["~> 1.3"])
    s.add_dependency(%q<puppet>, ["~> 3.7"])
    s.add_dependency(%q<bundler>, ["~> 1.7"])
    s.add_dependency(%q<jeweler>, ["~> 2.0"])
    s.add_dependency(%q<rspec>, ["~> 3.1"])
    s.add_dependency(%q<rdoc>, ["~> 3.12"])
    s.add_dependency(%q<github-markup>, ["~> 1.3"])
  end
end

