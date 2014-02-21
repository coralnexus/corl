begin
  require 'hiera/backend'

  class Hiera
    module Backend
      #
      # NOTE: This function is overridden so we can collect accumulated hiera
      # parameters and their values on a particular puppet run for reporting 
      # purposes.
      #
      # Calls out to all configured backends in the order they
      # were specified.  The first one to answer will win.
      #
      # This lets you declare multiple backends, a possible
      # use case might be in Puppet where a Puppet module declares
      # default data using in-module data while users can override
      # using JSON/YAML etc.  By layering the backends and putting
      # the Puppet one last you can override module author data
      # easily.
      #
      # Backend instances are cached so if you need to connect to any
      # databases then do so in your constructor, future calls to your
      # backend will not create new instances
      def lookup(key, default, scope, order_override, resolution_type)
        @backends ||= {}
        answer = nil

        Config[:backends].each do |backend|
          if constants.include?("#{backend.capitalize}_backend") || constants.include?("#{backend.capitalize}_backend".to_sym)
            @backends[backend] ||= Backend.const_get("#{backend.capitalize}_backend").new
            new_answer = @backends[backend].lookup(key, scope, order_override, resolution_type)

            if not new_answer.nil?
              case resolution_type
              when :array
                raise Exception, "Hiera type mismatch: expected Array and got #{new_answer.class}" unless new_answer.kind_of? Array or new_answer.kind_of? String
                answer ||= []
                answer << new_answer
              when :hash
                raise Exception, "Hiera type mismatch: expected Hash and got #{new_answer.class}" unless new_answer.kind_of? Hash
                answer ||= {}
                answer = merge_answer(new_answer,answer)
              else
              answer = new_answer
              break
              end
            end
          end
        end

        answer = resolve_answer(answer, resolution_type) unless answer.nil?
        answer = parse_string(default, scope) if answer.nil? and default.is_a?(String)

        answer = default if answer.nil?
        
        CORL::Config.set_property(key, answer) # This is why we override this function!!
        return answer
      end
    end
  end

rescue LoadError
end
