
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

    @bootstrap         = UNSET_VALUE
    @bootstrap_path    = UNSET_VALUE
    @bootstrap_glob    = UNSET_VALUE
    @bootstrap_init    = UNSET_VALUE
    @bootstrap_scripts = UNSET_VALUE
    @reboot            = true
    @dev_build         = false
    @home_env_var      = UNSET_VALUE
    @root_user         = UNSET_VALUE
    @root_home         = UNSET_VALUE

    @auth_files        = UNSET_VALUE

    @seed              = UNSET_VALUE
    @project_reference = UNSET_VALUE
    @project_branch    = UNSET_VALUE

    @provision         = false
    @dry_run           = false
  end

  #---

  def finalize!
    super
    @user_home         = nil if @user_home == UNSET_VALUE
    @user_home_env_var = nil if @user_home_env_var == UNSET_VALUE

    @root_user         = nil if @root_user == UNSET_VALUE
    @root_home         = nil if @root_home == UNSET_VALUE

    @bootstrap         = nil if @bootstrap == UNSET_VALUE
    @bootstrap_path    = nil if @bootstrap_path == UNSET_VALUE
    @bootstrap_glob    = nil if @bootstrap_glob == UNSET_VALUE
    @bootstrap_init    = nil if @bootstrap_init == UNSET_VALUE
    @bootstrap_scripts = nil if @bootstrap_scripts == UNSET_VALUE
    @home_env_var      = nil if @home_env_var == UNSET_VALUE
    @root_user         = nil if @root_user == UNSET_VALUE
    @root_home         = nil if @root_home == UNSET_VALUE

    @auth_files        = nil if @auth_files == UNSET_VALUE

    @seed              = nil if @seed == UNSET_VALUE
    @project_reference = nil if @project_reference == UNSET_VALUE
    @project_branch    = nil if @project_branch == UNSET_VALUE
  end

  #-----------------------------------------------------------------------------
  # Property accessor / modifiers

  attr_accessor :network, :node
  attr_accessor :force_updates, :user_home, :user_home_env_var, :root_user, :root_home

  attr_accessor :bootstrap, :bootstrap_path, :bootstrap_glob, :bootstrap_init, :bootstrap_scripts,
  attr_accessor :reboot, :dev_build, :home_env_var, :root_user, :root_home, :auth_files
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
