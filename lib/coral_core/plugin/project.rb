
module Coral
module Plugin
class Project < Base
  
  @@projects = {}
  
  #---
  
  def self.collection
    return @@projects
  end
     
  #-----------------------------------------------------------------------------
  # Constructor / Destructor
  
  def self.open(directory, provider, options = {})
    config = Config.ensure(options)
    
    directory = File.expand_path(Util::Disk.filename(directory))
    
    if ! @@projects.has_key?(directory) || config.get(:reset, false)
      return Coral.project(config.import({
        :name      => directory,
        :directory => directory
      }), provider)
    end
    return @@projects[directory]
  end
 
  #-----------------------------------------------------------------------------
  # Project plugin interface
   
  def normalize
    super
    
    set_url(get(:url)) if get(:url, false)    
    set_location(Util::Disk.filename(get(:directory, Dir.pwd)))
    
    self.name = path
    
    checkout(get(:revision))
    
    pull if get(:pull, false)
  end
   
  #-----------------------------------------------------------------------------
  # Plugin operations
  
  def register
    super
    # TODO: Scan project directory looking for plugins
  end
        
  #-----------------------------------------------------------------------------
  # Checks
   
  def can_persist?
    return top?(directory) if directory
    return false
  end
 
  #---
          
  def top?(path)
    return true if File.directory?(path)
    return false
  end
    
  #---
          
  def subproject?(path)
    return false
  end

  #---
      
  def project_directory?(path, require_top_level = false)
    path = File.expand_path(path)    
    return true if File.directory?(path) && (! require_top_level || top?(path))
    return false
  end
  protected :project_directory?
   
  #-----------------------------------------------------------------------------
  # Property accessor / modifiers
  
  def url(default = nil)
    return get(:url, default)
  end

  #---
  
  def set_url(url)
    if url
      set(:url, url)
      set_remote(:origin, url.strip)
    end
    return self
  end

  #---
  
  def edit_url(default = nil)
    return get(:edit, default)
  end
  
  #---
  
  def set_edit_url(url)
    set(:edit, url)
    set_remote(:edit, url.strip)
    return self
  end
 
  #---
  
  def directory(default = nil)
    return get(:directory, default)
  end
   
  #---
  
  def path
    if parent.nil?
      return directory  
    end
    return directory.gsub(parent.directory + File::SEPARATOR, '')
  end
  
  #---
   
  def set_location(directory)
    @@projects.delete(get(:directory)) if get(:directory)
    
    if Util::Data.empty?(directory)
      set(:directory, Dir.pwd)
    else
      set(:directory, File.expand_path(Util::Disk.filename(directory)))
    end
    @@projects[get(:directory)] = self
    
    yield if block_given?
    
    init_parent
    init_remotes    
    load_revision
       
    return self
  end
  
  #---
  
  def parent(default = nil)
    return get(:parent, default)
  end

  #---
  
  def subprojects(default = nil)
    return get(:subprojects, default)
  end

  #---
  
  def revision(default = nil)
    return get(:revision, default).to_s
  end
  
  #---
  
  def config(name, options = {})
    config = Config.ensure(options) # Just in case we throw a configuration in
    return yield(config) if can_persist? && block_given?
    return nil
  end
  
  #---
  
  def set_config(name, value, options = {})
    config = Config.ensure(options) # Just in case we throw a configuration in
    yield(config) if can_persist? && block_given?
    return self
  end
  
  #---
  
  def delete_config(name, options = {})
    config = Config.ensure(options) # Just in case we throw a configuration in
    yield(config) if can_persist? && block_given?
    return self
  end
  
  #---
 
  def subproject_config(options = {})
    config = Config.ensure(options)
    result = {}
    if can_persist?
      result = yield(config) if block_given?
    end
    return result
  end
  protected :subproject_config

  #-----------------------------------------------------------------------------
  # Project operations
  
  def init_parent
    delete(:parent)
        
    unless top?(directory)
      search_dir = directory
      
      while File.directory?((search_dir = File.expand_path('..', search_dir)))
        if project_directory?(search_dir)
          set(:parent, self.class.open(search_dir, plugin_provider))
          break;
        end        
      end      
    end
    return self       
  end
  protected :init_parent

  #---
 
  def load_revision
    if can_persist?
      yield if block_given?
      load_subprojects
    end
    return self
  end
  protected :load_revision
  
  #---
  
  def checkout(revision)
    if can_persist?
      yield if block_given?
      set(:revision, revision)
      load_subprojects
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
      
      yield(config, time, user, message) if block_given?
      
      if ! parent.nil? && config.get(:propogate, true)
        parent.commit(directory, config.import({
          :message => "Updating subproject #{path} with: #{message}"
        }))
      end                
    end
    return self      
  end

  #-----------------------------------------------------------------------------
  # Subproject operations
 
  def load_subprojects(options = {})
    config      = Config.ensure(options)
    subprojects = {}
    
    if can_persist?
      subproject_config(config).each do |path, data|
        project_path = File.join(directory, path)
        
        if File.directory?(project_path) 
          add_project = true
          add_project = yield(project_path, data) if block_given?
          
          if add_project
            project = self.class.open(project_path, plugin_provider)
            subprojects[path] = project
          end
        end
      end
    end
    set(:subprojects, subprojects)
    return self  
  end
  protected :load_subprojects
  
  #---
  
  def add_subproject(path, url, revision, options = {})
    success = true
    if can_persist?
      success = yield if block_given?      
      update_subprojects if success
    end
    return success
  end
  
  #---
  
  def delete_subproject(path)
    success = true
    if can_persist?
      success = yield if block_given?  
      update_subprojects if success
    end
    return success
  end
 
  #---
   
  def update_subprojects
    yield if can_persist? && block_given?
    load_subprojects
    return self
  end
  protected :update_subprojects
  
  #---
  
  def foreach!
    if can_persist?
      subprojects.each do |path, project|
        yield(path, project)  
      end
    end
    return self
  end 
         
  #-----------------------------------------------------------------------------
  # Remote operations
  
  def init_remotes
    yield if block_given?
    set_edit_url(translate_edit_url(url))
    return self 
  end
  protected :init_remotes
 
  #---
  
  def set_remote(name, url)
    delete_remote(name)
    yield if can_persist? && block_given?
    return self
  end
  
  #---
  
  def add_remote_url(name, url, options = {})
    config = Config.ensure(options)    
    yield(config) if can_persist? && block_given?
    return self  
  end
  
  #---
    
  def set_host_remote(name, hosts, path, options = {})
    config = Config.ensure(options)
    
    if can_persist?
      hosts = array(hosts)
      
      return self if hosts.empty?
      
      set_remote(name, translate_url(hosts.shift, path, config.export))
      
      unless hosts.empty?
        hosts.each do |host|
          add_remote_url(name, translate_url(host, path, config.export), config)
        end
      end
    end
    return self
  end
  
  #---
  
  def delete_remote(name)
    yield if can_persist? && block_given?
    return self  
  end
  
  #---
    
  def syncronize(cloud, options = {})
    config = Config.ensure(options)
    yield(config) if block_given?
    
    if can_persist?
      remote_path  = config.delete(:remote_path, '/var/coral')
      server_hosts = []
        
      #cloud.servers.each do |server_name, server|
      #  server_hosts << server.hostname          
      #  set_host_remote(server_name, server.hostname, remote_path, config)
      #end
      #set_host_remote('all', server_hosts, remote_path, config) unless server_hosts.empty?
    end
    return true
  end
   
  #-----------------------------------------------------------------------------
  # SSH operations
 
  def pull!(remote = :origin, options = {})
    config  = Config.ensure(options)
    success = false
    
    if can_persist?
      prev_dir = Dir.pwd      
      Dir.chdir(directory)
      
      success = yield(config) if block_given?
      
      update_subprojects
      
      if success && ! parent.nil? && config.get(:propogate, true)
        parent.commit(directory, config.import({
          :message     => "Pulling updates for subproject #{path}",
          :allow_empty => true
        }))
      end
      
      Dir.chdir(prev_dir)      
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
      prev_dir = Dir.pwd      
      Dir.chdir(directory)
      
      success = yield(config) if block_given?
      
      config.delete(:revision)
      
      if success && config.get(:propogate, true)
        foreach! do |path, project|
          project.push!(remote, config)
        end
      end
      
      Dir.chdir(prev_dir)
    end
    return success
  end
  
  #---
  
  def push(remote = :edit, options = {})
    return push!(remote, options)
  end
    
  #-----------------------------------------------------------------------------
  # Utilities
  
  def self.build_info(type, data)  
    data = data.split(/\s*,\s*/) if data.is_a?(String)
    return super(type, data)
  end
  
  #---
   
  def self.translate(data)
    options = {}
    
    case data        
    when String
      options = { :url => data }
    when Hash
      options = data
    end
    
    if options.has_key?(:url)
      if matches = translate_reference(options[:url])
        options[:provider] = matches[:provider]
        options[:url]      = matches[:reference]
        options[:revision] = matches[:revision] unless options.has_key?(:revision)  
      end
    end
    return options
  end
  
  #---
  
  def self.translate_reference(reference, editable = false)
    # ex: github:::coralnexus/puppet-coral[0.3]
    if reference && reference.match(/^\s*([a-zA-Z0-9_-]+):::([^\]\s]+)\s*(?:\[\s*([^\]\s]+)\s*\])?\s*$/)
      provider = $1
      url      = $2
      revision = $3
      
      if provider
        klass        = Coral.class_const([ :coral, :project, provider ])          
        expanded_url = klass.send(:expand_url, url, editable) if klass.respond_to?(:expand_url)
      end
      expanded_url = url unless expanded_url
      
      info = {
        :provider  => provider,
        :reference => url,
        :url       => expanded_url,
        :revision  => revision
      }
      return info
    end
    return nil
  end
  
  #---
  
  def translate_reference(reference, editable = false)
    return self.class.translate_reference(reference, editable)
  end
  
  #---
  
  def translate_url(host, path, options = {})
    config = Config.ensure(options)
    url    = "#{host}/#{path}"
    
    if block_given?
      temp_url = yield(config)
      url      = temp_url if temp_url
    end
    return url
  end
  
  #---
  
  def translate_edit_url(url, options = {})
    config = Config.ensure(options)
    
    if block_given?
      temp_url = yield(config)
      url      = temp_url if temp_url
    end
    return url
  end
end
end
end
