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
         
      #-------------------------------------------------------------------------
      # Parser
       
      class Parser
        
        attr_accessor :parser
        attr_accessor :options
        attr_accessor :arguments
        attr_accessor :processed
        
        #---
        
        def initialize(args, banner = '', help = '')
          
          @parser        = OptionParser.new
          
          self.options   = {}
          self.arguments = {}
          self.processed = false
          
          @arg_settings  = []
          
          self.banner  = banner
          self.help    = help
          
          yield(self) if block_given?
          
          parse_command(args)
        end
        
        #---
        
        def self.split(args, banner, separator = '')
          main_args   = nil
          sub_command = nil
          sub_args    = []

          args.each_index do |index|
            if !args[index].start_with?('-')
              main_args   = args[0, index]
              sub_command = args[index]
              sub_args    = args[index + 1, args.length - index + 1]
              break
            end
          end

          main_args = args.dup if main_args.nil?
          results   = [ Parser.new(main_args, banner, separator) ]
          
          if sub_command
            results << [ sub_command, sub_args ]
          end

          return results.flatten
        end
        
        #---
        
        def banner=banner
          parser.banner = banner  
        end
        
        #---
        
        def help=help
          if help.is_a?(Array)
            help.each do |line|
              parser.separator line  
            end                       
          else
            parser.separator help
          end  
        end
        
        #---
        
        def parse_command(args)
          args  = args.dup
          error = false
          
          self.processed = false
          
          parser.on_tail('-h', '--help', message('coral.util.cli.options.help')) do
            Coral.ui.info(parser.help)
            options[:help] = true
            return
          end

          parser.parse!(args)
          
          @arg_settings.each_with_index do |settings, index|
            if index >= args.length
              argument = nil
            else
              argument = Util::Data.value(args[index])  
            end            
            
            value = nil
            
            if !argument.nil? && settings.has_key?(:allowed)
              allowed = settings[:allowed]
              case allowed
              when Class
                if argument.is_a?(allowed)
                  value = argument
                else
                  Coral.ui.error(message(settings[:message]))
                  error = true
                end
              when Array
                if allowed.include(argument)
                  value = argument
                else
                  Coral.ui.error(message(settings[:message]))
                  error = true  
                end
              end
            end
            
            if value.nil?
              if settings.has_key?(:default)
                value = settings[:default]
              else
                error = true
              end
            end
            
            if !value.nil? && settings.has_key?(:block)
              value = block.call(value)
              error = true if value.nil?
            end
            
            break if error
            self.arguments[settings[:name]] = value
          end          
          
          if error
            Coral.ui.error(message('coral.util.cli.parse.error'))
            Coral.ui.info(parser.help)
          else
            self.processed = true
          end
        
        rescue OptionParser::InvalidOption
          raise Errors::CLIInvalidOptions, :help => parser.help.chomp  
        end
        
        #---
                
        def option(name, default, option_str, allowed_values, message_id, config = {})
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
        
        def arg(name, default, allowed_values, message_id, config = {}, &block)
          config       = Config.ensure(config)
          name         = name.to_sym
          
          message_name = name.to_s + '_message'
          message      = message(message_id, arguments[name])
        
          settings     = { 
            :name    => name,
            :default => config.get(name, default),
            :message => config.get(message_name.to_sym, message) 
          }
          settings[:allowed] = allowed_values if allowed_values
          settings[:block]   = block if block
          
          @arg_settings << settings  
        end
        
        #---
        
        def option_bool(name, default, option_str, message_id, config = {})
          option(name, default, option_str, nil, message_id, config) do |value|
            value = Util::Data.value(value)
            if value == true || value == false
              block_given? ? yield(value) : value
            else
              nil
            end 
          end  
        end
        
        #---
        
        def arg_bool(name, default, message_id, config = {})
          arg(name, default, nil, message_id, config) do |value|
            value = Util::Data.value(value)
            if value == true || value == false
              block_given? ? yield(value) : value
            else
              nil
            end 
          end  
        end
        
        #---
        
        def option_int(name, default, option_str, message_id, config = {})
          option(name, default, option_str, Integer, message_id, config) do |value|
            block_given? ? yield(value) : value 
          end 
        end
        
        #---
        
        def arg_int(name, default, message_id, config = {})
          arg(name, default, Integer, message_id, config) do |value|
            block_given? ? yield(value) : value 
          end 
        end
        
        #---
        
        def option_float(name, default, option_str, message_id, config = {})
          option(name, default, option_str, Float, message_id, config) do |value|
            block_given? ? yield(value) : value 
          end  
        end
        
        #---
        
        def arg_float(name, default, message_id, config = {})
          arg(name, default, Float, message_id, config) do |value|
            block_given? ? yield(value) : value 
          end  
        end
          
        #---
        
        def option_str(name, default, option_str, message_id, config = {})
          option(name, default, option_str, nil, message_id, config) do |value|
            block_given? ? yield(value) : value 
          end  
        end
         
        #---
        
        def arg_str(name, default, message_id, config = {})
          arg(name, default, nil, message_id, config) do |value|
            block_given? ? yield(value) : value 
          end  
        end
         
        #---
        
        def option_array(name, default, option_str, message_id, config = {})
          option(name, default, option_str, Array, message_id, config) do |value|
            block_given? ? yield(value) : value 
          end  
        end
         
        #---
        
        def arg_array(name, default, message_id, config = {})
          arg(name, default, Array, message_id, config) do |value|
            block_given? ? yield(value) : value 
          end  
        end 
      end    
    end
  end
end