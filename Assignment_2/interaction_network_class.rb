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
        if (nodes.key?(prot))
          next
        elsif (proteins.key?(prot))
          @nodes[prot] = proteins[prot]
          puts "holi"
        else
          @nodes[prot] = FALSE  # The protein doesn't come from a gene of the list
        end
        
      end
      
    end
    puts @nodes; puts
  end
  
  
  
  def report(proteins, net)
    
    gene_nodes = []
    
    net.nodes.each_key do |key|
      gene_nodes.push(nodes[key]) if (nodes[key])
    end
    #puts gene_nodes.keys
    
    puts "#{gene_nodes.length} genes from the list are interacting:"
    
    gene_nodes.each do |gene|
      puts "Gene #{gene.gene_ID}: #{gene.prot_name}"
      #puts "\tKegg pathways: #{gene.kegg_path}"
      #puts "\tGO biological process: #{GO_term[0]}"
      puts
    end
    
  end
  
  
  
  
  
  
  
  
  
  
  
  
end