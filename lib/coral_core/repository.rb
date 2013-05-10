
module Coral
class Repository < Core
    
  #-----------------------------------------------------------------------------
  # Constructor / Destructor
  
  def initialize(options = {})
    config = Config.ensure(options)
    
    super(config)
    
    @name       = config.get(:name, '')
    @directory  = config.get(:directory, '')
    @submodule  = config.get(:submodule, '')
    @remote_dir = config.get(:remote_dir, '')
    
    ensure_git(true) 
  end
    
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers
  
  attr_accessor :name, :remote_dir
  attr_reader :directory, :submodule, :git

  #---
   
  def ensure_git(reset = false)
    if reset || ! @git
      if @directory.empty?
        @git = nil
      else
        directory = @directory
        unless Util::Data.empty?(@submodule)
          directory = File.join(@directory, @submodule) 
        end
        @git = Git.open(directory, {
          :log => logger,
        })
      end
    end
    return self
  end
  
  #---
    
  def set_repository(directory = '', submodule = '')
    @directory = string(directory)
    @submodule = string(submodule)
    ensure_git(true)
    return self
  end
      
  #-----------------------------------------------------------------------------
    
  def set_remote(name, hosts, options = {})
    config = Config.ensure(options)
    
    if can_persist?
      hosts = array(hosts)
      
      delete_remote(name)
      return self if hosts.empty?
      
      if @remote_dir && ! config.get(:repo, false)
        config[:repo] = @remote_dir
      end
      
      git.add_remote(name, Git.url(hosts.shift, config[:repo], options))
      
      if ! hosts.empty?
        remote = git.remote(name)
        
        config[:add] = true
      
        hosts.each do |host|
          git_url = Git.url(host, config[:repo], config.options)
          remote.set_url(git_url, config.options)
        end
      end
    end
    return self
  end
  
  #---
  
  def delete_remote(name)
    if can_persist?
      remote = git.remote(name)
      if remote && remote.url && ! remote.url.empty?
        remote.remove
      end
    end
    return self  
  end
  
  #-----------------------------------------------------------------------------
  # Git operations
  
  def commit(files = '.', options = {})
    config = Config.ensure(options)
    
    if can_persist?
      time    = Time.new.strftime("%Y-%m-%d %H:%M:%S")
      user    = ENV['USER']
      message = config.get(:message, 'Saving state')
      
      config[:author]      = config.get(:author, '')
      config[:allow_empty] = config.get(:allow_empty, false)
      
      unless user && ! user.empty?
        user = 'UNKNOWN'
      end
    
      array(files).each do |file|
        git.add(file)                      # Get all added and updated files
        git.add(file, { :update => true }) # Get all deleted files
      end
        
      git.commit("#{time} by <#{user}> - #{message}", config.options)                
    end
    return self      
  end
  
  #-----------------------------------------------------------------------------
  
  def push!(remote = 'origin', options = {})
    config = Config.ensure(options)
    
    if can_persist?
      branch = config.get(:branch, 'master')
      tags   = config.get(:tags, false)
    
      return Coral::Command.new({
        :command => :git,
        :data => { 'git-dir=' => git.repo.to_s },
        :subcommand => {
          :command => :push,
          :flags => ( tags ? :tags : '' ),
          :args => [ remote, branch ]
        }
      }).exec!(config) do |line|
        block_given? ? yield(line) : true
      end
    end
  end
  
  #---
  
  def push(remote = 'origin', options = {})
    return push!(remote, options)
  end  
     
  #-----------------------------------------------------------------------------
  # Checks
  
  def can_persist?
    ensure_git
    return true if @git
    return false
  end
end
end