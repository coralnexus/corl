
module Coral
module Project
class Git < Plugin::Project
 
  #-----------------------------------------------------------------------------
  # Project plugin interface

   
  #-----------------------------------------------------------------------------
  # Plugin operations
   
  def normalize
    super
    
    init(:revision, 'master')
        
    set_location(Util::Disk.filename(get(:directory, Dir.pwd)))
    
    set_origin(get(:url)) unless get(:url, false)
    checkout(get(:revision))
    
    pull if get(:pull, false)    
  end
       
  #-----------------------------------------------------------------------------
  # Checks
   
  def ensure_git(reset = false)
    if reset || ! get(:git_lib, false)
      delete(:git_lib)
      unless directory.empty?
        set(:git_lib, Git.new(directory))
      end
    end
    return self
  end
  protected :ensure_git
  
  #---
   
  def can_persist?
    ensure_git
    return true if get(:git_lib, false)
    return false
  end
 
  #---
          
  def top?(path)
    git_dir = File.join(path, '.git')
    if File.exist?(git_dir)
      return true if File.directory?(git_dir)
    elsif File.exist?(path) && (path =~ /\.git$/ && File.exist?(File.join(path, 'HEAD')))
      return true
    end
    return false
  end
    
  #---
          
  def submodule?(path)
    git_dir = File.join(path, '.git')
    if File.exist?(git_dir)
      unless File.directory?(git_dir)
        git_dir = Util::Disk.read(git_dir)        
        unless git_dir.nil?
          git_dir = git_dir.gsub(/^gitdir\:\s*/, '').strip
          return true if File.directory?(git_dir)
        end  
      end
    end
    return false
  end
   
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers
      
  def project_directory(path, require_top_level = false)
    path    = File.expand_path(path)
    git_dir = File.join(path, '.git')

    if File.exist?(git_dir)
      if File.directory?(git_dir)
        return git_dir
      elsif ! require_top_level
        git_dir = Util::Disk.read(git_dir)
        unless git_dir.nil?
          git_dir = git_dir.gsub(/^gitdir\:\s*/, '').strip
          return git_dir if File.directory?(git_dir)
        end  
      end
    elsif File.exist?(path) && (path =~ /\.git$/ && File.exist?(File.join(path, 'HEAD')))
      return path
    end
    return nil
  end

  #---
  
  def lib(default = nil)
    return get(:git_lib, default)
  end
 
  #---
  
  def git
    return lib.git if can_persist?
    return nil
  end
  protected :git
  
  #---
   
  def set_location(directory)
    ensure_git(true)
    super(directory)
    
    init_remotes    
    load_revision    
    return self
  end

  #---
  
  def load_revision
    if can_persist?
      set(:revision, git.native(:rev_parse, { :abbrev_ref => true }, 'HEAD').strip)
    
      if get(:revision, '').empty?
        set(:revision, git.native(:rev_parse, {}, 'HEAD').strip)
      end
      load_submodules
    end
    return self
  end
  protected :load_revision
  
  #---
  
  def submodules(default = nil)
    return get(:submodules, default)
  end
  
  #---
  
  def origin(default = nil)
    return get(:url, default)
  end

  #---
  
  def set_origin(url)
    set(:url, url)
    set_remote(:url, url)
    return self
  end

  #---
  
  def edit(default = nil)
    return get(:edit, default)
  end
  
  #---
  
  def set_edit(url)
    set(:edit, url)
    set_remote(:edit, url)
    return self
  end
    
  #---
  
  def config(name, options = {})
    config = Config.ensure(options) # Just in case we throw a configuration in
    return git.config(config.export, name) if can_persist?
    return nil
  end
  
  #---
  
  def set_config(name, value, options = {})
    config = Config.ensure(options) # Just in case we throw a configuration in
    git.config(config.export, name, string(value)) if can_persist?
    return self
  end
  
  #---
  
  def delete_config(name, options = {})
    config = Config.ensure(options)
    git.config(config.import({ :remove_section => true }).export, name) if can_persist?
    return self
  end

  #-----------------------------------------------------------------------------
  # Basic Git operations
  
  def checkout(revision)
    if can_persist?
      git.checkout({}, revision) unless lib.bare
      set(:revision, revision)
      load_submodules
    end
    return self 
  end
  
  #---
  
  def commit(files = '.', options = {})
    config = Config.ensure(options)
    
    if can_persist?
      time    = Time.new.strftime("%Y-%m-%d %H:%M:%S")
      user    = ENV['USER']
      message = config.get(:message, 'Saving state')
      
      user = 'UNKNOWN' unless user && ! user.empty?
            
      git.reset({}, 'HEAD') # Clear the index so we get a clean commit
      
      files = array(files)
      git.add(files)                      # Get all added and updated files
      git.add({ :update => true }, files) # Get all deleted files
    
      git.commit({ 
        :m           => "#{time} by <#{user}> - #{message}",
        :author      => config.get(:author, false),
        :allow_empty => config.get(:allow_empty, false) 
      })
      
      if ! parent.nil? && config.get(:propogate, true)
        parent.commit(directory, config.import({
          :message => "Updating submodule #{path} with: #{message}"
        }))
      end                
    end
    return self      
  end

  #-----------------------------------------------------------------------------
  # Submodule operations
 
  def submodule_config(ref = 'master')
    commit = lib.commit(ref) if can_persist?
    blob   = commit.tree/'.gitmodules' unless commit.nil?
    
    return {} unless blob

    lines = blob.data.gsub(/\r\n?/, "\n" ).split("\n")

    config  = {}
    current = nil

    lines.each do |line|
      if line =~ /^\[submodule "(.+)"\]$/
        current         = $1
        config[current] = {}
        config[current]['id'] = (commit.tree/current).id
      
      elsif line =~ /^\t(\w+) = (.+)$/
        config[current][$1]   = $2
        config[current]['id'] = (commit.tree/$2).id if $1 == 'path'
      end
    end

    return config
  end
  protected :submodule_config
  
  #---
  
  def load_submodules
    submodules = {}
    
    if can_persist?
      # Returns a Hash of { <path:String> => { 'url' => <url:String>, 'id' => <id:String> } }
      # Returns {} if no .gitmodules file was found
      submodule_config(revision).each do |path, data|
        repo_path = File.join(directory, path)
        if File.directory?(repo_path) && File.exist?(File.join(repo_path, '.git'))
          repo = self.class.open(repo_path)
          repo.set_origin(data['url']) # Just a sanity check (might disapear)
        
          submodules[path] = repo
        end
      end
    end
    set(:submodules, submodules)
    return self  
  end
  protected :load_submodules
  
  #---
  
  def add_submodule(path, url, revision, options = {})
    if can_persist?
      git.submodule({ :branch => revision }, 'add', url, path)
      commit([ '.gitmodules', path ], { :message => "Adding submodule #{url} to #{path}" })      
      load_submodules
    end  
  end
  
  #---
  
  def delete_submodule(path)
    if can_persist?
      submodule_key = "submodule.#{path}"
      
      delete_config(submodule_key)
      delete_config(submodule_key, { :file => '.gitmodules' })
      
      git.rm({ :cached => true }, path)
      FileUtils.rm_rf(File.join(directory, path))
      FileUtils.rm_rf(File.join(git.git_dir, 'modules', path))
      
      commit([ '.gitmodules', path ], { :message => "Removing submodule #{url} from #{path}" })      
      load_submodules
    end  
  end
 
  #---
   
  def update_submodules
    git.submodule({ :timeout => false }, 'update', '--init', '--recursive') if can_persist?
    return self
  end
  protected :update_submodules
  
  #---
  
  def foreach!
    if can_persist?
      submodules.each do |path, repo|
        yield(path, repo)  
      end
    end
    return self
  end 
         
  #-----------------------------------------------------------------------------
  # Remote operations
  
  def init_remotes
    set(:url, config('remote.origin.url'))
    set_edit(edit_url(origin))
    return self 
  end
  protected :init_remotes
 
  #---
  
  def set_remote(name, url)
    delete_remote(name)
    git.remote({}, 'add', name.to_s, url) if can_persist?
    return self
  end
  
  #---
  
  def add_remote_url(name, url, options = {})
    config = Config.ensure(options)
    
    if can_persist?
      git.remote({
        :add    => true,
        :delete => config.get(:delete, false),
        :push   => config.get(:push, false)
      }, 'set-url', name.to_s, url)
    end
    return self  
  end
  
  #---
    
  def set_host_remote(name, hosts, path, options = {})
    config = Config.ensure(options)
    
    if can_persist?
      hosts = array(hosts)
      
      return self if hosts.empty?
      
      set_remote(name.to_s, url(hosts.shift, path, config.options))
      
      unless hosts.empty?
        hosts.each do |host|
          add_remote_url(name.to_s, url(host, path, config.options), config)
        end
      end
    end
    return self
  end
  
  #---
  
  def delete_remote(name)
    if can_persist?
      git.remote({}, 'rm', name.to_s)
    end
    return self  
  end
 
  #-----------------------------------------------------------------------------
  # SSH operations
 
  def pull!(remote = :origin, options = {})
    config  = Config.ensure(options)
    success = false
    
    if can_persist?
      success = Command.new({
        :command => :git,
        :data    => { 'git-dir=' => git.git_dir },
        :subcommand => {
          :command => :pull,
          :flags   => ( config.get(:tags, true) ? :tags : '' ),
          :args    => [ remote, config.get(:branch, '') ]
        }
      }).exec!(config) do |line|
        block_given? ? yield(line) : true
      end
      
      update_submodules
      
      if success && ! parent.nil? && config.get(:propogate, true)
        parent.commit(directory, config.import({
          :message     => "Pulling updates for submodule #{path}",
          :allow_empty => true
        }))
      end      
    end
    return success
  end
  
  #---
  
  def pull(remote = :origin, options = {})
    return pull!(remote, options)
  end  
  
  #---
    
  def push!(remote = :edit, options = {})
    config  = Config.ensure(options)
    success = false
    
    if can_persist?
      success = Command.new({
        :command => :git,
        :data => { 'git-dir=' => git.git_dir },
        :subcommand => {
          :command => :push,
          :flags => ( config.get(:tags, true) ? :tags : '' ),
          :args => [ remote, config.get(:branch, '') ]
        }
      }).exec!(config) do |line|
        block_given? ? yield(line) : true
      end
      
      if success && config.get(:propogate, true)
        foreach! do |path, repo|
          repo.push(remote, config)
        end
      end
    end
    return success
  end
  
  #---
  
  def push(remote = :edit, options = {})
    return push!(remote, options)
  end
  
  #-----------------------------------------------------------------------------
  # Utilities

  def url(host, repo, options = {})
    config = Config.ensure(options)
    
    user = config.get(:user, 'git')
    auth = config.get(:auth, true)
    
    return user + (auth ? '@' : '://') + host + (auth ? ':' : '/') + repo
  end
  
  #---
  
  def edit_url(url, options = {})
    config = Config.ensure(options)
    
    if matches = url.strip.match(/^(https?|git)\:\/\/([^\/]+)\/(.+)/)
      protocol, host, path = matches.captures
      return url(host, path, config.import({ :auth => true }))
    end
    return url
  end          
end
end
end
