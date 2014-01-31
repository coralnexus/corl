
module Coral
module Util
class Batch < Core
  
  #-----------------------------------------------------------------------------
  # Constructor / Destructor

  def initialize(parallel = true)
    super
    
    set(:parallel, parallel)
    set(:results, {})
    
    self.clear
    
    yield(self)
  end
  
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers
  
  def parallel
    get(:parallel, true)
  end
  
  #---
  
  def processes
    get_hash(:processes)
  end
  
  #---
  
  def results
    get_hash(:results)
  end
  
  def set_result(name, value)
    set([ :results, name ], value)
  end

  #-----------------------------------------------------------------------------
  # Batch operations

  def add(name, options = {}, &code)
    processes[name] = Util::Process.new(name, options) do
      code.call
    end
  end
  
  #---
  
  def delete(name)
    processes.delete(name)
    return self
  end
  
  #---
  
  def clear
    set(:processes, {})
    return self
  end
  
  #---
  
  #
  # This run implementation is loosely based on Vagrant's BatchAction 
  # run method which seems to work
  #
  def run
    logger.info("Running batch: Parallel: #{parallel.inspect}")

    errors = exec(get_hash(:processes))

    unless errors.empty?
      raise Errors::BatchError, :message => errors.join("\n\n")
    end
    
    results
  end
  
  #-----------------------------------------------------------------------------
  # Utilities
  
  def exec(processes)
    threads = []
    
    processes.each do |name, process|
      logger.info("Executing process: #{name}")

      thread = Thread.new do
        Thread.current[:error] = nil

        start_pid = ::Process.pid

        begin
          set_result(name, process.run)
          
        rescue Exception => error
          raise if ! parallel && ::Process.pid == start_pid
          
          Thread.current[:error] = error
        end

        if ::Process.pid != start_pid
          exit_status = true
          
          if Thread.current[:error]
            exit_status = false
            error       = Thread.current[:error]
            
            logger.error(error.inspect)
            logger.error(error.message)
            logger.error(error.backtrace.join("\n"))
          end

          ::Process.exit!(exit_status)
        end
      end

      thread[:process] = name

      thread.join if ! parallel
      threads << thread
    end
    
    return finalize(threads)  
  end
  protected :exec
  
  #---
  
  def finalize(threads)
    errors = []

    threads.each do |thread|
      thread.join
      
      if thread[:error]
        error = thread[:error]
        
        if ! thread[:error].is_a?(Errors::CoralError)
          error   = thread[:error]
          message = error.message
          message += "\n"
          message += "\n#{error.backtrace.join("\n")}"

          errors << I18n.t("coral.core.util.batch.unexpected_error",
                           :process => thread[:process],
                           :message => message)
        else
          errors << I18n.t("coral.core.util.batch.coral_error",
                           :process => thread[:process],
                           :message => thread[:error].message)
        end
      end
    end
    
    return errors  
  end
  protected :finalize
end
end
end
