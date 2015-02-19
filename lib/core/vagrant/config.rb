
#
# Because we create configurations and operate on resulting machines during
# the course of a single CLI command run we need to be able to reload the
# configurations based on updates to fetch Vagrant VMs and run Vagrant machine
# actions.  TODO: Inquire about some form of inclusion in Vagrant core?
#
module Vagrant
class Vagrantfile

  def reload
    @loader.clear_config_cache(@keys)
    @config, _ = @loader.load(@keys)
  end
end

module Config
class Loader
  def clear_config_cache(sources = nil)
    @config_cache = {}

    if sources
      keep = {}
      sources.each do |source|
        keep[source] = @sources[source] if @sources[source]
      end
      @sources = keep
    end
  end
end
end
end

#-------------------------------------------------------------------------------

module CORL
module Vagrant
module Config

  @@logger = Util::Logger.new('vagrant')

  def self.logger
    @@logger
  end

  #
  # Vagrant node network container
  #
  @@network = nil

  def self.network=network
    @@network = network
  end

  def self.network
    @@network
  end

  #
  # Whether or not we are re-rendering this configuration
  #
  @@rerender = false

  #
  # Gateway CORL configurator for Vagrant.
  #
  def self.register(directory, config, &code)
    ::Vagrant.require_version ">= 1.5.0"

    config_network = network
    config_network = load_network(directory) unless config_network

    if config_network
      # Vagrant settings
      unless configure_vagrant(config_network, config.vagrant)
        raise "Configuration of Vagrant general settings failed"
      end

      config_network.nodes(:vagrant, true).each do |node_name, node|
        config.vm.define node.id.to_sym do |machine|
          render("\n")
          render("config.vm.define '#{node.id}' do |node|")

          # SSH settings
          unless configure_ssh(node, machine)
            raise "Configuration of Vagrant VM SSH settings failed"
          end

          # VM settings
          unless configure_vm(node, machine)
            raise "Configuration of Vagrant VM failed: #{node_name}"
          end

          # Provisioner configuration
          unless configure_provisioner(network, node, machine, &code)
            raise "Configuration of Vagrant provisioner failed: #{node_name}"
          end
        end
      end
    end
    @@rerender = true
  end

  #---

  def self.load_network(directory)
    # Load network if it exists
    @@network = CORL.network(directory, CORL.config(:vagrant_network, { :directory => directory }))
  end

  #---

  def self.configure_vagrant(network, vagrant)
    success = true
    Util::Data.hash(network.settings(:vagrant_config)).each do |name, data|
      if vagrant.respond_to?("#{name}=")
        data = Util::Data.value(data)
        render("config.vagrant.#{name} = %property", { :property => data })
        vagrant.send("#{name}=", data)
      else
        params = parse_params(data)
        render("config.vagrant.#{name} %params", { :params => params })
        vagrant.send(name, params)
      end
    end
    success
  end

  #---

  def self.configure_ssh(node, machine)
    success = true

    render("  node.ssh.username = %property", { :property => node.user })
    machine.ssh.username = node.user

    render("  node.ssh.guest_port = %property", { :property => node.ssh_port })
    machine.ssh.guest_port = node.ssh_port

    if node.cache_setting(:use_private_key, false)
      key_dir     = node.network.key_cache_directory
      key_name    = node.plugin_name

      ssh_config  = ::CORL::Config.new({
        :keypair  => node.keypair,
        :key_dir  => key_dir,
        :key_name => key_name
      })

      if keypair = Util::SSH.unlock_private_key(node.private_key, ssh_config)
        if keypair.is_a?(String)
          render("  node.ssh.private_key_path = %property", { :property => keypair })
          machine.ssh.private_key_path = keypair
        else
          private_key_file = keypair.private_key_file(key_dir, key_name)
          node.keypair     = keypair
          render("  node.ssh.private_key_path = %property", { :property => private_key_file })
          machine.ssh.private_key_path = private_key_file
        end
      end
      unless keypair && File.exists?(machine.ssh.private_key_path)
        render("  node.ssh.private_key_path = %property", { :property => node.private_key })
        machine.ssh.private_key_path = node.private_key
      end
    end

    render("\n")

    Util::Data.hash(node.ssh).each do |name, data|
      if machine.ssh.respond_to?("#{name}=")
        data = Util::Data.value(data)
        render("  node.ssh.#{name} = %property", { :property => data })
        machine.ssh.send("#{name}=", data)
      else
        params = parse_params(data)
        render("  node.ssh.#{name} %params", { :params => params })
        machine.ssh.send(name, params)
      end
    end
    success
  end

  #---

  def self.configure_vm(node, machine)
    vm_config = Util::Data.hash(Util::Data.clone(node.vm))
    success   = true

    render("  node.vm.hostname = %property", { :property => node.hostname })
    machine.vm.hostname = node.hostname

    box      = node.cache_setting(:box)
    box_url  = node.cache_setting(:box_url)
    box_file = nil

    if box_url
      box_file = box_url.gsub(/^file\:\/\//, '')
      unless File.exists?(box_file)
        box_url = nil
        node.clear_cache
      end
    end

    if vm_config.has_key?(:private_network)
      network_options = Util::Data.hash(vm_config[:private_network])

      if node[:public_ip]
        network_options[:ip] = node[:public_ip]
      end
      render("  node.vm.network :private_network, %params", { :params => network_options })
      machine.vm.network :private_network, network_options
      vm_config.delete(:private_network)
      render("\n")

    elsif vm_config.has_key?(:public_network)
      network_options = Util::Data.hash(vm_config[:public_network])

      render("  node.vm.network :public_network, %params", { :params => network_options })
      machine.vm.network :public_network, network_options
      vm_config.delete(:public_network)
      render("\n")
    end

    if vm_config.has_key?(:provision)
      Util::Data.array(vm_config[:provision]).each do |provisioner|
        if provisioner.is_a?(String)
          render("  node.vm.provision :#{provisioner}")
          machine.vm.provision provisioner
        else
          provision_options = Util::Data.symbol_map(provisioner)
          provision_type    = provision_options.delete(:type)

          if provision_type
            render("  node.vm.provision :#{provision_type}, %params", { :params => provision_options })
            machine.vm.provision provision_type, provision_options
          end
        end
      end
      vm_config.delete(:provision)
    end

    vm_config.each do |name, data|
      case name.to_sym
      # Network interfaces
      when :forwarded_ports
        data.each do |forward_name, info|
          forward_config = CORL::Config.new({ :auto_correct => true }).import(info)

          forward_config.keys do |key|
            forward_config[key] = Util::Data.value(forward_config[key])
          end
          forward_options = forward_config.export
          render("  node.vm.network :forwarded_port, %params", { :params => forward_options })
          machine.vm.network :forwarded_port, forward_options
        end
        render("\n")
      when :usable_port_range
        low, high = data.to_s.split(/\s*--?\s*/)
        render("  node.vm.usable_port_range = #{low}..#{high}")
        machine.vm.usable_port_range = Range.new(low, high)

      # Provider specific settings
      when :providers
        data.each do |provider, info|
          provider          = provider.to_sym
          info              = Util::Data.symbol_map(info)
          already_processed = {}

          machine.vm.provider provider do |interface, override|
            render("  node.vm.provider '#{provider}' do |provider, override|  # for #{node.hostname}") unless already_processed[provider]

            if info.has_key?(:private_network)
              network_options = info[:private_network].is_a?(Hash) ? info[:private_network] : { :ip => info[:private_network] }

              render("    node.vm.network :private_network, %params", { :params => network_options }) unless already_processed[provider]
              machine.vm.network :private_network, network_options
              info.delete(:private_network)

            elsif info.has_key?(:public_network)
              network_options = info[:public_network].is_a?(Hash) ? info[:public_network] : { :ip => info[:public_network] }

              render("    node.vm.network :public_network, %params", { :params => network_options })
              machine.vm.network :public_network, network_options
              info.delete(:public_network)
            end

            if info.has_key?(:override) && info[:override].has_key?(:provision)
              Util::Data.array(info[:override][:provision]).each do |provisioner|
                if provisioner.is_a?(String)
                  render("    override.vm.provision :#{provisioner}")
                  override.vm.provision provisioner
                else
                  provision_options = Util::Data.symbol_map(provisioner)
                  provision_type    = provision_options.delete(:type)

                  if provision_type
                    render("    override.vm.provision :#{provision_type}, %params", { :params => provision_options })
                    override.vm.provision provision_type, provision_options
                  end
                end
              end
              info[:override].delete(:provision)
            end

            info.each do |property, item|
              if property.to_sym == :override
                configure_provider_overrides(provider, machine, override, item, already_processed[provider], [], '    ')
              else
                if interface.respond_to?("#{property}=")
                  render("    provider.#{property} = %property", { :property => item }) unless already_processed[provider]
                  interface.send("#{property}=", item)
                else
                  params = parse_params(item)
                  render("    provider.#{property} %params", { :params => params }) unless already_processed[provider]
                  interface.send(property, params)
                end
              end
            end

            if box || box_url
              if provider != :docker
                if box && box_url
                  render("    override.vm.box = %property", { :property => box }) unless already_processed[provider]
                  override.vm.box = box

                  render("    override.vm.box_url = %property", { :property => box_url }) unless already_processed[provider]
                  override.vm.box_url = box_url
                end
              else
                if box_file
                  render("    provider.build_dir = %property", { :property => box_file }) unless already_processed[provider]
                  interface.build_dir = box_file
                else
                  render("    provider.image = %property", { :property => box }) unless already_processed[provider]
                  interface.image = box
                end
              end
              render("\n")
            end

            # Server shares
            unless configure_shares(node, provider, override, already_processed[provider], '    ')
              raise "Configuration of Vagrant shares failed: #{node_name}"
            end

            unless already_processed[provider]
              render("  end")
              render("\n")
            end
            already_processed[provider] = 1
          end
        end
      # All other basic VM settings...
      else
        if machine.vm.respond_to?("#{name}=")
          render("  node.vm.#{name} = %property", { :property => data })
          machine.vm.send("#{name}=", data)
        else
          params = parse_params(data)
          render("  node.vm.#{name} %params", { :params => params })
          machine.vm.send(name, params)
        end
      end
      render("\n")
    end
    success
  end

  #---

  def self.configure_shares(node, provider, machine, already_processed, indent = '')
    use_nfs          = provider.to_sym != :docker
    bindfs_installed = Gems.exist?('vagrant-bindfs')
    success          = true

    if use_nfs && bindfs_installed
      machine.vm.synced_folder ".", "/vagrant", disabled: true

      unless ENV['CORL_NO_NETWORK_SHARE']
        machine.vm.synced_folder ".", "/tmp/vagrant", :type => "nfs"
        machine.bindfs.bind_folder "/tmp/vagrant", "/vagrant"
      end
    end

    render("\n") unless already_processed

    Util::Data.hash(node.shares).each do |name, options|
      config = CORL::Config.ensure(options)

      if config[:type].to_sym == :nfs && ! use_nfs
        config.delete(:type)
      end

      share_type = config.get(:type, nil)
      local_dir  = config.delete(:local, '')
      remote_dir = config.delete(:remote, '')

      config.init(:create, true)

      unless local_dir.empty? || remote_dir.empty?
        bindfs_options = config.delete(:bindfs, {})
        share_options  = {}

        config.keys.each do |key|
          share_options[key] = Util::Data.value(config[key])
        end

        if share_type && share_type.to_sym == :nfs && bindfs_installed
          final_dir  = remote_dir
          remote_dir = [ '/tmp', remote_dir.sub(/^\//, '') ].join('/')

          render("#{indent}override.bindfs.bind_folder '#{remote_dir}', '#{final_dir}', %params", { :params => bindfs_options }) unless already_processed
          machine.bindfs.bind_folder remote_dir, final_dir, bindfs_options
        end

        render("#{indent}override.vm.synced_folder '#{local_dir}', '#{remote_dir}', %params", { :params => share_options }) unless already_processed
        machine.vm.synced_folder local_dir, remote_dir, share_options
      end
    end
    success
  end

  #---

  def self.configure_provisioner(network, node, machine, &code)
    success = true

    unless node[:docker_host]
      # CORL provisioning
      machine.vm.provision :corl do |provisioner|
        provisioner.network = network
        provisioner.node    = node

        code.call(node, machine, provisioner) if code
      end
    end
    success
  end

  #---

  def self.configure_provider_overrides(provider, machine, config, data, already_processed, parents = [], indent = '')
    data.each do |name, info|
      label = (parents.empty? ? name : "#{parents.join('.')}.#{name}")

      if info.is_a?(Hash)
        configure_provider_overrides(provider, machine.send(name), config.send(name), info, already_processed, [ parents, name].flatten, indent)
      else
        if machine.respond_to?("#{name}=")
          render("#{indent}override.#{label} = %property", { :property => info }) unless already_processed
          config.send("#{name}=", info)
        else
          params = parse_params(info)
          render("#{indent}override.#{label} %params", { :params => params }) unless already_processed
          config.send(name, params)
        end
      end
    end
  end

  #---

  def self.parse_params(data)
    params = data
    if data.is_a?(Hash)
      params = []
      data.each do |key, item|
        unless Util::Data.undef?(item)
          params << ( key.match(/^\:/) ? key.gsub(/^\:/, '').to_sym : key.to_s )
          unless Util::Data.empty?(item)
            value = item
            value = ((item.is_a?(String) && item.match(/^\:/)) ? item.gsub(/^\:/, '').to_sym : item)
            params << Util::Data.value(value)
          end
        end
      end
    end
    params
  end

  #---

  def self.render(statement, inputs = {})
    return unless [ :debug, :info, :warn, :error ].include?(Nucleon.log_level)

    if statement =~ /^\s+$/
      puts statement
    else
      Util::Data.clone(inputs).each do |name, data|
        rendered_data = render_value(data)

        if rendered_data.empty?
          statement.gsub!(/,\s*$/, '')
        end
        statement.gsub!("\%#{name}", rendered_data)
      end
      Core.ui_group('') do |ui|
        ui.success(statement, { :prefix => false })
      end
    end
  end

  #---

  def self.render_value(data)
    rendered_value = ''

    case data
    when Hash
      keypairs = []
      data.each do |name, value|
        keypairs << "#{name}: " + render_value(value)
      end
      rendered_value = keypairs.join(', ')
    when Array
      unless data.empty?
        data.collect! {|value| render_value(value) }
        rendered_value = '[' + data.join(', ') + ']'
      end
    when String
      if check_numeric(data) || data[0] == ':'
        rendered_value = data.to_s
      else
        if data =~ /\'/
          rendered_value = "\"#{data}\""
        else
          rendered_value = "'#{data}'"
        end
      end
    when Symbol
      rendered_value = ":#{data}"
    else
      rendered_value = data.to_s
    end
    rendered_value
  end

  #---

  def self.check_numeric(string)
    return true if string =~ /^\d+$/
    begin
      Float(string)
      return true
    rescue
      return false
    end
  end
end
end
end
