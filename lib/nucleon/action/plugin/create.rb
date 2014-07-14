
module Nucleon
module Action
module Plugin
class Create < CORL.plugin_class(:nucleon, :cloud_action)
   
  #-----------------------------------------------------------------------------
  # Info
  
  def self.describe
    super(:plugin, :create, 10)
  end
  
  #-----------------------------------------------------------------------------
  # Settings
  
  def strict?
    false # Allow extra settings
  end
  
  def configure
    super do
      codes :no_template_file, 
            :template_file_parse_failed, 
            :plugin_already_exists,
            :plugin_save_failed
      
      register_str :type, :action do |value|
        namespace  = nil
        components = value.to_s.split(':::')
        
        if components.size > 1
          namespace = components[0].to_sym
          value     = components[1]
        end
        value = value.to_sym
        
        Nucleon.namespaces.each do |plugin_namespace|
          if ! namespace || namespace == plugin_namespace
            if Nucleon.types(plugin_namespace).include?(value)
              @plugin_namespace = plugin_namespace
              @plugin_type      = value
            end
          end
        end
        @plugin_namespace ? true : false  
      end
      register_array :name, nil
      
      register_bool :save
      register_bool :interpolate, true
      
      register_directory :template_path
    end
  end
  
  #---
  
  def ignore
    node_ignore
  end
  
  def arguments
    [ :type, :name ]
  end
  
  #-----------------------------------------------------------------------------
  # Operations
   
  def execute
    super do |node|
      ensure_network(network) do
        require 'erubis'
        
        type = settings[:type].to_sym
        name = settings[:name]
        
        unless template_path = settings.delete(:template_path)
          template_path = File.join(File.dirname(__FILE__), 'template')  
        end
                
        templates = Dir.glob("#{template_path}/**/*.erb")
        template  = nil
        
        templates.each do |template_file|
          if template_file =~ /#{@plugin_namespace}\.#{@plugin_type}\.erb/
            template = template_file
          end
        end
        
        if template
          template_contents = Util::Disk.read(template)
          
          unless template_contents
            error('parse_failed', { :file => template })
            myself.status = code.template_file_parse_failed
            next      
          end
          template = template_contents
        end
        
        unless template
          error('no_template', { :file => "#{template_path}#{File::SEPARATOR}#{@plugin_namespace}.#{@plugin_type}.erb" })
          myself.status = code.no_template_file
          next    
        end
        
        save_path   = File.join(network.directory, 'lib', @plugin_namespace.to_s, @plugin_type.to_s)
        save_file   = File.join(save_path, name.join(File::SEPARATOR) + '.rb')
        plugin_file = nil
        
        if File.exists?(save_file)
          error('provider_exists', { :file => save_file })
          myself.status = code.plugin_already_exists
          next  
        end
        
        settings.import({
          :plugin_class  => name.pop,
          :plugin_groups => name
        })
        
        renderer = Erubis::Eruby.new(template)
        parse    = true
        
        while(parse)
          begin
            plugin_file = renderer.result(settings.export)
            parse       = false
        
          rescue NameError => error
            settings.set(error.name, nil)
            
          rescue => error
            raise error
          end
        end
        
        if settings.delete(:save)
          # Save template to file within network project
          save_directory = File.dirname(save_file)
          
          FileUtils.mkdir_p(save_directory)
          
          if Util::Disk.write(save_file, plugin_file)
            success('saved', { :file => save_file })
          else
            error('save_failed', { :file => save_file })
            myself.status = code.plugin_save_failed 
          end
        else
          info('plugin_file', { :file => blue(save_file) })
          # Render template ONLY (testing)
          if settings.delete(:interpolate)
            puts green(plugin_file)  
          else
            puts green(template)  
          end          
        end  
      end
    end
  end
end
end
end
end
