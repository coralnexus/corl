
module CORL
module Configuration
class File < CORL.plugin_class(:configuration)

  #-----------------------------------------------------------------------------
  # Configuration plugin interface
  
  def normalize(reload)
    super do        
      _set(:search, Config.new)
      _set(:router, Config.new)
    end
  end
  
  #--- 
  
  def self.finalize(file_name)
    proc do
      logger.debug("Finalizing file: #{file_name}")
      Util::Disk.close(file_name)
    end
  end
    
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers
  
  def search
    _get(:search)
  end
  
  #---
  
  def router
    _get(:router)
  end

  #-----------------------------------------------------------------------------
  
  def set_location(directory)
    super
    search_files if directory
  end
  
  #-----------------------------------------------------------------------------
  # Configuration loading / saving
    
  def load(options = {})
    super do |method_config, properties|
      
      generate_routes = lambda do |config_name, file_properties, parents = []|
        file_properties.each do |name, value|
          keys = [ parents, name ].flatten
          
          if value.is_a?(Hash) && ! value.empty?
            generate_routes.call(config_name, value, keys)
          else
            router.set(keys, config_name)  
          end
        end
      end
      
      if fetch_project(method_config)
        search.export.each do |config_name, info|
          provider = info[:provider]
          file     = info[:file]
        
          logger.info("Loading #{provider} translated source configuration from #{file}")
          
          parser = CORL.translator(method_config, provider)
          raw    = Util::Disk.read(file)    
        
          if parser && raw && ! raw.empty?
            logger.debug("Source configuration file contents: #{raw}")            
            file_properties = parser.parse(raw)
            
            generate_routes.call(config_name, file_properties)
            properties.import(file_properties)
          end         
        end
      end
    end
  end
   
  #---
  
  # properties[key...] = values
  #
  # to
  # 
  # file_data[config_name][key...] = config
  
  def separate    
    file_data        = Config.new
    default_provider = CORL.type_default(:translator)
    
    split_config = lambda do |properties, local_router, parents = []|
      properties.each do |name, value|
        next if name.to_sym == :nodes
        
        keys = [ parents, name ].flatten
        
        if value.is_a?(Hash) && ! value.empty?
          # Nested configurations
          if local_router.is_a?(Hash) && local_router.has_key?(name)
            # Router and configuration values are nested
            split_config.call(value, local_router[name], keys)
          else
            # Just configuration values are nested
            if local_router.is_a?(String)
              # We are down to a config_name router.  Inherit on down the line
              split_config.call(value, local_router, keys)
            else
              # Never encountered before
              config_name = nil
              
              config_name = select_largest(router.get(parents)) unless parents.empty?
              split_config.call(value, config_name, keys)  
            end  
          end
        else
          if local_router.is_a?(String)
            # Router is a config_name string
            file_data.set([ local_router, keys ].flatten, value)          
          elsif router.is_a?(Hash)
            # Router is a hash with sub options we have to pick from
            config_name = select_largest(local_router)
            file_data.set([ config_name, keys ].flatten, value)  
          else
            # Router is non existent
            if config_name = select_largest(router.export)
              # Pick largest router from top level
              file_data.set([ config_name, keys ].flatten, value)
            else
              # Resort to sane defaults
              config_name = "corl.#{default_provider}"
              file_data.set([ config_name, keys ].flatten, value)
            end      
          end
        end        
      end
    end
    
    if config.get(:nodes, false)
      config[:nodes].each do |provider, data|
        data.each do |name, info|
          file_data.set([ ::File.join('nodes', provider.to_s, "#{name}.#{default_provider}"), :nodes, provider, name ], info)  
        end
      end
    end    
    
    # Whew!  Glad that's over...
    split_config.call(Util::Data.subset(config.export, config.keys - [ :nodes ]), router.export)
    file_data     
  end
  protected :separate
  
  #---
    
  def save(options = {})
    super do |method_config|
      config_files = []
      success      = true
      
      separate.export.each do |config_name, router_data|
        info     = search[config_name]
        provider = info[:provider]
        file     = info[:file]
        
        if renderer = CORL.translator(method_config, provider)
          rendering = renderer.generate(router_data)
          
          if Util::Disk.write(file, rendering)
            config_files << config_name
          else
            success = false
          end
        else
          success = false
        end
        break unless success        
      end
      if success && ! config_files.empty?
        commit_files = [ config_files, method_config.get_array(:files) ].flatten
          
        logger.debug("Source configuration rendering: #{rendering}")        
        success = update_project(commit_files, method_config)
      end
      success
    end
  end
  
  #---
  
  def remove(options = {})
    super do |method_config|
      success      = true
      config_files = [] 
      search.each do |config_name, info|
        config_files << info[:file]
        success = false unless Util::Disk.delete(info[:file])
      end
      success = update_project(config_files, method_config) if success
      success
    end
  end
  
  #---
  
  def attach(type, name, data, options = {})
    super do |method_config|
      attach_path = Util::Disk.filename([ project.directory, type.to_s ])
      success     = true
      
      begin
        FileUtils.mkdir_p(attach_path) unless Dir.exists?(attach_path)
      
      rescue Exception => error
        alert(error.message)
        success = false
      end
      
      if success
        case method_config.get(:type, :source)
        when :source
          new_file = project.local_path(Util::Disk.filename([ attach_path, name ]))
          
          logger.debug("Attaching source data (length: #{data.length}) to configuration at #{attach_path}")        
          success = Util::Disk.write(new_file, data)
          
        when :file  
          file       = ::File.expand_path(data)
          attach_ext = ::File.basename(file)
          new_file   = project.local_path(Util::Disk.filename([ attach_path, "#{name}-#{attach_ext}" ])) 
              
          logger.debug("Attaching file #{file} to configuration at #{attach_path}")       
      
          begin
            FileUtils.mkdir_p(attach_path) unless Dir.exists?(attach_path)
            FileUtils.cp(file, new_file)
          
          rescue Exception => error
            alert(error.message)
            success = false
          end  
        end
      end
      if success && autosave
        logger.debug("Attaching data to project as #{new_file}")
        success = update_project(new_file, method_config)
      end
      success ? new_file : nil
    end
  end
  
  #---
  
  def delete_attachments(ids, options = {})
    super do |method_config|
      success = true
      files   = []
      
      array(ids).each do |id|
        file = ::File.join(project.directory, id.to_s)
        
        if Util::Disk.delete(file)
          files << file
        else
          success = false
        end
      end
      
      if success && autosave
        logger.debug("Removing attached data from project as #{files.join(', ')}")
        success = update_project(files, method_config)
      end
      success ? files : nil
    end
  end
  
  #-----------------------------------------------------------------------------
  # Utilities
   
  def search_files
    
    add_search_file = lambda do |config_name, file, provider, info|
      if Util::Disk.exists?(file)            
        search[config_name] = {
          :provider => provider,
          :info     => info,
          :file     => file
        }
        ObjectSpace.define_finalizer(myself, myself.class.finalize(file))
      else
        logger.info("Configuration file #{file} does not exist")   
      end  
    end
    
    if Util::Data.empty?(project.directory)
      logger.debug("Clearing configuration file information")      
      search.clear
    else
      translators = CORL.loaded_plugins(:translator)
      file_bases  = [ "corl", extension_collect(:base) ].flatten
      
      project.localize do
        translators.each do |provider, info|
          Dir.glob(::File.join('nodes', '**', "*.#{provider}")).each do |file|
            config_name = file
            file        = ::File.join(project.directory, file)
            
            add_search_file.call(config_name, file, provider, info)  
          end
        end
      end
      
      translators.each do |provider, info|
        file_bases.each do |file_base|
          config_name = "#{file_base}.#{provider}"
          file        = Util::Disk.filename([ project.directory, config_name ])
         
          add_search_file.call(config_name, file, provider, info)
        end
      end     
      logger.debug("Setting configuration file information to #{search.inspect}")
    end
    load(_export) if autoload
  end
  protected :search_files
  
  #---
  
  def fetch_project(options = {})
    config  = Config.ensure(options)
    success = true
    if remote = config.get(:remote, nil)
      logger.info("Pulling configuration updates from remote #{remote}")
      success = project.pull(remote, config) if config.get(:pull, true)   
    end
    success
  end
  protected :fetch_project
  
  #---
  
  def update_project(files = [], options = {})
    config  = Config.ensure(options)
    success = true
    
    commit_files = '.'
    commit_files = array(files).flatten unless files.empty?
          
    logger.info("Committing changes to configuration files")        
    success = project.commit(commit_files, config)
          
    if success && remote = config.get(:remote, nil)
      logger.info("Pushing configuration updates to remote #{remote}")
      success = project.pull(remote, config) if config.get(:pull, true)
      success = project.push(remote, config) if success && config.get(:push, true)      
    end
    success
  end
  protected :update_project
  
  #---
  
  def select_largest(router)
    return router unless router.is_a?(Hash)
    
    config_map = {}
    
    count_config_names = lambda do |data|
      data = data.export if data.is_a?(CORL::Config)
      data.each do |name, value|
        if value.is_a?(Hash)
          count_config_names.call(value)
        else
          config_map[value] = 0 unless config_map.has_key?(value)
          config_map[value] = config_map[value] + 1
        end
      end
    end
    
    config_name   = nil
    config_weight = nil
    
    count_config_names.call(router)
    config_map.each do |name, weight|
      if config_name.nil? || weight > config_weight
        config_name   = name
        config_weight = weight
      end  
    end
    config_name
  end
  protected :select_largest
end
end
end
