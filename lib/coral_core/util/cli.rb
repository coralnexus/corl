module Coral
  module Util
    module CLI
        
      #-------------------------------------------------------------------------
      # Utilities
        
      def self.message(name, default = nil)
        if default.nil?
          default = :none
        end
        return I18n.t(name.to_s, :default_value => default.to_s)
      end
        
      #---
        
      def self.parse(parser, options, name, default, option_str, allowed_values, message_id, config = {})
        config        = Config.ensure(config)
        name          = name.to_sym
        options[name] = config.get(name, default)
          
        message_name = name.to_s + '_message'
        message      = message(message_id, options[name])
        
        option_str   = Util::Data.array(option_str)
          
        if allowed_values
          parser.on(*option_str, allowed_values, config.get(message_name.to_sym, message)) do |value|
            value         = yield(value) if block_given?
            options[name] = value unless value.nil?
          end
        else
          parser.on(*option_str, config.get(message_name.to_sym, message)) do |value|
            value         = yield(value) if block_given?
            options[name] = value unless value.nil?
          end  
        end
      end
        
      #---
        
      def self.bool(parser, options, name, default, option_str, message_id, config = {})
        parse(parser, options, name, default, option_str, nil, message_id, config) do |value|
          block_given? ? yield(value) : value 
        end  
      end
        
      #---
        
      def self.int(parser, options, name, default, option_str, message_id, config = {})
        parse(parser, options, name, default, option_str, Integer, message_id, config) do |value|
          block_given? ? yield(value) : value 
        end 
      end
        
      #---
        
      def self.float(parser, options, name, default, option_str, message_id, config = {})
        parse(parser, options, name, default, option_str, Float, message_id, config) do |value|
          block_given? ? yield(value) : value 
        end  
      end
          
      #---
        
      def self.str(parser, options, name, default, option_str, message_id, config = {})
        parse(parser, options, name, default, option_str, nil, message_id, config) do |value|
          block_given? ? yield(value) : value 
        end  
      end
         
      #---
        
      def self.array(parser, options, name, default, option_str, message_id, config = {})
        parse(parser, options, name, default, option_str, Array, message_id, config) do |value|
          block_given? ? yield(value) : value 
        end  
      end        
    end
  end
end