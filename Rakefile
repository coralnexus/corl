# encoding: utf-8

require 'rubygems'
require 'bundler'
require 'rake'
require 'rake/testtask'
require 'rdoc/task'
require 'jeweler'

require './lib/coral_core.rb'

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
  gem.version               = Coral::VERSION
  gem.name                  = "coral_core"
  gem.homepage              = "http://github.com/coraltech/ruby-coral_core"
  gem.rubyforge_project     = 'coral_core'
  gem.license               = "GPLv3"
  gem.email                 = "adrian.webb@coraltech.net"
  gem.authors               = ["Adrian Webb"]
  gem.summary               = %Q{Provides core data elements and utilities used in other Coral gems}
  gem.description           = %Q{
    The Coral core library contains functionality that is utilized by other
    Coral gems by providing basic utilities like Git, Shell, Disk, and Data
    manipulation libraries, a UI system, and a core data model that supports
    Events, Commands, Repositories, and Memory (version controlled JSON 
    objects).  This library is only used as a starting point for other systems.
  }  
  gem.required_ruby_version = '>= 1.8.1'
  gem.has_rdoc              = true
  gem.rdoc_options << '--title' << 'Coral Core library' <<
                      '--main' << 'README.rdoc' <<
                      '--line-numbers' 
  
  # Dependencies defined in Gemfile
end

Jeweler::RubygemsDotOrgTasks.new

#-------------------------------------------------------------------------------
# Testing

Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

task :default => :test

#-------------------------------------------------------------------------------
# Documentation

Rake::RDocTask.new do |rdoc|
  version = Coral::VERSION

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = "coral_core #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
