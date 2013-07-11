# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "coral_core"
  s.version = "0.3.7"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Adrian Webb"]
  s.date = "2013-07-11"
  s.description = "= coral_core\n\nThis library provides core data elements and utilities used in other Coral gems.\n\nThe Coral core library contains functionality that is utilized by other\nCoral gems by providing basic utilities like Git, Shell, Disk, and Data\nmanipulation libraries, a UI system, and a core data model that supports\nEvents, Commands, Repositories, and Memory (version controlled JSON \nobjects).  This library is only used as a starting point for other systems.\n\nNote:  This library is still very early in development!\n\n== Contributing to coral_core\n \n* Check out the latest {major}.{minor} branch to make sure the feature hasn't \n  been implemented or the bug hasn't been fixed yet.\n* Check out the issue tracker to make sure someone already hasn't requested \n  it and/or contributed it.\n* Fork the project.\n* Start a feature/bugfix branch.\n* Commit and push until you are happy with your contribution.\n* Make sure to add tests for it. This is important so I don't break it in a \n  future version unintentionally.\n* Please try not to mess with the Rakefile, version, or history. If you want \n  to have your own version, or is otherwise necessary, that is fine, but \n  please isolate to its own commit so I can cherry-pick around it.\n\n== Copyright\n\nLicensed under GPLv3.  See LICENSE.txt for further details.\n\nCopyright (c) 2013  Adrian Webb <adrian.webb@coraltech.net>\nCoral Technology Group LLC"
  s.email = "adrian.webb@coraltech.net"
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.rdoc"
  ]
  s.files = [
    ".document",
    "Gemfile",
    "Gemfile.lock",
    "LICENSE.txt",
    "README.rdoc",
    "Rakefile",
    "VERSION",
    "coral_core.gemspec",
    "lib/coral/command/shell.rb",
    "lib/coral/context/type.rb",
    "lib/coral/event/puppet.rb",
    "lib/coral/event/regex.rb",
    "lib/coral/project/git.rb",
    "lib/coral/project/github.rb",
    "lib/coral/provisioner/puppet.rb",
    "lib/coral/provisioner/puppet/resource.rb",
    "lib/coral/provisioner/puppet/resource_group.rb",
    "lib/coral/template/environment.rb",
    "lib/coral/template/json.rb",
    "lib/coral/template/wrapper.rb",
    "lib/coral/template/yaml.rb",
    "lib/coral_core.rb",
    "lib/coral_core/builder.rb",
    "lib/coral_core/config.rb",
    "lib/coral_core/config/collection.rb",
    "lib/coral_core/config/file.rb",
    "lib/coral_core/config/options.rb",
    "lib/coral_core/core.rb",
    "lib/coral_core/interface.rb",
    "lib/coral_core/mixins/config_collection.rb",
    "lib/coral_core/mixins/config_ops.rb",
    "lib/coral_core/mixins/config_options.rb",
    "lib/coral_core/mixins/lookup.rb",
    "lib/coral_core/mixins/sub_config.rb",
    "lib/coral_core/mod/hash.rb",
    "lib/coral_core/mod/hiera_backend.rb",
    "lib/coral_core/plugin.rb",
    "lib/coral_core/plugin/command.rb",
    "lib/coral_core/plugin/context.rb",
    "lib/coral_core/plugin/event.rb",
    "lib/coral_core/plugin/project.rb",
    "lib/coral_core/plugin/provisioner.rb",
    "lib/coral_core/plugin/template.rb",
    "lib/coral_core/util/cli.rb",
    "lib/coral_core/util/data.rb",
    "lib/coral_core/util/disk.rb",
    "lib/coral_core/util/git.rb",
    "lib/coral_core/util/process.rb",
    "lib/coral_core/util/shell.rb",
    "lib/facter/coral_exists.rb",
    "lib/facter/hiera_ready.rb",
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
    "spec/coral_core/interface_spec.rb",
    "spec/coral_mock_input.rb",
    "spec/coral_test_kernel.rb",
    "spec/spec_helper.rb"
  ]
  s.homepage = "http://github.com/coraltech/ruby-coral_core"
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
      s.add_runtime_dependency(%q<multi_json>, ["~> 1.7"])
      s.add_runtime_dependency(%q<grit>, ["~> 2.5"])
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
      s.add_dependency(%q<multi_json>, ["~> 1.7"])
      s.add_dependency(%q<grit>, ["~> 2.5"])
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
    s.add_dependency(%q<multi_json>, ["~> 1.7"])
    s.add_dependency(%q<grit>, ["~> 2.5"])
    s.add_dependency(%q<puppet>, ["~> 3.2"])
    s.add_dependency(%q<bundler>, ["~> 1.2"])
    s.add_dependency(%q<jeweler>, ["~> 1.8"])
    s.add_dependency(%q<rspec>, ["~> 2.10"])
    s.add_dependency(%q<rdoc>, ["~> 3.12"])
    s.add_dependency(%q<yard>, ["~> 0.8"])
  end
end

