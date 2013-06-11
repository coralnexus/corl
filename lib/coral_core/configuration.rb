
module Coral
class Configuration < Core
  
  @@configurations = {}
  
  #---
  
  def self.collection(directory = nil)
    return @@configurations[directory] unless directory.nil?
    return @@configurations
  end
   
  #-----------------------------------------------------------------------------
  # Constructor / Destructor
 
  def self.open(directory, config_file, properties = {}, options = {})
    config = Config.ensure(options)
    
    directory_exists = @@configurations.has_key?(directory)
    config_exists    = (directory_exists && @@configurations[directory].has_key?(config_file))
    
    if ! config_exists || config.get(:reset, false)    
      @@configurations[directory] = {} unless directory_exists
      
      return new(config.import({
        :directory   => directory,
        :config_file => config_file,
        :properties  => properties
      }))
    end
    return @@configurations[directory][config_file]
  end
  
  #---
  
  def self.delete(directory, config_file, options = {})
    config = Config.ensure(options)
    
    directory_exists = @@configurations.has_key?(directory)
    config_exists    = (directory_exists && @@configurations[directory].has_key?(config_file))
    
    if config_exists
      @@configurations[directory][config_file].delete(config)
      @@configurations[directory].delete(config_file)
    end  
  end

  #-----------------------------------------------------------------------------
  
  def initialize(options = {})
    config = Config.ensure(options)
    
    super(config)
    
    @repo = Repository.open(config.get(:directory, Dir.pwd), config)
    
    @absolute_config_file = ''
    @config_file          = ''
    
    @properties     = hash(config.get(:properties, {}))
    
    @autoload       = config.get(:autoload, true)
    @autosave       = config.get(:autosave, true)
    @autocommit     = config.get(:autocommit, true)
    @commit_message = config.get(:commit_message, 'Saving state')
    
    self.config_file = config.get(:config_file, '')
    
    @@configurations[repo.directory][config_file] = self
  end
  
  #---
  
  def self.finalize(file_name)
    proc do
      Util::Disk.close(file_name)
    end
  end
     
  #-----------------------------------------------------------------------------
  # Checks
  
  def can_persist?
    success = repo.can_persist?
    success = false if Util::Data.empty?(@absolute_config_file)
    return success
  end
      
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers
  
  attr_accessor :autoload, :autosave, :autocommit, :commit_message
  attr_reader :repo, :config_file, :absolute_config_file
   
  #---
  
  def config_file=file
    unless Util::Data.empty?(file)
      @config_file = Util::Disk.filename(file)
    end
    
    set_absolute_config_file
    load if autoload
  end

  #---
 
  def set_absolute_config_file
    if Util::Data.empty?(repo.directory) || Util::Data.empty?(@config_file)
      @absolute_config_file = ''
    else 
      @absolute_config_file = File.join(repo.directory, @config_file)
      ObjectSpace.define_finalizer(self, self.class.finalize(@absolute_config_file))
    end
    return self
  end
  protected :set_absolute_config_file
  
  #-----------------------------------------------------------------------------
  
  def fetch(data, keys, default = nil, format = false)    
    if keys.is_a?(String) || keys.is_a?(Symbol)
      keys = [ string(keys) ]
    end    
    key = string(keys.shift)
    
    if data.has_key?(key)
      value = data[key]
      
      if keys.empty?
        return filter(value, format)
      else
        return fetch(data[key], keys, default, format)  
      end
    end
    return filter(default, format)
  end
  protected :fetch
  
  #---
  
  def modify(data, keys, value = nil)    
    if keys.is_a?(String) || keys.is_a?(Symbol)
      keys = [ string(keys) ]
    end    
    key = string(keys.shift)
    
    if keys.empty?
      if value.nil?
        data.delete(key) if data.has_key?(key)
      else
        data[key] = value
      end
    else
      unless data.has_key?(key)
        data[key] = {}
      end
      modify(data[key], keys, value)  
    end
  end
  protected :modify
  
  #---
  
  def get(keys, default = nil, format = false)
    return fetch(@properties, keys, default, format)
  end
  
  #---
  
  def set(keys, value = '', options = {})
    config = Config.ensure(options) 
    modify(@properties, keys, value)
    save(config) if autosave
    return self
  end
  
  #---
  
  def delete(keys, options = {})
    config = Config.ensure(options) 
    modify(@properties, keys, nil)
    save(config) if autosave
    return self
  end
  
  #---
  
  def clear(options = {})
    config      = Config.ensure(options)    
    @properties = {}
    save(config) if autosave
    return self
  end

  #-----------------------------------------------------------------------------
  # Import / Export
  
  def import(properties, options = {})
    config      = Config.ensure(options)
    @properties = Util::Data.merge([ @properties, properties ].flatten, config)
    save(config) if autosave
    return self
  end
  
  #---
  
  def export
    return @properties
  end
       
  #-----------------------------------------------------------------------------
  # Configuration loading / saving
    
  def load(options = {})
    config = Config.ensure(options)
    
    if can_persist? && File.exists?(@absolute_config_file)
      json_text = Util::Disk.read(@absolute_config_file)    
      if json_text && ! json_text.empty?
        if config.get(:override, false)
          @properties = MultiJson.load(json_text)
        else
          @properties = Util::Data.merge([ @properties, MultiJson.load(json_text) ], config)
        end
      end
    end
    return self
  end
   
  #---
    
  def save(options = {})
    config = Config.ensure(options)
    
    if can_persist?
      json_text = MultiJson.dump(@properties, :pretty => true)
      if json_text && ! json_text.empty?
        Util::Disk.write(@absolute_config_file, json_text)
        repo.commit(@absolute_config_file, config) if autocommit
      end
    end
    return self
  end
  
  #---
  
  def delete(options = {})
    config = Config.ensure(options)
    
    if can_persist?
      @properties = {}
      File.delete(@absolute_config_file)
      repo.commit(@absolute_config_file, config) if autocommit
    end  
  end
  
  #-----------------------------------------------------------------------------
  # Utilities
  
  def parse(statement, options = {})
    config = Config.ensure(options)
    
    # statement = 'common->php::apache::memory_limit = 32M'
    # statement = 'identity -> test -> users::user[admin][shell]'
    # statement = 'servers->development->dev.loc->facts[server_environment]=vagrant'
    # statement = 'cloud->settings[debug][puppet][options] = ["--debug"]'
    
    reference, new_value = statement.split(/\=/)
    new_value            = new_value.join('=').strip if new_value && new_value.is_a?(Array)
    
    config_elements = reference.gsub(/\s+/, '').split(/\-\>/)
    property        = config_elements.pop
    config_file     = config_elements.pop
    
    if config_directory = config.get(:directory, nil)
      config_path = File.join(repo.directory, config_directory, *config_elements)
    else
      config_path = File.join(repo.directory, *config_elements)
    end
    
    return nil unless property && config_file
    
    config_file = "#{config_file}." + config.get(:ext, 'json')
    property    = property.gsub(/\]$/, '').split(/\]?\[/)
    data        = open(config_path, config_file, config)
       
    return { 
      :path          => config_path, 
      :file          => config_file, 
      :property      => property,
      :conf          => data,
      :current_value => (data ? data.get(property) : nil), 
      :new_value     => eval(new_value) 
    }    
  end
end
end
