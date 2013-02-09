
module Coral
module Util
class Disk < Core
  
  #-----------------------------------------------------------------------------
  # Properties
 
  @@files = {}
  
  @@separator   = false
  @@description = ''
  
  #-----------------------------------------------------------------------------
  # Utilities
  
  def self.open(file_name, options = {}, reset = false)
    mode          = string(options[:mode])
    
    @@separator   = ( options[:separator] ? options[:separator] : false )
    @@description = ( options[:description] ? options[:description] : '' )
    
    if @@files.has_key?(file_name) && ! reset
      reset = true if ! mode.empty? && mode != @@files[file_name][:mode]
    end
    
    if ! @@files.has_key?(file_name) || ! @@files[file_name][:file] || reset
      @@files[file_name][:file].close if @@files[file_name] && @@files[file_name][:file]
      unless mode.empty? || ( mode == 'r' && ! File.exists?(file_name) )
        @@files[file_name] = {
          :file => File.open(file_name, mode),
          :mode => mode,
        }
      end
    end
    return nil unless @@files[file_name]
    return @@files[file_name][:file]
  end
  
  #---
  
  def self.read(file_name, options = {})
    options[:mode] = ( options[:mode] ? options[:mode] : 'r' )
    file           = open(file_name, options)
    
    if file
      return file.read
    end
    return nil
  end
  
  #---
  
  def self.write(file_name, data, options = {})
    options[:mode] = ( options[:mode] ? options[:mode] : 'w' )
    file           = open(file_name, options)
    
    if file
      return file.write(data)
    end
    return nil
  end
  
  #---
  
  def self.log(data, options = {})
    reset = ( options[:file_name] || options[:mode] )
    file  = open(( options[:file_name] ? options[:file_name] : 'log.txt' ), options, reset)    
    if file      
      file.write("--------------------------------------\n") if @@separator
      file.write("#{@@description}\n") if @@description       
      file.write("#{data}\n")
    end
  end
  
  #---
  
  def self.close(file_names = [])
    file_names = @@files.keys unless file_names && ! file_names.empty?
    array(file_names).each do |file_name|
      @@files[file_name][:file].close if @@files[file_name][:file]
      @@files.delete(file_name)
    end
  end
end
end
end