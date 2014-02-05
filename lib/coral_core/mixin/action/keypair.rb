
module Coral
module Mixin
module Action
module Keypair
        
  #-----------------------------------------------------------------------------
  # Options
        
  def keypair_options(parser)
    parser.option_str(:private_key, '~/.ssh/id_rsa',
      '--private-key KEY_PATH',  
      'coral.core.mixins.keypair.options.private_key'
    )
    parser.option_str(:public_key, '~/.ssh/id_rsa.pub',
      '--public-key KEY_PATH',  
      'coral.core.mixins.keypair.options.public_key'
    )         
  end
        
  #-----------------------------------------------------------------------------
  # Operations
  
end
end
end
end

