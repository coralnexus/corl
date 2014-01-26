
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
      if directory.empty?
        logger.warn("Can not manage Git project at #{directory} as it does not exist")  
      else
        logger.debug("Ensuring Git instance to manage #{directory}")
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
  
  #---
  
  def new?(reset = false)
    if get(:new, nil).nil? || reset
      set(:new, git.native(:rev_parse, { :all => true }).empty?)  
    end
    get(:new, false)
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
    super do
      ensure_git(true)
    end
    return self
  end
  
  #---
  
  def config(name, options = {})
    return super do |config|
      git.config(config.export, name)
    end
  end
  
  #---
  
  def set_config(name, value, options = {})
    return super do |config|
      git.config(config.export, name, value)
    end
  end
  
  #---
  
  def delete_config(name, options = {})
    return super do |config|
      git.config(config.import({ :remove_section => true }).export, name)
    end
  end
  
  #---
 
  def subproject_config(options = {})
    return super do |config|
      result = {}
      
      if new?
        logger.debug("Project has no sub project configuration yet (has not been committed to)")  
      else
        commit = lib.commit(revision)
        blob   = commit.tree/'.gitmodules' unless commit.nil?
          
        if blob
          logger.debug("Houston, we have a Git blob!")
        
          lines   = blob.data.gsub(/\r\n?/, "\n" ).split("\n")
          current = nil

          lines.each do |line|
            if line =~ /^\[submodule "(.+)"\]$/
              current         = $1
              result[current] = {}
              result[current]['id'] = (commit.tree/current).id
            
              logger.debug("Reading: #{current}")
      
            elsif line =~ /^\t(\w+) = (.+)$/
              result[current][$1]   = $2
              result[current]['id'] = (commit.tree/$2).id if $1 == 'path'
            end
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
      if new?
        logger.debug("Project has no current revision yet (has not been committed to)")  
      else
        current_revision = git.native(:rev_parse, { :abbrev_ref => true }, 'HEAD').strip
      
        logger.debug("Current revision: #{current_revision}")
      
        set(:revision, current_revision) unless get(:revision, false)
      
        if get(:revision, '').empty?
          logger.debug("Setting revision to current revision")
          set(:revision, current_revision)
        end
      end
    end
  end
  
  #---
  
  def checkout(revision)
    return super do
      if new?
        logger.debug("Project can not be checked out (has not been committed to)")  
      else
        git.checkout({}, revision) unless lib.bare
      end  
    end
  end
  
  #---
  
  def commit(files = '.', options = {})
    return super do |config, time, user, message|
      begin
        git.reset({}, 'HEAD') # Clear the index so we get a clean commit
      
        files = array(files)
      
        logger.debug("Adding files to Git index")
        
        git.add({ :raise => true }, files)                  # Get all added and updated files
        git.add({ :update => true, :raise => true }, files) # Get all deleted files
        
        commit_options = {
          :raise       => true, 
          :m           => "#{time} by <#{user}> - #{message}",
          :allow_empty => config.get(:allow_empty, false) 
        }
        commit_options[:author] = config[:author] if config.get(:author, false)
    
        logger.debug("Composing commit options: #{commit_options.inspect}")
        git.commit(commit_options)
        
        new?(true)
        true
      rescue
        logger.warn("There was apparently a problem with the commit")
        false
      end
    end   
  end

  #-----------------------------------------------------------------------------
  # Subproject operations
 
  def load_subprojects(options = {})
    return super do |project_path, data|
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
      
      logger.debug("Deleting Git configurations for #{submodule_key}")
      delete_config(submodule_key)
      delete_config(submodule_key, { :file => '.gitmodules' })
      
      logger.debug("Cleaning Git index cache for #{path}")
      git.rm({ :cached => true }, path)
      
      logger.debug("Removing Git submodule directories")
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
      
      logger.debug("Original origin remote url: #{origin_url}")
      
      set(:url, origin_url) unless get(:url, false)
      
      if origin_url.empty?
        logger.debug("Setting origin remote url to #{url}")
        set_remote(:origin, url)
      end
    end
  end
 
  #---
  
  def set_remote(name, url)
    return super do
      git.remote({}, 'add', name.to_s, url)
    end
  end
  
  #---
  
  def add_remote_url(name, url, options = {})
    return super do |config|
      git.remote({
        :add    => true,
        :delete => config.get(:delete, false),
        :push   => config.get(:push, false)
      }, 'set-url', name.to_s, url)
    end
  end
  
  #---
  
  def delete_remote(name)
    return super do
      if config("remote.#{name}.url").empty?
        logger.debug("Project can not delete remote #{name} because it does not exist yet")  
      else
        git.remote({}, 'rm', name.to_s)
      end
    end
  end
  
  #---
    
  def syncronize(cloud, options = {})
    return super do |config|
      config.init(:remote_path, '/var/git')
      config.set(:add, true)
    end
  end
   
  #-----------------------------------------------------------------------------
  # SSH operations
 
  def pull!(remote = :origin, options = {})
    return super do |config|
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
      
      new?(true) if success
      success    
    end
  end
  
  #---
    
  def push!(remote = :edit, options = {})
    return super do |config|
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
    return super do |config|
      user = config.get(:user, 'git')
      auth = config.get(:auth, true)
      
      user + (auth ? '@' : '://') + host + (auth ? ':' : '/') + path
    end
  end
  
  #---
  
  def translate_edit_url(url, options = {})
    return super do |config|    
      if matches = url.strip.match(/^(https?|git)\:\/\/([^\/]+)\/(.+)/)
        protocol, host, path = matches.captures
        translate_url(host, path, config.import({ :auth => true }))
      end
    end
  end
end
end
end
