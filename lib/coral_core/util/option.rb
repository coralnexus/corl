module Coral
  module Util
    module Option
        
      #-------------------------------------------------------------------------
      # Utilities
        
      def message(name, default = nil)
        if default.nil?
          default = :none
        end
        return I18n.t(name.to_s, :default => default.to_s)
      end
        
      #---
        
      def parse(parser, options, name, default, option_str, allowed_values, message_id, config = {})
        config        = Config.ensure(config)
        name          = name.to_sym
        options[name] = config.get(name, default)
          
        message_name = name.to_s + '_message'
        message      = message(message_id, options[name])
        
        option_str   = Core.array(option_str)
          
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
        
      def bool(parser, options, name, default, option_str, message_id, config = {})
        parse(parser, options, name, default, option_str, nil, message_id, config) do |value|
          yield(value) if block_given?
        end  
      end
        
      #---
        
      def int(parser, options, name, default, option_str, message_id, config = {})
        parse(parser, options, name, default, option_str, Integer, message_id, config) do |value|
          yield(value) if block_given?  
        end 
      end
        
      #---
        
      def float(parser, options, name, default, option_str, message_id, config = {})
        parse(parser, options, name, default, option_str, Float, message_id, config) do |value|
          yield(value) if block_given?  
        end  
      end
          
      #---
        
      def str(parser, options, name, default, option_str, message_id, config = {})
        parse(parser, options, name, default, option_str, nil, message_id, config) do |value|
          yield(value) if block_given?  
        end  
      end
         
      #---
        
      def array(parser, options, name, default, option_str, message_id, config = {})
        parse(parser, options, name, default, option_str, Array, message_id, config) do |value|
          yield(value) if block_given?  
        end  
      end        
    end
  end
end