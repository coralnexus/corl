
module Coral
module Template
class Wrapper < Base
  #-----------------------------------------------------------------------------
  # Renderers  
   
  def render(input)
    return get(:template_prefix, '') + input.to_s + get(:template_suffix, '')
  end
end
end
end