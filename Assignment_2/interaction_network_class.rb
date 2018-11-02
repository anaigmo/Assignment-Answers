class InteractionNetwork
  
  attr_accessor :nodes 
  attr_accessor :connections
  
  def initialize (params = {})
   @connections = params.fetch(:connections, FALSE)
   @nodes = {}
  end
 
  def get_nodes(proteins)
    
    @connections.each_key do |key|
      
      if (proteins.key?(key))
         @nodes[key] = proteins[key]  # Correspond to a gene in the list
      else
        @nodes[key] = FALSE  # The protein doesn't come from a gene of the list
      end
      
      @connections[key].each do |prot|
        
        if (proteins.key?(prot))
          @nodes[prot] = proteins[prot]
        else
          @nodes[prot] = FALSE  # The protein doesn't come from a gene of the list
        end
        
      end
      
    end
    
    print @nodes.keys
    puts;puts
    
  end
 
 
end