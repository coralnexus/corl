
class Hiera
module Backend
class << self
  #
  # NOTE: This method is overridden so we can collect accumulated hiera
  # parameters and their values on a particular provisioning run for reporting 
  # purposes.
  #
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
    
    # This is why we override this method!!
    # TODO: Submit a patch that allows for some kind of hook into the process.
    if CORL::Config.get_property(key).nil? || answer    
      CORL::Config.set_property(key, answer)
    end
    return answer
  end
end
end
end
