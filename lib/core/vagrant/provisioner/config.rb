
module VagrantPlugins
module CORL
module Config
class CORL < ::Vagrant.plugin("2", :config)

  #-----------------------------------------------------------------------------
  # Constructor / Destructor

  def initialize
    super
    @network           = UNSET_VALUE
    @node              = UNSET_VALUE
    
    @force_updates     = false
    @user_home         = UNSET_VALUE
    @user_home_env_var = UNSET_VALUE
    
    @root_user         = UNSET_VALUE
    @root_home         = UNSET_VALUE
    
    @bootstrap         = false
    @bootstrap_path    = UNSET_VALUE
    @bootstrap_glob    = UNSET_VALUE
    @bootstrap_init    = UNSET_VALUE
    @auth_files        = UNSET_VALUE
    
    @seed              = false
    @project_reference = UNSET_VALUE
    @project_branch    = UNSET_VALUE
    
    @provision         = true
    @dry_run           = false
  end
  
  #---
  
  def finalize!
    super
    @user_home         = nil if @user_home == UNSET_VALUE
    @user_home_env_var = nil if @user_home_env_var == UNSET_VALUE
    
    @root_user         = nil if @root_user == UNSET_VALUE
    @root_home         = nil if @root_home == UNSET_VALUE
    
    @bootstrap_path    = nil if @bootstrap_path == UNSET_VALUE
    @bootstrap_glob    = nil if @bootstrap_glob == UNSET_VALUE
    @bootstrap_init    = nil if @bootstrap_init == UNSET_VALUE
    @auth_files        = nil if @auth_files == UNSET_VALUE
    
    @project_reference = nil if @project_reference == UNSET_VALUE
    @project_branch    = nil if @project_branch == UNSET_VALUE
  end
  
  #-----------------------------------------------------------------------------
  # Property accessor / modifiers
  
  attr_accessor :network, :node  
  attr_accessor :force_updates, :user_home, :user_home_env_var, :root_user, :root_home
  
  attr_accessor :bootstrap, :bootstrap_path, :bootstrap_glob, :bootstrap_init, :auth_files 
  attr_accessor :seed, :project_reference, :project_branch
  attr_accessor :provision, :dry_run
  
  #-----------------------------------------------------------------------------
  # Validation

  def validate(machine)
    errors = _detected_errors
    
    # TODO: Validation (with action config validators)
        
    { "CORL provisioner" => errors }
  end
end
end
end
end
