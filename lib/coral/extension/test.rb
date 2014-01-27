
module Coral
module Extension
class Test < Plugin::Extension

  #-----------------------------------------------------------------------------
  # Extension hooks
  
  def action_create_parse(config)
    if parser = config.get(:parser, nil)
      parser.option_str(:donkey, :kick, 
        '--donkey KICK', 
        'coral.core.actions.create.options.donkey'
      )
    end
  end
  
  #---
  
  def action_create_exec_init(config)
    dbg('Hello from create exec init')
    true
  end
  
  #---
  
  def action_create_project_config(config)
    dbg('Hello from create project config')
    { :pull => false, :revision => :master }  
  end
  
  #---
  
  def action_create_extend_project(config)
    if project = config.get(:project, nil)
      plugin = config.get(:plugin)
      
      dbg('Hello from create extend project')
      dbg('Donkey has kicked!') if plugin.options[:donkey]
    end
  end
  
  #---
  
  def action_create_exec_exit(config)
    plugin = config.get(:plugin)
    dbg('Hello from create exec exit')
  end
  
  #---
  
  def action_create_cleanup(config)
    plugin = config.get(:plugin)
    dbg('Hello from create cleanup')
  end
end
end
end
