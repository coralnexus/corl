
module Coral
module Util
class SSH

  #-----------------------------------------------------------------------------
  # Instance generators
  
  def self.generate(private_key = nil)
    key_comment = congig.get(:comment, '')    
    
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
    
    def store(key_path, key_base = 'id')
      private_key_file = File.join(key_path, "#{key_base}_#{type.downcase}")
      public_key_file  = File.join(key_path, "#{key_base}_#{type.downcase}.pub")
      
      private_success = Disk.write(private_key_file, encrypted_key)
      public_success  = Disk.write(public_key_file, ssh_key)
      
      if private_success && public_success
        return { :private_key => private_key_file, :public_key => public_key_file }
      end
      false
    end
  end
end
end
end
