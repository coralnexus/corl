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
  gem.license               = "GPLv3"
  gem.email                 = "adrian.webb@coralnexus.com"
  gem.authors               = ["Adrian Webb"]
  gem.summary               = %Q{Provides core data elements and utilities used in other CORL gems}
  gem.description           = File.read('README.rdoc')  
  gem.required_ruby_version = '>= 1.8.1'
  gem.has_rdoc              = true
  gem.rdoc_options << '--title' << 'Cluster Orchestration and Research Library' <<
                      '--main' << 'README.rdoc' <<
                      '--line-numbers'
                      
  gem.files.include Dir.glob('bootstrap/**/*') 
  
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

version   = CORL::VERSION
doc_title = "corl #{version}"

Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = doc_title
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

#---

YARD::Rake::YardocTask.new do |ydoc|
  ydoc.files   = [ 'README*', 'lib/**/*.rb' ]
  ydoc.options = [ "--output-dir yardoc", "--title '#{doc_title}'" ]
end
