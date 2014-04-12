
module Facter
module Util
class Loader
  def load_dir(dir)
    # TODO:  If this works submit a patch to Facter project
    return if dir =~ /\/\.+$/ or dir =~ /\/util$/ or dir =~ /\/core$/ or dir =~ /\/lib$/

    Dir.entries(dir).find_all { |f| f =~ /\.rb$/ }.sort.each do |file|
      load_file(File.join(dir, file))
    end
  end      
end
end
end
