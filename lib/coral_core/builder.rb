
module Coral
class Builder < Configuration
 
  @@instances = {}
 
  #---
  
  def self.collection
    return @@instances
  end
  
  #-----------------------------------------------------------------------------
  # Constructor / Destructor
  
  def self.create(name, options = {})
    config = Config.ensure(options)
    return new(config.import({ :name => name })) 
  end
  
  #---
  
  def self.get(name, options = {}, reset = false)
    name = name.to_s
    if collection.has_key?(name)
      builder = collection[name]
      builder.reset(options) if reset
    else
      builder = new(options)
      builder.name = name
    end
    return builder
  end
  
  #---
 
  def self.[](name)
    if ! collection.has_key?(name) || ! collection[name]
      return new({ :name => name })
    end  
    return collection[name]  
  end
   
  #---
  
  def self.delete(name, options = {})
    config = Config.ensure(options)
    
    if collection.has_key?(name) && collection[name].is_a?(Coral::Builder)
      cloud = collection[name]
      super(cloud.directory, cloud.config_file, config)
      collection.delete(name)
    end  
  end
  
  #-----------------------------------------------------------------------------
  
  def initialize(options = {})
    config = Config.ensure(options)
    
    super(config)
    
    self.name       = config.get(:name, 'global')
    self.build_path = config.get(:build_path, 'build')
    
    @@instances[name] = self
  end
  
  #---
  
  def reset(options = {})
    config = Config.ensure(options)
    
    self.build_path = config[:build_path] if config[:build_path] 
  end
  
  #---
  
  def inspect
    "#<#{self.class}: #{name} (#{build_path})>"
  end
       
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers
  
  attr_reader :build_path
  attr_accessor :name

  #---
  
  def build_path=path
    @build_path = path
    build
  end
  
  #-----------------------------------------------------------------------------
  # > Resources
  
  def get_resource(name, type = :class, provider = :puppet)
    #provisioner = Coral.provisioner(provider)
    return get(name)
  end
  protected :get_resource
    
  #---

  def set_resource(name, info)
    # info = 'puppet::resource_name'
    #
    #   or
    #
    # info = {
    #   :class   => 'puppet::resource_name',
    #   :require => 'resource_id'
    # }
    success = set(name, info)
    build if success
    return success
  end
  protected :set_resource
  
  #-----------------------------------------------------------------------------
  # > Projects
  
  def get_project(name)
    return Project.instance(get(name))  
  end
  protected :get_project
  
  #---
  
  def set_project(name, info)
    # info = 'git://url/project.git'
    #
    #   or
    #
    # info = {
    #   :url      => 'git://url/project.git',
    #   :revision => 'version | revision | branch',
    #   :ssh      => true | false
    # }
    success = set(name, info)
    build if success
    return success  
  end
  protected :set_project
    
  #-----------------------------------------------------------------------------
  # > Libraries
  
  def libraries
    data    = get_hash(:libraries)
    results = {}
    
    data.each do |name, info|
      results[name] = library(name)    
    end
    return results
  end
  
  #---
  
  def library(name)
    return get_project([ :libraries, name ])
  end
    
  #---

  def set_library(name, info)
    return set_project([ :libraries, name ], info)
  end
  
  #---
  
  def delete_library(name)
    return delete([ :libraries, name ])
  end
  
  #-----------------------------------------------------------------------------
  # > Nodes
    
  def nodes
    data    = get_hash(:nodes)
    results = {}
    
    data.each do |name, info|
      results[name] = node(name)    
    end
    return results
  end
  
  #---
  
  def node(name)
    return get_resource([ :nodes, name ], :node)
  end
    
  #---

  def set_node(name, info = 'default')
    return set_resource([ :nodes, name ], info)
  end
  
  #---
  
  def delete_node(name)
    return delete([ :nodes, name ])
  end
    
  #-----------------------------------------------------------------------------
  # > Profiles
  
  def profiles
    data    = get_hash(:profiles)
    results = {}
    
    data.each do |name, info|
      results[name] = profile(name)    
    end
    return results
  end
  
  #---
  
  def profile(name)
    return get_resource([ :profiles, name ])
  end
    
  #---

  def set_profile(name, info)
    return set_resource([ :profiles, name ], info)
  end
  
  #---
  
  def delete_profile(name)
    return delete([ :profiles, name ])
  end
     
  #-----------------------------------------------------------------------------
  # > Modules
  
  def mods
    data    = get_hash(:modules)
    results = {}
    
    data.each do |name, info|
      results[name] = mod(name)    
    end
    return results 
  end
  
  #---
  
  def mod(name)
    return get_project([ :modules, name ])
  end
    
  #---

  def set_mod(name, info)
    return set_project([ :modules, name ], info)
  end
  
  #---
  
  def delete_mod(name)
    return delete([ :modules, name ])
  end
    
  #-----------------------------------------------------------------------------
  # > Configuration defaults
  
  def defaults
    data    = get_hash(:defaults)
    results = {}
    
    data.each do |name, info|
      results[name] = default(name)    
    end
    return results
  end
  
  #---
  
  def default(name)
    return get_resource([ :defaults, name ])
  end
    
  #---

  def set_default(name, info)
    return set_resource([ :defaults, name ], info)
  end
  
  #---
  
  def delete_default(name)
    return delete([ :defaults, name ])
  end
    
  #-----------------------------------------------------------------------------
  # > JSON configurations
  
  def configs
    data    = get_hash(:config)
    results = {}
    
    data.each do |name, info|
      results[name] = config(name)    
    end
    return results
  end
  
  #---
  
  def config(name)
    return get_project([ :config, name ])
  end
    
  #---

  def set_config(name, info)
    return set_project([ :config, name ], info)
  end
  
  #---
  
  def delete_config(name)
    return delete([ :config, name ])
  end
     
  #-----------------------------------------------------------------------------
  # Configuration loading / saving
    
  def load(options = {})
    super(options)
    return self
  end
  
  #-----------------------------------------------------------------------------
  # Project
  
  def info(type = nil, options = {})
    config = Config.ensure(options)
    
    puppet_template_url = config.get(:puppet_template_url, 'https://github.com/coralnexus/puppet-templates.git')
    
    project_info = {
      :library => {
        :default_url  => config.get(:library_default_url, 'https://github.com/coralnexus/cluster-lib-template.git'),
        :base_path    => config.get(:library_base_path, File.join(repo.directory, 'build', 'libraries'))  
      },
      :module => {
        :default_url  => config.get(:module_default_url, 'https://github.com/coralnexus/puppet-module-template.git'),
        :base_path    => config.get(:module_base_path, File.join(repo.directory, 'build', 'modules'))  
      },
      :config => {
        :base_path    => config.get(:config_base_path, File.join(repo.directory, 'build', 'config'))  
      },
      :default => {
        :default_url  => config.get(:default_default_url, puppet_template_url),
        :default_file => 'default.pp',
        :base_path    => config.get(:default_base_path, File.join(repo.directory, 'build', 'default'))  
      },
      :profile => {
        :default_url  => config.get(:profile_default_url, puppet_template_url),
        :default_file => 'profile.pp',
        :base_path    => config.get(:profile_base_path, File.join(repo.directory, 'build', 'profiles'))  
      },
      :node => {
        :default_url  => config.get(:node_default_url, puppet_template_url),
        :default_file => 'node.pp',
        :base_path    => config.get(:node_base_path, File.join(repo.directory, 'build', 'nodes'))  
      }      
    }
    
    project_info.each do |project_type, info|
        
    end
    
    return project_info unless type
    return project_info[type.to_sym]
  end
  
  #---
  
  def build
    build_path = File.join(repo.directory, build_path)
    
    dbg(libraries, 'libraries')
    dbg(nodes, 'nodes')
    dbg(profiles, 'profiles')
    dbg(mods, 'modules')
    
    dbg(defaults, 'defaults')
    dbg(configs, 'configs')
    
    
    
    
    
    
    
    
    
    
    
    
    return true
  end
  
  #---
  
  def add(name, type = :module, options = {})
    #config = Config.ensure(options)
     
    #info = project_info(type, config)
    #path = File.join(info[:base_path], Util::Disk.filename(name))
    #url  = config.get(:repo, info[:default_url])
    
    #return repo.add_submodule(path, url, config.get(:branch, 'master'))  
  end
  
  #---
  
  def delete(name, type, options = {})
    #config = Config.ensure(options)
    
    #info = project_info(type, config)
    #path = File.join(info[:base_path], Util::Disk.filename(name))
    
    #return repo.delete_submodule(path)
  end
  
  #-----------------------------------------------------------------------------
  # Utilities

end
end