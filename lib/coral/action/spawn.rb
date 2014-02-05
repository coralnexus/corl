
module Coral
module Action
class Spawn < Plugin::Action
  
  include Mixin::Action::Keypair
 
  #-----------------------------------------------------------------------------
  # Spawn action interface
  
  def normalize
    super('coral spawn <node_provider> <image_id> <hostname> ...')
    
    codes :network_failure     => 20,
          :node_create_failure => 21
  end

  #-----------------------------------------------------------------------------
  # Action operations
  
  def parse(parser)
    parser.option_bool(:parallel, true, 
      '--[no-]parallel', 
      'coral.core.actions.spawn.options.parallel'
    )
    parser.option_str(:seed, "github:::coraltech/test[master]", 
      '--seed PROJECT_REFERENCE', 
      'coral.core.actions.spawn.options.seed'
    )
    parser.option_str(:region, nil, 
      '--region MACHINE_REGION', 
      'coral.core.actions.spawn.options.region'
    )
    parser.option_str(:machine_type, nil, 
      '--machine MACHINE_TYPE', 
      'coral.core.actions.spawn.options.machine_type'
    )
    parser.arg_str(:provider, nil,
      'coral.core.actions.spawn.options.provider'
    )
    parser.arg_str(:image, nil, 
      '--image IMAGE_NAME', 
      'coral.core.actions.spawn.options.image'
    )    
    parser.arg_array(:hostnames, nil, 
      'coral.core.actions.spawn.options.hostnames'
    )
    keypair_options(parser)
  end
  
  #---
   
  def execute
    super do |node, network, status|
      info('coral.core.actions.spawn.start')      
      
      if network
        Coral.batch(settings[:parallel]) do |op, batch|
          if op == :add
            # Add batch operations      
            settings[:hostnames].each do |hostname|
              batch.add(hostname) do
                node = network.add_node(settings[:provider], hostname, {
                  :private_key  => settings[:private_key],
                  :public_key   => settings[:public_key],
                  :region       => settings[:region],
                  :machine_type => settings[:machine_type],
                  :image        => settings[:image],
                  :seed         => settings[:seed]
                })
              
                dbg('we are done')
                            
                code.success                      
              end                           
            end
          else
            # Reduce to single status
            batch.each do |name, result|
              unless result == code.success
                status = code.batch_error
                break
              end
            end
          end
        end
      else
        status = code.network_failure    
      end
      status
    end
  end
end
end
end
