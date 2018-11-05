class InteractionNetwork
  
  attr_accessor :nodes 
  attr_accessor :connections
  
  def initialize (params = {})
   @connections = params.fetch(:connections, FALSE)
   @nodes = {}
  end
 
  def get_nodes(proteins)

    no_prots = []  ## hey
    @connections.each_key do |key|

      if (proteins.key?(key))
         @nodes[key] = proteins[key]  # Correspond to a gene in the list
      else
        @nodes[key] = FALSE  # The protein doesn't come from a gene of the list
      end

      @connections[key].each do |prot|
        no_prots.push(prot)
        if (nodes.key?(prot))
          next
        elsif (proteins.key?(prot))
          @nodes[prot] = proteins[prot]
        else
          @nodes[prot] = FALSE  # The protein doesn't come from a gene of the list
        end
        
      end
      
    end

  end
  

  def get_gnodes(net)
    gene_nodes = []

    net.nodes.each_key do |key|
      gene_nodes.push(nodes[key]) if (nodes[key])
    end

    return gene_nodes

  end


  def filter(net)
    gene_nodes = get_gnodes(net)

    if gene_nodes.length <= 1
      return FALSE
    else
      return TRUE
    end

  end


  def report(net)
    
    gene_nodes = get_gnodes(net)
    
    puts "#{gene_nodes.length} genes from the list are interacting:"
    
    gene_nodes.each do |gene|
      puts "Gene #{gene.gene_ID}: #{gene.prot_name}"
      #puts "\tKegg pathways: #{gene.kegg_path}"
      #puts "\tGO biological process: #{gene.GO_term}"
      puts
    end

    puts net.connections; puts; puts

  end
  
  
  
  
  
  
  
  
  
  
  
  
end