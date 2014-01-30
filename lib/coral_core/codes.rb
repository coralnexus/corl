
module Coral
class Codes
  
  #-----------------------------------------------------------------------------
  # Code index
  
  @@index = {}
  
  def self.index(number = nil)
    if number.nil?
      @@index
    else
      number = number.to_i
          
      if @@index.has_key?(number)
        @@index[number]
      else
        @@index[2] # Unknown status
      end  
    end    
  end
  
  #-----------------------------------------------------------------------------
  # Code construction
  
  def self.code(name, number)
    number = number.to_i
    
    # TODO: Add more information to the index (like a help message)
    @@index[number] = name.to_s 
    
    define_method(name) { number }
  end
  
  #-----------------------------------------------------------------------------
  # Code of last resort
  
  def method_missing(method, *args, &block)  
    return unknown_status  
  end
  
  #-----------------------------------------------------------------------------
  # Core status codes
  
  code(:help_wanted, 1)
  code(:unknown_status, 2)
  
  code(:action_unprocessed, 3)
  
end
end