
module Git

#*******************************************************************************
# Errors
  
class GitDirectoryError < StandardError 
end

#*******************************************************************************
# Base Git definition

class Base
 
  #-----------------------------------------------------------------------------
  # Constructor / Destructor
  
  def initialize(options = {})
    if working_dir = options[:working_directory]
      options[:repository] ||= File.join(working_dir, '.git')
      
      if File.file?(options[:repository])
        File.read(options[:repository]).each_line do |line|
          matches = line.match(/^\s*gitdir:\s*(.+)\s*/)
          if matches.length == 1 && matches[1]
            options[:repository] = matches[1]
            break
          end
        end        
      end
      
      if File.directory?(options[:repository])
        options[:index] ||= File.join(options[:repository], 'index')
      else
        raise GitDirectoryError.new("Git repository directory #{options[:repository]} not found for #{working_dir}")
      end
    end
    
    if options[:log]
      @logger = options[:log]
      @logger.info("Starting Git")
    else
      @logger = nil
    end
     
    @working_directory = options[:working_directory] ? Git::WorkingDirectory.new(options[:working_directory]) : nil
    @repository        = options[:repository] ? Git::Repository.new(options[:repository]) : nil 
    @index             = options[:index] ? Git::Index.new(options[:index], false) : nil
  end
    
  #-----------------------------------------------------------------------------
  # Commit extensions

  def add(path = '.', opts = {})
    self.lib.add(path, opts)
  end
end
end
