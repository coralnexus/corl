
module Git
class Remote
  
  #-----------------------------------------------------------------------------
  # Remote endpoints

  def set_url(url, opts = {})
    @base.lib.remote_set_url(@name, url, opts)  
  end
end
end