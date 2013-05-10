
module Coral
module Util
class Data
  
  #-----------------------------------------------------------------------------
  # Type checking
  
  def self.undef?(value)
    if value.nil? || 
      (value.is_a?(Symbol) && value == :undef || value == :undefined) || 
      (value.is_a?(String) && value.match(/^\s*(undef|UNDEF|Undef|nil|NIL|Nil)\s*$/))
      return true
    end
    return false  
  end
  
  #---
  
  def self.true?(value)
    if value == true || 
      (value.is_a?(String) && value.match(/^\s*(true|TRUE|True)\s*$/))
      return true
    end
    return false  
  end
  
  #---
  
  def self.false?(value)
    if value == false || 
      (value.is_a?(String) && value.match(/^\s*(false|FALSE|False)\s*$/))
      return true
    end
    return false  
  end
  
  #---
  
  def self.empty?(value)
    if undef?(value) || false?(value) || (value.respond_to?('empty?') && value.empty?)
      return true
    end
    return false
  end
   
  #-----------------------------------------------------------------------------
  # Translation
  
  def self.to_json(data)
    output = ''
    begin
      output = data.to_json
      
    rescue Exception
    end
    return output
  end
  
  #---
  
  def self.to_yaml(data)
    output = ''
    begin
      require 'yaml'
      output = YAML.dump(data)
      
    rescue Exception
    end
    return output
  end
  
  #---
  
  def self.value(value)
    case value
    when String
      if undef?(value)
        value = nil
      elsif true?(value)
        value = true
      elsif false?(value)
        value = false
      end
    
    when Array
      value.each_with_index do |item, index|
        value[index] = value(item)
      end
    
    when Hash
      value.each do |key, data|
        value[key] = value(data)
      end
    end
    return value  
  end
 
  #-----------------------------------------------------------------------------
  # Operations
  
  def self.merge(data, force = true)
    value = data
    
    # Special case because this method is called from within Config.new so we 
    # can not use Config.ensure, as that would cause an infinite loop.
    force = force.is_a?(Coral::Config) ? force.get(:force, force) : force
    
    #dbg(data, 'data')
    
    if data.is_a?(Array)
      value = data.shift
      data.each do |item|
        #dbg(item, 'item')
        case value
        when Hash
          begin
            require 'deep_merge'
            value = force ? value.deep_merge!(item) : value.deep_merge(item)
            
          rescue LoadError
            if item.is_a?(Hash) # Non recursive top level by default.
              value = value.merge(item)                
            elsif force
              value = item
            end
          end  
        when Array
          if item.is_a?(Array)
            value = value.concat(item).uniq
          elsif force
            value = item
          end
        end
      end  
    end
    
    #dbg(value, 'value')            
    return value
  end

  #---
  
  def self.interpolate(value, scope, options = {})    
    
    pattern = ( options.has_key?(:pattern) ? options[:pattern] : '\$(\{)?([a-zA-Z0-9\_\-]+)(\})?' )
    group   = ( options.has_key?(:var_group) ? options[:var_group] : 2 )
    flags   = ( options.has_key?(:flags) ? options[:flags] : '' )
    
    if scope.is_a?(Hash)
      regexp = Regexp.new(pattern, flags.split(''))
    
      replace = lambda do |item|
        matches = item.match(regexp)
        result  = nil
        
        #dbg(item, 'item')
        #dbg(matches, 'matches')
        
        unless matches.nil?
          replacement = scope.search(matches[group], options)
          result      = item.gsub(matches[0], replacement) unless replacement.nil?
        end
        return result
      end
      
      case value
      when String
        #dbg(value, 'interpolate (string) -> init')
        while (temp = replace.call(value))
          #dbg(temp, 'interpolate (string) -> replacement')
          value = temp
        end
        
      when Hash
        #dbg(value, 'interpolate (hash) -> init')
        value.each do |key, data|
          #dbg(data, "interpolate (#{key}) -> data")
          value[key] = interpolate(data, scope, options)
        end
      end
    end
    #dbg(value, 'interpolate -> result')
    return value  
  end
end
end
end
