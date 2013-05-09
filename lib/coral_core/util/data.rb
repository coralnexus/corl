
module Coral
module Util
class Data < Core
  
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
      return false
    end
    return true
  end
   
  #-----------------------------------------------------------------------------
  # Translation
  
  def self.to_json(data)
    output = ''
    begin
      require 'json'
      output = data.to_json
    rescue LoadError
    end
    return output
  end
  
  #---
  
  def self.to_yaml(data)
    output = ''
    begin
      require 'yaml'
      output = YAML.dump(data)
    rescue LoadError
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

  def self.normalize(data, override = nil, options = {})
    config  = Config.ensure(options)
    results = {}
    
    unless undef?(override)
      case data
      when String, Symbol
        data = [ data, override ] if data != override
      when Array
        data << override unless data.include?(override)
      when Hash
        data = [ data, override ]
      end
    end
    
    case data
    when String, Symbol
      results = Config.lookup(data.to_s, {}, config)
      
    when Array
      data.each do |item|
        if item.is_a?(String) || item.is_a?(Symbol)
          item = Config.lookup(item.to_s, {}, config)
        end
        unless undef?(item)
          results = merge([ results, item ], config)
        end
      end
  
    when Hash
      results = data
    end
    
    return results
  end
  
  #---
  
  def self.interpolate(value, scope, options = {})    
    config  = Config.ensure(options)
  
    pattern = config.get(:pattern, '\$(\{)?([a-zA-Z0-9\_\-]+)(\})?')
    group   = config.get(:var_group, 2)
    flags   = config.get(:flags, '')
    
    if scope.is_a?(Hash)
      regexp = Regexp.new(pattern, flags.split(''))
    
      replace = lambda do |item|
        matches = item.match(regexp)
        result  = nil
        
        #dbg(item, 'item')
        #dbg(matches, 'matches')
        
        unless matches.nil?
          replacement = scope.search(matches[group], config)
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
          value[key] = interpolate(data, scope, config)
        end
      end
    end
    #dbg(value, 'interpolate -> result')
    return value  
  end
end
end
end

#-------------------------------------------------------------------------------
# Data type alterations

class Hash
  def search(search_key, options = {})
    config = Coral::Config.ensure(options)
    value  = nil
    
    recurse       = config.get(:recurse, false)
    recurse_level = config.get(:recurse_level, -1)
        
    self.each do |key, data|
      if key == search_key
        value = data
        
      elsif data.is_a?(Hash) && 
        recurse && (recurse_level == -1 || recurse_level > 0)
        
        recurse_level -= 1 unless recurse_level == -1
        value = value.search(search_key, 
          Coral::Config.new(config).set(:recurse_level, recurse_level)
        )
      end
      break unless value.nil?
    end
    return value
  end
end
