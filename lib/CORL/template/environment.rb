
module CORL
module Template
class Environment < plugin_class(:template)
  
  #-----------------------------------------------------------------------------
  # Renderers  
   
  def render_processed(data)
    return super do |output|   
      case data
      when Hash
        data.each do |name, value|
          output << render_assignment(name, value)
        end
      end
      output          
    end      
  end
  
  #-----------------------------------------------------------------------------
  
  def render_assignment(name, value)
    name  = render_name(name)
    value = render_value(value)
    
    export      = get(:export, true)
    export_text = export ? get(:export_text, 'export ') : ''
    operator    = get(:operator, '=')
    
    return "#{export_text}#{name}#{operator}#{value}\n"  
  end
  
  #---
  
  def render_name(name)
    prefix     = get(:name_prefix, '')
    prefix_sep = prefix.empty? ? '' : get(:name_prefix_sep, '_')
    
    suffix     = get(:name_suffix, '')
    suffix_sep = suffix.empty? ? '' : get(:name_suffix_sep, '')
    
    unless prefix.empty?
      name = "#{prefix}#{prefix_sep}#{name}#{suffix_sep}#{suffix}"
    end
    return name
  end
  
  #---
  
  def render_value(value)
    sep          = get(:value_sep, ' ')
    quote        = get(:quote, true)
    
    array_prefix = get(:array_prefix, '(')
    array_suffix = get(:array_suffix, ')')
    
    case value
    when Array
      values = []
      value.each do |item|
        values << quote ? "'#{item}'" : "#{item}"  
      end
      value = "#{array_prefix}#{values.join(sep)}#{array_suffix}"
            
    when String
      value = quote ? "'#{value}'" : "#{value}" 
    end
    return value
  end
end
end
end