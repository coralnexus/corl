
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
  attr_reader :directory, :submodule, :lib

  #---
   
  def ensure_git(reset = false)
    if reset || ! @lib
      if @directory.empty?
        @lib = nil
      else
        directory = @directory
        unless Util::Data.empty?(@submodule)
          directory = File.join(@directory, @submodule) 
        end
        @lib = Grit::Repo.init_bare_or_open(directory)
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
      
      lib.remote_add(name, Git.url(hosts.shift, config[:repo], options))
      
      if ! hosts.empty?
        hosts.each do |host|
          lib.remote_set_url(name, Git.url(host, config[:repo], config.options), {
            :add    => true,
            :delete => config.get(:delete, false),
            :push   => config.get(:push, false)
          })
        end
      end
    end
    return self
  end
  
  #---
  
  def delete_remote(name)
    if can_persist?
      lib.remote_rm(name)
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
      
      unless user && ! user.empty?
        user = 'UNKNOWN'
      end
      
      files = array(files)
      lib.add(files)                          # Get all added and updated files
      lib.git.add({ :update => true }, files) # Get all deleted files
    
      lib.git.commit({ 
        :m           => "#{time} by <#{user}> - #{message}",
        :author      => config.get(:author, false),
        :allow_empty => config.get(:allow_empty, false) 
      })                
    end
    return self      
  end
  
  #-----------------------------------------------------------------------------
  # SSH operations
 
  def pull!(remote = 'origin', options = {})
    config = Config.ensure(options)
    
    if can_persist?
      return Coral::Command.new({
        :command => :git,
        :data    => { 'git-dir=' => lib.path },
        :subcommand => {
          :command => :pull,
          :flags   => ( config.get(:tags, false) ? :tags : '' ),
          :args    => [ remote, config.get(:branch, 'master') ]
        }
      }).exec!(config) do |line|
        block_given? ? yield(line) : true
      end
    end
  end
  
  #---
  
  def pull(remote = 'origin', options = {})
    return pull!(remote, options)
  end  
  
  #---
    
  def push!(remote = 'origin', options = {})
    config = Config.ensure(options)
    
    if can_persist?
      return Coral::Command.new({
        :command => :git,
        :data => { 'git-dir=' => lib.path },
        :subcommand => {
          :command => :push,
          :flags => ( config.get(:tags, false) ? :tags : '' ),
          :args => [ remote, config.get(:branch, 'master') ]
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
    return true if @lib
    return false
  end
end
end