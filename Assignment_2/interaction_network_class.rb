class InteractionNetwork
  
  attr_accessor :nodes 
  attr_accessor :connections
  attr_accessor :gene_nodes
  
  def initialize (params = {})
    @connections = params.fetch(:connections, FALSE)
    @nodes = {}
    @gene_nodes = []
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
  

  def get_gnodes()

    @nodes.each_value do |node|
      @gene_nodes.push(node) if (node)
    end

  end


  def filter_singles(net)

    if @gene_nodes.length <= 1
      return FALSE
    else
      return TRUE
    end

  end


  def report(out_file)

    
    out_file.puts("#{@gene_nodes.length} genes from the list are interacting:")
    
    @gene_nodes.each do |gene|
      out_file.puts("Gene #{gene.gene_ID}: #{gene.prot_name}")

      out_file.puts("\tProtein IDs:")
      gene.proteins.each do |prot|
        out_file.puts("\t\t#{prot}")
      end

      out_file.puts("\tKegg pathways: ")
      gene.kegg_path.each_key do |key|
        out_file.puts("\t\t#{[key][0]}: #{gene.kegg_path[key]}")
      end

      out_file.puts("\tGO biological process:")
      gene.go_term.each_key do |key|
        out_file.puts("\t\t#{[key][0]}: #{gene.go_term[key]}")
      end

      out_file.puts()
    end

    out_file.puts("#{@connections}\n\n")

  end

  
end