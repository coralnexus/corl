
$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))
  
#-------------------------------------------------------------------------------
  
require 'rubygems'

#---

# Include core
[ :ui, :core ].each do |name| 
  require File.join('coral_core', name.to_s + ".rb") 
end

# Include utilities
[ :git, :data, :disk, :shell ].each do |name| 
  require File.join('coral_core', 'util', name.to_s + ".rb") 
end

# Include Git overrides
Dir.glob(File.join('coral_core', 'util', 'git', '*.rb')).each do |file|
  require file
end

# Include data model
[ :event, :command, :repository, :memory ].each do |name| 
  require File.join('coral_core', name.to_s + ".rb") 
end

# Include specialized events
Dir.glob(File.join('coral_core', 'event', '*.rb')).each do |file|
  require file
end

#*******************************************************************************
# Coral Core Library
#
# This provides core data elements and utilities used in the Coral gems.
#
# Author::    Adrian Webb (mailto:adrian.webb@coraltech.net)
# License::   GPLv3
module Coral
  
  VERSION = File.read(File.join('..', 'VERSION'))
 
end