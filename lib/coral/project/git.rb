
module Coral
module Project
class Git < Plugin::Project
 
  #-----------------------------------------------------------------------------
  # Project plugin interface
   
  def normalize
    super   
  end
  
  #-----------------------------------------------------------------------------
  # Git interface (local)
   
  def ensure_git(reset = false)
    if reset || ! get(:git_lib, false)
      delete(:git_lib)
      unless directory.empty?
        set(:git_lib, Util::Git.new(directory))
      end
    end
    return self
  end
  protected :ensure_git
       
  #-----------------------------------------------------------------------------
  # Checks
   
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
          
  def subproject?(path)
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
  
  #---
      
  def project_directory?(path, require_top_level = false)
    path    = File.expand_path(path)
    git_dir = File.join(path, '.git')

    if File.exist?(git_dir)
      if File.directory?(git_dir)
        return true
      elsif ! require_top_level
        git_dir = Util::Disk.read(git_dir)
        unless git_dir.nil?
          git_dir = git_dir.gsub(/^gitdir\:\s*/, '').strip
          return true if File.directory?(git_dir)
        end  
      end
    elsif File.exist?(path) && (path =~ /\.git$/ && File.exist?(File.join(path, 'HEAD')))
      return true
    end
    return false
  end
   
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers
  
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
    super(directory) do
      ensure_git(true)
    end
    return self
  end
  
  #---
  
  def config(name, options = {})
    return super(name, options) do |config|
      git.config(config.export, name)
    end
  end
  
  #---
  
  def set_config(name, value, options = {})
    return super(name, value, options) do |config|
      git.config(config.export, name, string(value))
    end
  end
  
  #---
  
  def delete_config(name, options = {})
    return super(name, options) do |config|
      git.config(config.import({ :remove_section => true }).export, name)
    end
  end
  
  #---
 
  def subproject_config(options = {})
    return super(options) do |config|
      commit = lib.commit(revision)
      blob   = commit.tree/'.gitmodules' unless commit.nil?
      result = {}
    
      if blob
        lines   = blob.data.gsub(/\r\n?/, "\n" ).split("\n")
        current = nil

        lines.each do |line|
          if line =~ /^\[submodule "(.+)"\]$/
            current         = $1
            result[current] = {}
            result[current]['id'] = (commit.tree/current).id
      
          elsif line =~ /^\t(\w+) = (.+)$/
            result[current][$1]   = $2
            result[current]['id'] = (commit.tree/$2).id if $1 == 'path'
          end
        end
      end
      result
    end
  end
 
  #-----------------------------------------------------------------------------
  # Basic Git operations
  
  def load_revision
    return super do
      current_revision = git.native(:rev_parse, { :abbrev_ref => true }, 'HEAD').strip
      
      set(:revision, current_revision) unless get(:revision, false)
      
      if get(:revision, '').empty?
        set(:revision, current_revision)
      end
    end
  end
  
  #---
  
  def checkout(revision)
    return super(revision) do
      git.checkout({}, revision) unless lib.bare  
    end
  end
  
  #---
  
  def commit(files = '.', options = {})
    return super(files, options) do |config, time, user, message|
      begin
        git.reset({}, 'HEAD') # Clear the index so we get a clean commit
      
        files = array(files)
      
        git.add({ :raise => true }, files)                  # Get all added and updated files
        git.add({ :update => true, :raise => true }, files) # Get all deleted files
        
        commit_options = {
          :raise       => true, 
          :m           => "#{time} by <#{user}> - #{message}",
          :allow_empty => config.get(:allow_empty, false) 
        }
        commit_options[:author] = config[:author] if config.get(:author, false)
    
        git.commit(commit_options)
        true
      rescue
        false
      end
    end   
  end

  #-----------------------------------------------------------------------------
  # Subproject operations
 
  def load_subprojects(options = {})
    return super(options) do |project_path, data|
      File.exist?(File.join(project_path, '.git'))
    end
  end
  
  #---
  
  def add_subproject(path, url, revision, options = {})
    return super do
      branch_options = ''
      branch_options = [ '-b', revision ] if revision
      
      begin      
        git.submodule({ :raise => true }, 'add', *branch_options, url, path)
        commit([ '.gitmodules', path ], { :message => "Adding submodule #{url} to #{path}" })
        true
      rescue
        false
      end
    end  
  end
  
  #---
  
  def delete_subproject(path)
    return super do
      submodule_key = "submodule.#{path}"
      
      delete_config(submodule_key)
      delete_config(submodule_key, { :file => '.gitmodules' })
      
      git.rm({ :cached => true }, path)
      FileUtils.rm_rf(File.join(directory, path))
      FileUtils.rm_rf(File.join(git.git_dir, 'modules', path))
      
      commit([ '.gitmodules', path ], { :message => "Removing submodule #{path} from #{url}" })
    end  
  end
 
  #---
   
  def update_subprojects
    return super do
      git.submodule({ :timeout => false }, 'update', '--init', '--recursive')
    end
  end
         
  #-----------------------------------------------------------------------------
  # Remote operations
  
  def init_remotes
    return super do
      origin_url = config('remote.origin.url').strip
      
      set(:url, origin_url) unless get(:url, false)
      
      if origin_url.empty?
        set_remote(:origin, url)
      end
    end
  end
 
  #---
  
  def set_remote(name, url)
    return super(name, url) do
      git.remote({}, 'add', name.to_s, url)
    end
  end
  
  #---
  
  def add_remote_url(name, url, options = {})
    return super(name, url, options) do |config|
      git.remote({
        :add    => true,
        :delete => config.get(:delete, false),
        :push   => config.get(:push, false)
      }, 'set-url', name.to_s, url)
    end
  end
  
  #---
  
  def delete_remote(name)
    return super(name) do
      git.remote({}, 'rm', name.to_s)
    end
  end
  
  #---
    
  def syncronize(cloud, options = {})
    return super(cloud, options) do |config|
      config.init(:remote_path, '/var/git')
      config.set(:add, true)
    end
  end
   
  #-----------------------------------------------------------------------------
  # SSH operations
 
  def pull!(remote = :origin, options = {})
    return super(remote, options) do |config|
      success = Coral.command({
        :command => :git,
        :data    => { 'git-dir=' => git.git_dir },
        :subcommand => {
          :command => :pull,
          :flags   => ( config.get(:tags, true) ? :tags : '' ),
          :args    => [ remote, config.get(:revision, get(:revision, :master)) ]
        }
      }, config.get(:provider, :shell)).exec!(config) do |line|
        block_given? ? yield(line) : true
      end    
    end
  end
  
  #---
    
  def push!(remote = :edit, options = {})
    return super(remote, options) do |config|
      push_branch = config.get(:revision, '')
      
      success = Coral.command({
        :command => :git,
        :data => { 'git-dir=' => git.git_dir },
        :subcommand => {
          :command => :push,
          :flags => [ ( push_branch.empty? ? :all : '' ), ( config.get(:tags, true) ? :tags : '' ) ],
          :args => [ remote, push_branch ]
        }
      }, config.get(:provider, :shell)).exec!(config) do |line|
        block_given? ? yield(line) : true
      end
    end
  end
 
  #-----------------------------------------------------------------------------
  # Utilities
  
  def translate_url(host, path, options = {})
    return super(host, path, options) do |config|
      user = config.get(:user, 'git')
      auth = config.get(:auth, true)
      
      user + (auth ? '@' : '://') + host + (auth ? ':' : '/') + path
    end
  end
  
  #---
  
  def translate_edit_url(url, options = {})
    return super(url, options) do |config|    
      if matches = url.strip.match(/^(https?|git)\:\/\/([^\/]+)\/(.+)/)
        protocol, host, path = matches.captures
        translate_url(host, path, config.import({ :auth => true }))
      end
    end
  end
end
end
end
