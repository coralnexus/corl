# encoding: utf-8

require 'rubygems'
require 'rake'
require 'bundler'
require 'jeweler'
require 'rspec/core/rake_task'
require 'rdoc/task'
require 'yard'

require './lib/corl.rb'

#-------------------------------------------------------------------------------
# Dependencies

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

#-------------------------------------------------------------------------------
# Gem specification

Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name                  = "corl"
  gem.homepage              = "http://github.com/coralnexus/corl"
  gem.rubyforge_project     = 'corl'
  gem.license               = "Apache License, Version 2.0"
  gem.email                 = "adrian.webb@coralnexus.com"
  gem.authors               = ["Adrian Webb"]
  gem.summary               = %Q{Coral Orchestration and Research Library}
  gem.description           = %Q{Framework that provides a simple foundation for growing organically in the cloud}
  gem.required_ruby_version = '>= 1.9.1'
  gem.has_rdoc              = true
  gem.rdoc_options << '--title' << 'Coral Orchestration and Research Library' <<
                      '--main' << 'README.rdoc' <<
                      '--line-numbers'

  gem.files = [
    Dir.glob('bootstrap/**/*'),
    Dir.glob('bin/*'),
    Dir.glob('lib/**/*.rb'),
    Dir.glob('spec/**/*.rb'),
    Dir.glob('locales/**/*.yml'),
    Dir.glob('**/*.rdoc'),
    Dir.glob('**/*.txt'),
    Dir.glob('Gemfile*'),
    Dir.glob('*.gemspec'),
    Dir.glob('.git*'),
    'VERSION',
    'Rakefile'
  ]

  # Dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

#-------------------------------------------------------------------------------
# Testing

RSpec::Core::RakeTask.new(:spec, :tag) do |spec, task_args|
  options = []
  options << "--tag #{task_args[:tag]}" if task_args.is_a?(Array) && ! task_args[:tag].to_s.empty?
  spec.rspec_opts = options.join(' ')
end

task :default => :spec

#-------------------------------------------------------------------------------
# Documentation

version   = CORL.VERSION
doc_title = "corl #{version}"

class RDoc::Options
  def template_dir_for(template)
    File.join(File.dirname(__FILE__), 'rdoc', 'template')
  end
end

Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = File.join('rdoc', 'site', version)

  rdoc.title    = doc_title
  rdoc.main     = 'README.rdoc'

  rdoc.options << '--line-numbers'
  rdoc.options << '--all'
  rdoc.options << '-w' << '2'

  rdoc.rdoc_files.include('*.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

#---

YARD::Rake::YardocTask.new do |ydoc|
  ydoc.files   = [ '*.rdoc', 'lib/**/*.rb' ]
  ydoc.options = [ "--output-dir yardoc", "--title '#{doc_title}'" ]
end
