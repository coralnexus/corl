
module Coral
module Util
class SSH < Core

  #-----------------------------------------------------------------------------
  # Instance generators
  
  def self.generate(options = {})
    config      = Config.ensure(options)
    
    private_key = config.get(:private_key, nil)
    key_comment = config.get(:comment, '')    
    
    if private_key.nil?
      key_type    = config.get(:type, "RSA")
      key_bits    = config.get(:bits, 2048)
      passphrase  = config.get(:passphrase, nil)
    
      key_data = SSHKey.generate(
        :type       => key_type, 
        :bits       => key_bits, 
        :comment    => key_comment, 
        :passphrase => passphrase
      )
    else
      if private_key.include?('PRIVATE KEY')
        key_data = SSHKey.generate(private_key, :comment => key_comment)
      else
        key_data = SSHKey.generate(Disk.read(private_key), :comment => key_comment)
      end
    end
    
    Keypair.new(key_data)
  end
  
  #-----------------------------------------------------------------------------
  # Checks
  
  def valid?(public_ssh_key)
    SSHKey.valid_ssh_public_key?(public_ssh_key)
  end
  
  #-----------------------------------------------------------------------------
  # Keypair interface
    
  class Keypair
    attr_reader :type, :private_key, :encrypted_key, :public_key, :ssh_key
    
    def initialize(key_data)
      @type          = key_data.type
      @private_key   = key_data.private_key
      @encrypted_key = key_data.encrypted_private_key
      @public_key    = key_data.public_key
      @ssh_key       = key_data.ssh_public_key
    end
    
    #---
    
    def store(key_path, key_base = 'id')
      private_key_file = File.join(key_path, "#{key_base}_#{type.downcase}")
      public_key_file  = File.join(key_path, "#{key_base}_#{type.downcase}.pub")
      
      private_success = Disk.write(private_key_file, encrypted_key)
      FileUtils.chmod(0600, private_key_file) if private_success
      
      public_success  = Disk.write(public_key_file, ssh_key)
      
      if private_success && public_success
        return { :private_key => private_key_file, :public_key => public_key_file }
      end
      false
    end
  end
  
  #-----------------------------------------------------------------------------
  # SSH Execution interface
  
  @@sessions = {}
  
  #---
  
  def self.session_id(public_ip, user)
    "#{public_ip}-#{user}"  
  end
  
  #---
  
  def self.session(public_ip, user, port = 22, private_key = nil, reset = false)
    require 'net/ssh'
    
    ssh_options = {
      :port         => port,
      :keys         => private_key.nil? ? [] : [ private_key ],
      :key_data     => [],
      :keys_only    => false,
      :auth_methods => [ 'publickey' ]
    }
    
    session_id = session_id(public_ip, user)
    
    unless reset || @@sessions.has_key?(session_id)
      @@sessions[session_id] = Net::SSH.start(public_ip, user, ssh_options)
    end
    yield(@@sessions[session_id]) if block_given?
    @@sessions[session_id] 
  end
  
  def self.init_session(public_ip, user, port = 22, private_key = nil)
    session(public_ip, user, port, private_key, true)  
  end
  
  #---
  
  def self.close
    @@sessions.keys.each do |session_id|
      session = @@sessions[session_id]
      session.close
      @@sessions.delete(session_id)      
    end
  end
  
  #---
  
  def self.exec!(public_ip, user, commands)
    results = []
        
    begin
      session(public_ip, user) do |ssh|
        Data.array(commands).each do |command|
          command = command.flatten.join(' ') if command.is_a?(Array)
          command = command.to_s
          result  = Shell::Result.new(command)
              
          ssh.open_channel do |ssh_channel|
            ssh_channel.request_pty
            ssh_channel.exec(command) do |channel, success|
              unless success
                raise "Could not execute command: #{command.inspect}"
              end

              channel.on_data do |ch, data|
                result.append_output(data)
                yield(:output, command, data) if block_given?
              end

              channel.on_extended_data do |ch, type, data|
                next unless type == 1
                result.append_errors(data)
                yield(:error, command, data) if block_given?
              end

              channel.on_request('exit-status') do |ch, data|
                result.status = data.read_long
              end

              channel.on_request('exit-signal') do |ch, data|
                result.status = 255
              end
            end
          end
          ssh.loop              
          results << result
        end
      end
    rescue Net::SSH::HostKeyMismatch => error
      error.remember_host!
      sleep 0.2
      retry
    end
    results  
  end
  
  def self.exec(public_ip, user, commands, options = {})
    exec!(public_ip, user, commands, options)
  end
  
  #---
  
  def self.download!(public_ip, user, remote_path, local_path, options = {})
    config = Config.ensure(options)
    
    require 'net/scp'
    
    # Accepted options:
    # * :recursive - the +remote+ parameter refers to a remote directory, which
    # should be downloaded to a new directory named +local+ on the local
    # machine.
    # * :preserve - the atime and mtime of the file should be preserved.
    # * :verbose - the process should result in verbose output on the server
    # end (useful for debugging).
    #
    config.init(:recursive, true)
    config.init(:preserve, true)
    config.init(:verbose, true)
    
    blocking = config.delete(:blocking, true)
    
    session(public_ip, user) do |ssh|
      if blocking
        ssh.scp.download!(remote_path, local_path, config.export) do |ch, name, received, total|
          yield(name, received, total) if block_given?
        end
      else
        ssh.scp.download(remote_path, local_path, config.export)
      end
    end
  end
  
  def self.download(public_ip, user, remote_path, local_path, options = {})
    download!(public_ip, user, remote_path, local_path, options)
  end
  
  #---
  
  def self.upload!(public_ip, user, local_path, remote_path, options = {})
    config = Config.ensure(options)
    
    require 'net/scp'
    
    # Accepted options:
    # * :recursive - the +local+ parameter refers to a local directory, which
    # should be uploaded to a new directory named +remote+ on the remote
    # server.
    # * :preserve - the atime and mtime of the file should be preserved.
    # * :verbose - the process should result in verbose output on the server
    # end (useful for debugging).
    # * :chunk_size - the size of each "chunk" that should be sent. Defaults
    # to 2048. Changing this value may improve throughput at the expense
    # of decreasing interactivity.
    #
    config.init(:recursive, true)
    config.init(:preserve, true)
    config.init(:verbose, true)
    config.init(:chunk_size, 2048)
    
    blocking = config.delete(:blocking, true)
    
    session(public_ip, user) do |ssh|
      if blocking
        ssh.scp.upload!(local_path, remote_path, config.export) do |ch, name, sent, total|
          yield(name, sent, total) if block_given?
        end
      else
        ssh.scp.upload(local_path, remote_path, config.export)
      end
    end
  end
  
  def self.upload(public_ip, user, remote_path, local_path, options = {})
    upload!(public_ip, user, remote_path, local_path, options)
  end
end
end
end
