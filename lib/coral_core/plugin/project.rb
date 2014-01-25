
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
      logger.info("Creating new project at #{directory} with #{provider}")
      
      return Coral.project(config.import({
        :name      => directory,
        :directory => directory
      }), provider)
      
    else
      logger.info("Opening existing project at #{directory}")  
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
      url = url.strip
      
      logger.info("Setting project #{name} url to #{url}")
      
      set(:url, url)
      set_remote(:origin, url)
    end
    return self
  end

  #---
  
  def edit_url(default = nil)
    return get(:edit, default)
  end
  
  #---
  
  def set_edit_url(url)
    if url
      url = url.strip
      
      logger.info("Setting project #{name} edit url to #{url}")
      
      set(:edit, url)
      set_remote(:edit, url)
    end
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
    current_directory = get(:directory)
    
    logger.info("Setting project #{name} directory to #{current_directory}")
    @@projects[current_directory] = self
    
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
    
    logger.info("Setting project #{self.name} configuration: #{name} = #{value.inspect}")
    
    yield(config) if can_persist? && block_given?
    return self
  end
  
  #---
  
  def delete_config(name, options = {})
    config = Config.ensure(options) # Just in case we throw a configuration in
    
    logger.info("Removing project #{self.name} configuration: #{name}")
    
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
    
    logger.debug("Subproject configuration: #{result.inspect}")
    return result
  end
  protected :subproject_config

  #-----------------------------------------------------------------------------
  # Project operations
  
  def init_parent
    delete(:parent)
    
    logger.info("Initializing project #{name} parents")
        
    if top?(directory)
      logger.debug("Project #{name} has no parents to initialize")
    else
      search_dir = directory
      
      while File.directory?((search_dir = File.expand_path('..', search_dir)))
        logger.debug("Scanning directory #{search_dir} for parent project")
        
        if project_directory?(search_dir)
          logger.debug("Directory #{search_dir} is a valid parent for this #{plugin_provider} project")
          
          set(:parent, self.class.open(search_dir, plugin_provider))
          logger.debug("Setting parent to #{parent.inspect}")
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
      logger.info("Loading project #{name} revision")
      
      yield if block_given?      
      logger.debug("Loaded revision: #{revision}")
      
      load_subprojects
    else
      logger.warn("Project #{name} does not meet the criteria for persistence and has no revision")
    end
    return self
  end
  protected :load_revision
  
  #---
  
  def checkout(revision)
    if can_persist?
      logger.info("Checking out project #{name} revision: #{revision}")
      
      yield if block_given?
      set(:revision, revision)
      
      load_subprojects
    else
      logger.warn("Project #{name} does not meet the criteria for persistence and can not checkout a revision")
    end
    return self 
  end
  
  #---
  
  def commit(files = '.', options = {})
    config = Config.ensure(options)
    
    if can_persist?
      logger.info("Committing changes to project #{name}: #{files.inspect}")
      
      time     = Time.new.strftime("%Y-%m-%d %H:%M:%S")
      user     = ENV['USER']
      
      message  = config.get(:message, '')
      message  = 'Saving state: ' + ( files.is_a?(Array) ? "\n\n" + files.join("\n") : files.to_s ) if message.empty?
      
      user = 'UNKNOWN' unless user && ! user.empty?
      
      logger.debug("Commit by #{user} at #{time} with #{message}")
      
      yield(config, time, user, message) if block_given?
      
      if ! parent.nil? && config.get(:propogate, true)
        logger.debug("Commit to parent as parent exists and propogate option given")
        
        parent.commit(directory, config.import({
          :message => "Updating subproject #{path} with: #{message}"
        }))
      end
    else
      logger.warn("Project #{name} does not meet the criteria for persistence and can be committed to")                
    end
    return self      
  end

  #-----------------------------------------------------------------------------
  # Subproject operations
 
  def load_subprojects(options = {})
    config      = Config.ensure(options)
    subprojects = {}
    
    if can_persist?
      logger.info("Loading sub projects for project #{name}")
      
      subproject_config(config).each do |path, data|
        project_path = File.join(directory, path)
        
        if File.directory?(project_path)
          logger.debug("Checking if project path #{project_path} is a valid sub project")
           
          add_project = true
          add_project = yield(project_path, data) if block_given?
          
          if add_project
            logger.debug("Directory #{project_path} is a valid sub project for this #{plugin_provider} project")
            
            project = self.class.open(project_path, plugin_provider)
            subprojects[path] = project
          else
            logger.warn("Directory #{project_path} is not a valid sub project for this #{plugin_provider} project")   
          end
        else
          logger.warn("Sub project configuration points to a location that is not a directory: #{project_path}")  
        end
      end
    else
      logger.warn("Project #{name} does not meet the criteria for persistence and can not have sub projects")    
    end
    set(:subprojects, subprojects)
    return self  
  end
  protected :load_subprojects
  
  #---
  
  def add_subproject(path, url, revision, options = {})
    success = true
    if can_persist?
      logger.info("Adding a sub project to #{path} from #{url} at #{revision}")
      
      success = yield if block_given?
      update_subprojects if success
    else
      logger.warn("Project #{name} does not meet the criteria for persistence and can not have sub projects")   
    end
    return success
  end
  
  #---
  
  def delete_subproject(path)
    success = true
    if can_persist?
      logger.info("Deleting a sub project at #{path}")
      
      success = yield if block_given?  
      update_subprojects if success
    else
      logger.warn("Project #{name} does not meet the criteria for persistence and can not have sub projects") 
    end
    return success
  end
 
  #---
   
  def update_subprojects
    if can_persist?
      logger.info("Updating sub projects in project #{name}")
      
      yield if block_given?
      load_subprojects
    else
      logger.warn("Project #{name} does not meet the criteria for persistence and can not have sub projects") 
    end
    return self
  end
  protected :update_subprojects
  
  #---
  
  def foreach!
    if can_persist?
      logger.info("Iterating through all sub projects of project #{name}")
      
      subprojects.each do |path, project|
        logger.debug("Running process on sub project #{path}")
        yield(path, project)  
      end
    else
      logger.warn("Project #{name} does not meet the criteria for persistence and can not have sub projects") 
    end
    return self
  end 
         
  #-----------------------------------------------------------------------------
  # Remote operations
  
  def init_remotes
    logger.info("Initializing project #{name} remotes")
    
    yield if block_given?
    set_edit_url(translate_edit_url(url))
    return self 
  end
  protected :init_remotes
 
  #---
  
  def set_remote(name, url)
    if can_persist?
      delete_remote(name)
    
      logger.info("Setting project remote #{name} to #{url}")
      yield if block_given?
    else
      logger.warn("Project #{self.name} does not meet the criteria for persistence and can not have remotes") 
    end
    return self
  end
  
  #---
  
  def add_remote_url(name, url, options = {})
    if can_persist?
      config = Config.ensure(options)
      
      logger.info("Adding project remote url #{url} to #{name}")    
      yield(config) if block_given?
    else
      logger.warn("Project #{self.name} does not meet the criteria for persistence and can not have remotes") 
    end
    return self  
  end
  
  #---
    
  def set_host_remote(name, hosts, path, options = {})
    config = Config.ensure(options)
    
    if can_persist?
      hosts = array(hosts)
      return self if hosts.empty?
      
      logger.info("Setting host remote #{name} for #{hosts.inspect} at #{path}") 
      
      set_remote(name, translate_url(hosts.shift, path, config.export))
      
      unless hosts.empty?
        hosts.each do |host|
          logger.debug("Adding remote url to #{host}")
          add_remote_url(name, translate_url(host, path, config.export), config)
        end
      end
    else
      logger.warn("Project #{self.name} does not meet the criteria for persistence and can not have remotes") 
    end
    return self
  end
  
  #---
  
  def delete_remote(name)
    if can_persist?
      logger.info("Deleting project remote #{name}")  
      yield if block_given?
    else
      logger.warn("Project #{self.name} does not meet the criteria for persistence and can not have remotes") 
    end
    return self  
  end
  
  #---
    
  def syncronize(network, options = {})
    config = Config.ensure(options)
    yield(config) if block_given?
    
    if can_persist?
      remote_path  = config.delete(:remote_path, '/var/coral')
      server_hosts = []
      
      logger.info("Syncronizing network remotes for project #{name} remote path: #{remote_path}") 
        
      network.nodes.each do |provider, nodes|
        logger.debug("Iterating over nodes of provider #{provider}")
        
        nodes.each do |node_name, node|
          logger.debug("Syncronizing node #{node_name} with hostname: #{node.hostname}")
          
          node_hosts << node.hostname          
          set_host_remote(node_name, node.hostname, remote_path, config)
        end
      end
      
      logger.debug("Setting 'all' remote to bridge hosts: #{node_hosts.inspect}")
      set_host_remote('all', node_hosts, remote_path, config) unless node_hosts.empty?
    else
      logger.warn("Project #{name} does not meet the criteria for persistence and can not have remotes") 
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
      
      logger.info("Pulling from #{remote} into #{directory}") 
      
      success = yield(config) if block_given?
      
      update_subprojects
      
      if success && ! parent.nil? && config.get(:propogate, true)
        logger.debug("Commit to parent as parent exists and propogate option was given")
        
        parent.commit(directory, config.import({
          :message     => "Pulling updates for subproject #{path}",
          :allow_empty => true
        }))
      end
      
      Dir.chdir(prev_dir)
    else
      logger.warn("Project #{name} does not meet the criteria for persistence and can not pull from remotes")       
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
      
      logger.info("Pushing to #{remote} from #{directory}") 
      
      success = yield(config) if block_given?
      
      config.delete(:revision)
      
      if success && config.get(:propogate, true)
        logger.debug("Pushing sub projects as propogate option was given")
        
        foreach! do |path, project|
          project.push!(remote, config)
        end
      end
      
      Dir.chdir(prev_dir)
    else
      logger.warn("Project #{name} does not meet the criteria for persistence and can not push to remotes") 
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
    options = super(data)
    
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
        
        logger.debug("Translating project options: #{options.inspect}")  
      end
    end
    return options
  end
  
  #---
  
  def self.translate_reference(reference, editable = false)
    # ex: github:::coralnexus/puppet-coral[0.2]
    if reference && reference.match(/^\s*([a-zA-Z0-9_-]+):::([^\]\s]+)\s*(?:\[\s*([^\]\s]+)\s*\])?\s*$/)
      provider = $1
      url      = $2
      revision = $3
      
      logger.debug("Translating project reference: #{provider}  #{url}  #{revision}")
      
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
      
      logger.debug("Project reference info: #{info.inspect}")
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
