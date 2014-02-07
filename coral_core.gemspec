# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "coral_core"
  s.version = "0.2.31"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Adrian Webb"]
  s.date = "2014-02-07"
  s.description = "= coral_core\n\nThis library provides core data elements and utilities used in other Coral gems.\n\nThe Coral core library contains functionality that is utilized by other\nCoral gems by providing basic utilities like Git, Shell, Disk, and Data\nmanipulation libraries, a UI system, and a core data model that supports\nEvents, Commands, Repositories, and Memory (version controlled JSON \nobjects).  This library is only used as a starting point for other systems.\n\nNote:  This library is still very early in development!\n\n== Contributing to coral_core\n \n* Check out the latest {major}.{minor} branch to make sure the feature hasn't \n  been implemented or the bug hasn't been fixed yet.\n* Check out the issue tracker to make sure someone already hasn't requested \n  it and/or contributed it.\n* Fork the project.\n* Start a feature/bugfix branch.\n* Commit and push until you are happy with your contribution.\n* Make sure to add tests for it. This is important so I don't break it in a \n  future version unintentionally.\n* Please try not to mess with the Rakefile, version, or history. If you want \n  to have your own version, or is otherwise necessary, that is fine, but \n  please isolate to its own commit so I can cherry-pick around it.\n\n== Copyright\n\nLicensed under GPLv3.  See LICENSE.txt for further details.\n\nCopyright (c) 2013  Adrian Webb <adrian.webb@coraltech.net>\nCoral Technology Group LLC"
  s.email = "adrian.webb@coraltech.net"
  s.executables = ["coral"]
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.rdoc"
  ]
  s.files = [
    ".document",
    ".gitmodules",
    "Gemfile",
    "Gemfile.lock",
    "LICENSE.txt",
    "README.rdoc",
    "Rakefile",
    "VERSION",
    "bin/coral",
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
    "bootstrap/os/ubuntu/05_ruby.sh",
    "bootstrap/os/ubuntu/06_puppet.sh",
    "bootstrap/os/ubuntu/10_coral.sh",
    "coral_core.gemspec",
    "lib/coral/action/add.rb",
    "lib/coral/action/bootstrap.rb",
    "lib/coral/action/clone.rb",
    "lib/coral/action/create.rb",
    "lib/coral/action/exec.rb",
    "lib/coral/action/image.rb",
    "lib/coral/action/images.rb",
    "lib/coral/action/lookup.rb",
    "lib/coral/action/machines.rb",
    "lib/coral/action/provision.rb",
    "lib/coral/action/remove.rb",
    "lib/coral/action/save.rb",
    "lib/coral/action/seed.rb",
    "lib/coral/action/spawn.rb",
    "lib/coral/action/start.rb",
    "lib/coral/action/stop.rb",
    "lib/coral/action/update.rb",
    "lib/coral/command/shell.rb",
    "lib/coral/configuration/file.rb",
    "lib/coral/event/puppet.rb",
    "lib/coral/event/regex.rb",
    "lib/coral/machine/fog.rb",
    "lib/coral/machine/physical.rb",
    "lib/coral/network/default.rb",
    "lib/coral/node/aws.rb",
    "lib/coral/node/fog.rb",
    "lib/coral/node/google.rb",
    "lib/coral/node/local.rb",
    "lib/coral/node/rackspace.rb",
    "lib/coral/project/git.rb",
    "lib/coral/project/github.rb",
    "lib/coral/provisioner/puppetnode.rb",
    "lib/coral/provisioner/puppetnode/resource.rb",
    "lib/coral/provisioner/puppetnode/resource_group.rb",
    "lib/coral/template/environment.rb",
    "lib/coral/template/json.rb",
    "lib/coral/template/wrapper.rb",
    "lib/coral/template/yaml.rb",
    "lib/coral/translator/json.rb",
    "lib/coral/translator/yaml.rb",
    "lib/coral_core.rb",
    "lib/coral_core/codes.rb",
    "lib/coral_core/config.rb",
    "lib/coral_core/config/collection.rb",
    "lib/coral_core/config/options.rb",
    "lib/coral_core/coral.rb",
    "lib/coral_core/core.rb",
    "lib/coral_core/errors.rb",
    "lib/coral_core/facade.rb",
    "lib/coral_core/mixin/action/commit.rb",
    "lib/coral_core/mixin/action/keypair.rb",
    "lib/coral_core/mixin/action/node.rb",
    "lib/coral_core/mixin/action/project.rb",
    "lib/coral_core/mixin/action/push.rb",
    "lib/coral_core/mixin/config/collection.rb",
    "lib/coral_core/mixin/config/ops.rb",
    "lib/coral_core/mixin/config/options.rb",
    "lib/coral_core/mixin/lookup.rb",
    "lib/coral_core/mixin/macro/object_interface.rb",
    "lib/coral_core/mixin/macro/plugin_interface.rb",
    "lib/coral_core/mixin/settings.rb",
    "lib/coral_core/mixin/sub_config.rb",
    "lib/coral_core/mod/hash.rb",
    "lib/coral_core/mod/hiera_backend.rb",
    "lib/coral_core/plugin.rb",
    "lib/coral_core/plugin/action.rb",
    "lib/coral_core/plugin/base.rb",
    "lib/coral_core/plugin/command.rb",
    "lib/coral_core/plugin/configuration.rb",
    "lib/coral_core/plugin/event.rb",
    "lib/coral_core/plugin/extension.rb",
    "lib/coral_core/plugin/machine.rb",
    "lib/coral_core/plugin/network.rb",
    "lib/coral_core/plugin/node.rb",
    "lib/coral_core/plugin/project.rb",
    "lib/coral_core/plugin/provisioner.rb",
    "lib/coral_core/plugin/template.rb",
    "lib/coral_core/plugin/translator.rb",
    "lib/coral_core/types.rb",
    "lib/coral_core/util/batch.rb",
    "lib/coral_core/util/cli.rb",
    "lib/coral_core/util/data.rb",
    "lib/coral_core/util/disk.rb",
    "lib/coral_core/util/git.rb",
    "lib/coral_core/util/interface.rb",
    "lib/coral_core/util/process.rb",
    "lib/coral_core/util/shell.rb",
    "lib/facter/coral_config_ready.rb",
    "lib/facter/coral_exists.rb",
    "lib/facter/coral_network.rb",
    "lib/hiera/coral_logger.rb",
    "lib/puppet/indirector/coral.rb",
    "lib/puppet/indirector/data_binding/coral.rb",
    "lib/puppet/parser/functions/config_initialized.rb",
    "lib/puppet/parser/functions/coral_include.rb",
    "lib/puppet/parser/functions/coral_resources.rb",
    "lib/puppet/parser/functions/deep_merge.rb",
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
    "spec/coral_core/interface_spec.rb",
    "spec/coral_mock_input.rb",
    "spec/coral_test_kernel.rb",
    "spec/spec_helper.rb"
  ]
  s.homepage = "http://github.com/coralnexus/ruby-coral_core"
  s.licenses = ["GPLv3"]
  s.rdoc_options = ["--title", "Coral Core library", "--main", "README.rdoc", "--line-numbers"]
  s.require_paths = ["lib"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.8.1")
  s.rubyforge_project = "coral_core"
  s.rubygems_version = "1.8.11"
  s.summary = "Provides core data elements and utilities used in other Coral gems"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<log4r>, ["~> 1.1"])
      s.add_runtime_dependency(%q<i18n>, ["~> 0.6"])
      s.add_runtime_dependency(%q<deep_merge>, ["~> 1.0"])
      s.add_runtime_dependency(%q<hiera>, ["~> 1.3"])
      s.add_runtime_dependency(%q<multi_json>, ["~> 1.7"])
      s.add_runtime_dependency(%q<grit>, ["~> 2.5"])
      s.add_runtime_dependency(%q<fog>, ["~> 1"])
      s.add_runtime_dependency(%q<rgen>, ["~> 0.6"])
      s.add_runtime_dependency(%q<facter>, ["~> 1.7"])
      s.add_runtime_dependency(%q<puppet>, ["~> 3.2"])
      s.add_development_dependency(%q<bundler>, ["~> 1.2"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.8"])
      s.add_development_dependency(%q<rspec>, ["~> 2.10"])
      s.add_development_dependency(%q<rdoc>, ["~> 3.12"])
      s.add_development_dependency(%q<yard>, ["~> 0.8"])
    else
      s.add_dependency(%q<log4r>, ["~> 1.1"])
      s.add_dependency(%q<i18n>, ["~> 0.6"])
      s.add_dependency(%q<deep_merge>, ["~> 1.0"])
      s.add_dependency(%q<hiera>, ["~> 1.3"])
      s.add_dependency(%q<multi_json>, ["~> 1.7"])
      s.add_dependency(%q<grit>, ["~> 2.5"])
      s.add_dependency(%q<fog>, ["~> 1"])
      s.add_dependency(%q<rgen>, ["~> 0.6"])
      s.add_dependency(%q<facter>, ["~> 1.7"])
      s.add_dependency(%q<puppet>, ["~> 3.2"])
      s.add_dependency(%q<bundler>, ["~> 1.2"])
      s.add_dependency(%q<jeweler>, ["~> 1.8"])
      s.add_dependency(%q<rspec>, ["~> 2.10"])
      s.add_dependency(%q<rdoc>, ["~> 3.12"])
      s.add_dependency(%q<yard>, ["~> 0.8"])
    end
  else
    s.add_dependency(%q<log4r>, ["~> 1.1"])
    s.add_dependency(%q<i18n>, ["~> 0.6"])
    s.add_dependency(%q<deep_merge>, ["~> 1.0"])
    s.add_dependency(%q<hiera>, ["~> 1.3"])
    s.add_dependency(%q<multi_json>, ["~> 1.7"])
    s.add_dependency(%q<grit>, ["~> 2.5"])
    s.add_dependency(%q<fog>, ["~> 1"])
    s.add_dependency(%q<rgen>, ["~> 0.6"])
    s.add_dependency(%q<facter>, ["~> 1.7"])
    s.add_dependency(%q<puppet>, ["~> 3.2"])
    s.add_dependency(%q<bundler>, ["~> 1.2"])
    s.add_dependency(%q<jeweler>, ["~> 1.8"])
    s.add_dependency(%q<rspec>, ["~> 2.10"])
    s.add_dependency(%q<rdoc>, ["~> 3.12"])
    s.add_dependency(%q<yard>, ["~> 0.8"])
  end
end

