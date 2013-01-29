
module Coral
class Repository < Core
    
  #-----------------------------------------------------------------------------
  # Constructor / Destructor
  
  def initialize(options = {})
    super(options)
    
    @name       = ( options.has_key?(:name) ? string(options[:name]) : '' )
    @directory  = ( options.has_key?(:directory) ? string(options[:directory]) : '' )
    @submodule  = ( options.has_key?(:submodule) ? string(options[:submodule]) : '' )
    @remote_dir = ( options.has_key?(:remote_dir) ? string(options[:remote_dir]) : '' )
            
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
        if ! @submodule.empty?
          directory = File.join(@directory, @submodule) 
        end
        @git = Git.open(directory, {
          :log => @logger,
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
    if can_persist?
      hosts = array(hosts)
      
      delete_remote(name)
      return self if hosts.empty?
      
      if @remote_dir && ! options.has_key?(:repo)
        options[:repo] = @remote_dir
      end
      
      git.add_remote(name, Git.url(hosts.shift, options[:repo], options))
      
      if ! hosts.empty?
        remote = git.remote(name)
      
        hosts.each do |host|
          git_url = Git.url(host, options[:repo], options)
          remote.set_url(git_url, options)
        end
      end
    end
    return self
  end
  
  #---
  
  def delete_remote(name)
    if can_persist?
      remote = @git.remote(name)
      if remote && remote.url && ! remote.url.empty?
        remote.remove
      end
    end
    return self  
  end
  
  #-----------------------------------------------------------------------------
  # Git operations
  
  def commit(files = '.', options = {})
    if can_persist?
      time    = Time.new.strftime("%Y-%m-%d %H:%M:%S")
      user    = ENV['USER']
      message = ( options[:message] ? options[:message] : 'Saving state' )
      
      options[:author]      = ( ! options[:author].empty? ? options[:author] : '' )
      options[:allow_empty] = ( options[:allow_empty] ? options[:allow_empty] : false )
      
      unless user && ! user.empty?
        user = 'UNKNOWN'
      end
    
      array(files).each do |file|
        @git.add(file)                      # Get all added and updated files
        @git.add(file, { :update => true }) # Get all deleted files
      end
        
      @git.commit("#{time} by <#{user}> - #{message}", options)                
    end
    return self      
  end
  
  #-----------------------------------------------------------------------------
  
  def push!(remote = 'origin', options = {})
    if can_persist?
      branch  = ( options[:branch] && ! options[:branch].empty? ? options[:branch] : 'master' )
      tags    = ( options[:tags] ? options[:tags] : false )
    
      return Coral::Command.new({
        :command => :git,
        :data => { 'git-dir=' => @git.repo.to_s },
        :subcommand => {
          :command => :push,
          :flags => ( tags ? :tags : '' ),
          :args => [ remote, branch ]
        }
      }).exec!(options) do |line|
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