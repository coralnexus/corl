
module Coral
module Plugin
class Template < Base

  #-----------------------------------------------------------------------------
  # Template plugin interface

  
  #-----------------------------------------------------------------------------
  # Property accessor / modifiers

  #-----------------------------------------------------------------------------
  # Operations
  
  def process(value)
    case value
    when String, Symbol
      return nil        if Util::Data.undef?(value)
      return 'false'    if value == false
      return 'true'     if value == true      
      return value.to_s if value.is_a?(Symbol)
      
    when Hash
      results = {}
      value.each do |key, item|
        result = process(item)
        unless result.nil?
          results[key] = result  
        end
        value = results
      end
      
    when Array
      results = []
      value.each_with_index do |item, index|
        result = process(item)
        unless result.nil?
          results << result  
        end        
      end
      value = results
    end
    return value
  end
    
  #---
  
  def render(data)
    normalize   = get(:normalize_template, true)
    interpolate = get(:interpolate_template, true)
    
    if normalize
      data = Config.normalize(data, nil, config)
    end
    
    if normalize && interpolate
      data = Util::Data.interpolate(data, data, export)
    end    
    return render_processed(process(data))
  end
  
  #---
  
  def render_processed(data)
    # implement in sub classes.
    return data.to_s
  end
end
end
end
