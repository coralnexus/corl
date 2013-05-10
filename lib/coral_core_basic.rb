
home         = File.dirname(__FILE__)
dependencies = File.join(home, 'dependency')

$:.unshift(home) unless
  $:.include?(home) || $:.include?(File.expand_path(home))
  
#-------------------------------------------------------------------------------
  
require 'rubygems'
require 'hiera_backend.rb'

#---

begin
  require 'log4r'
    
rescue LoadError
  log4r_lib = File.join(dependencies, 'log4r', 'lib')
  
  $:.push(log4r_lib)
  require File.join(log4r_lib, 'log4r.rb')  
end

#---

begin
  require 'json'
    
rescue LoadError
  json_lib = File.join(dependencies, 'json', 'lib')
  
  $:.push(json_lib)
  require File.join(json_lib, 'json.rb')  
end

#---

# Include pre core utilities (no internal dependencies)
[ :data ].each do |name| 
  require File.join('coral_core', 'util', name.to_s + ".rb") 
end

# Include core
[ :config, :interface, :core, :resource, :template ].each do |name| 
  require File.join('coral_core', name.to_s + ".rb") 
end

# Include post core utilities 
# ( normally inherit from core and have no reverse dependencies with 
#   core classes )
#
[ :disk, :shell ].each do |name| 
  require File.join('coral_core', 'util', name.to_s + ".rb") 
end

# Include data model
[ :event, :command ].each do |name| 
  require File.join('coral_core', name.to_s + ".rb") 
end

# Include specialized events
Dir.glob(File.join(home, 'coral_core', 'event', '*.rb')).each do |file|
  require file
end

# Include bundled templates
Dir.glob(File.join(home, 'coral_core', 'template', '*.rb')).each do |file|
  require file
end

#---

require 'coral.rb'
