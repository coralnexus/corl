
nucleon_require(File.dirname(__FILE__), :cloud_action)

#---

module Nucleon
module Plugin
class Agent < Nucleon.plugin_class(:nucleon, :cloud_action)

  #-----------------------------------------------------------------------------
  # Property accessor / modifiers

  def configure
    super do
      yield if block_given?
      agent_config
    end
  end

  #---

  def help
    # TODO:  Localization
    'AGENT ' + super
  end

  #-----------------------------------------------------------------------------
  # Settings

  def pid
    settings[:pid]
  end

  #---

  def agent_config
  end

  #-----------------------------------------------------------------------------
  # Operations

  def execute(use_network = true, &code)
    super do |node|
      ensure_network do
        daemonize(node)
        yield node
      end
    end
  end

  #---

  def daemonize(node)
    # Mostly derived from rack gem implementation
    #
    # https://github.com/rack/rack/blob/master/lib/rack/server.rb
    # http://www.jstorimer.com/blogs/workingwithcode/7766093-daemon-processes-in-ruby
    #
    if RUBY_VERSION < "1.9"
      exit if fork
      Process.setsid
      safe_exit if fork

      Dir.chdir network.directory

      STDIN.reopen "/dev/null"
      STDOUT.reopen "/dev/null", "a"
      STDERR.reopen "/dev/null", "a"
    else
      Process.daemon
    end

    #---

    save_process(node)

    at_exit do
      shutdown_process(node)
    end

    trap(:INT) do
      safe_exit
    end
  end
  protected :daemonize

  #-----------------------------------------------------------------------------
  # Utilities

  def process_status(node)
    agent_settings = node.agent(plugin_provider)

    return :not_running unless agent_settings && agent_settings.has_key?(:pid)
    return :dead if agent_settings[:pid] == 0

    Process.kill(0, agent_settings[:pid])
    :running

    rescue Errno::ESRCH
      :dead
    rescue Errno::EPERM
      :not_owned
  end
  protected :process_status

  #---

  def save_process(node)
    settings[:pid] = Process.pid

    node.add_agent(plugin_provider, settings)
    node.save({
      :message => "Agent #{plugin_provider} starting up on #{node.plugin_name}",
      :remote => extension_set(:write_process_remote, :edit),
      :push => true
    })
  end
  protected :save_process

  #---

  def shutdown_process(node)
    node.remove_agent(plugin_provider)
    node.save({
      :message => "Agent #{plugin_provider} shutting down on #{node.plugin_name}",
      :remote => extension_set(:shutdown_handler_remote, :edit),
      :push => true
    })
  end
  protected :shutdown_process

  #---

  def safe_exit
    finalize_execution
    exit status
  end
  protected :safe_exit
end
end
end
