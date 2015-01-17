# encoding: utf-8

require 'rubygems'
require 'rake'
require 'bundler'
require 'jeweler'
require 'rspec/core/rake_task'
require 'rdoc/task'
require 'github/markup'

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
    Dir.glob('*.rdoc'),
    Dir.glob('info/*.rdoc'),
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

version   = File.read(File.join(File.dirname(__FILE__), 'VERSION'))
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
  rdoc.rdoc_files.include('info/*.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')

  #
  # [link:info/*.rdoc]
  #
  # Doc viewers
  #
  # Github.com (no control) & Generated RDoc site (limited control)
  #      README.rdoc
  #      info/*.rdoc
  # Local Github render (full control)
  #      tmp/README.rdoc
  #      tmp/info/*.rdoc
  #

  FileUtils.mkdir_p('tmp')

  html_prefix = "<!DOCTYPE html><html lang='en' class=''><head><title>Test Github markup</title>"
  html_prefix << '<link href="https://assets-cdn.github.com/assets/github-07ee5f9b28252daadba7750d43951602b35cdaa9dc19b5aff2eececebd6b6627.css" media="all" rel="stylesheet" type="text/css" />'
  html_prefix << '<link href="https://assets-cdn.github.com/assets/github2-13950c15da59f6c02f99ce11c07b93342a063458ce7ab72e243013dd9729008e.css" media="all" rel="stylesheet" type="text/css" />'
  html_prefix << "</head><body style='padding: 30px'><div class='site' itemscope itemtype='http://schema.org/WebPage'><article class='markdown-body entry-content' itemprop='mainContentOfPage'>"
  html_suffix = "</article></div></body></html>"

  embedded_html = lambda do |html_body|
    "#{html_prefix}#{html_body}#{html_suffix}"
  end

  create_rdoc_link = lambda do |source|
    rdoc_html = File.join(Dir.pwd, rdoc.rdoc_dir, "#{source.gsub('.', '_')}.html")
    rdoc_link = File.join(Dir.pwd, rdoc.rdoc_dir, source)

    if File.exists?(rdoc_html)
      FileUtils.rm_f(rdoc_link)
      FileUtils.ln_s(rdoc_html, rdoc_link)
    end
  end

  tmp_readme         = File.join(Dir.pwd, 'tmp', rdoc.main)
  readme_github_html = embedded_html.call(GitHub::Markup.render(rdoc.main, File.read(rdoc.main)))
  File.write(tmp_readme, readme_github_html)

  create_rdoc_link.call(rdoc.main)

  Dir.glob('info/*.rdoc') do |rdoc_file|
    tmp_dir     = File.join(Dir.pwd, 'tmp', File.dirname(rdoc_file))
    tmp_file    = File.join(Dir.pwd, 'tmp', rdoc_file)
    readme_file = File.join(tmp_dir, rdoc.main)

    FileUtils.mkdir_p(tmp_dir)

    FileUtils.rm_f(readme_file)
    FileUtils.ln_s(tmp_readme, readme_file)

    github_html = embedded_html.call(GitHub::Markup.render(rdoc_file, File.read(rdoc_file)))
    File.write(tmp_file, github_html)

    create_rdoc_link.call(rdoc_file)
  end
end
