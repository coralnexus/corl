
module Git
class Lib

  #-----------------------------------------------------------------------------
  # Commit extensions
  
  def add(path = '.', opts = {})
    arr_opts = []
    arr_opts << '-u' if opts[:update]
    if path.is_a?(Array)
      arr_opts += path
    else
      arr_opts << path
    end
    command('add', arr_opts)
  end
  
  #---
  
  def commit(message, opts = {})
    arr_opts = ['-m', message]
    arr_opts << "--author=\'#{opts[:author]}\'" unless opts[:author] && opts[:author].empty?
    arr_opts << '-a' if opts[:add_all]
    arr_opts << '--allow-empty' if opts[:allow_empty]      
    command('commit', arr_opts)
  end
  
  #-----------------------------------------------------------------------------
  # Remote extensions
  
  def remote_add(name, url, opts = {})
    arr_opts = ['add']
    arr_opts << '-f' if opts[:with_fetch]
    arr_opts << name
    arr_opts << url
      
    command('remote', arr_opts)
  end
  
  #---

  def remote_set_url(name, url, opts = {})
    arr_opts = ['set-url']
      
    if opts[:add]
      arr_opts << '--add' if opts[:add]
    end
      
    if opts[:delete]
      arr_opts << '--delete' if opts[:delete]
    end
      
    if opts[:push]
      arr_opts << '--push' if opts[:push]
    end
        
    arr_opts << name
    arr_opts << url
      
    command('remote', arr_opts)
  end
  
  #---
      
  def remote_remove(name)
    command('remote', ['rm', name])
  end
  
  #---
  
  def pull(remote, branch = 'master', tags = false)
    command('pull', [remote, branch])
    command('pull', ['--tags', remote]) if tags
  end
    
  #-----------------------------------------------------------------------------
  # Utilities
  
  def escape(s)
    escaped = s.to_s.gsub('"', '\'')
    if escaped =~ /^\-+/
      escaped  
    else
      %Q{"#{escaped}"}
    end
  end
end
end
