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
    # This function finds out which proteins in the net come from the list of genes and saves the gene object
    # associated in a hash, the variable nodes. If the protein doesn't have a gene associated, it is assigned
    # the value FALSE.

    @connections.each_key do |key|

      # Nodes for the keys in the hash
      if (proteins.key?(key))
         @nodes[key] = proteins[key]  # Correspond to a gene in the list
      else
        @nodes[key] = FALSE  # The protein doesn't come from a gene of the list
      end

      # Nodes for the values
      @connections[key].each do |prot|

        if (nodes.key?(prot))
          next
        elsif (proteins.key?(prot))
          @nodes[prot] = proteins[prot]  # Correspond to a gene in the list
        else
          @nodes[prot] = FALSE  # The protein doesn't come from a gene of the list
        end
        
      end
    end
  end
  

  def get_gnodes()
    # This function saves in an array the gene objects of the proteins in the variable nodes

    @nodes.each_value do |node|
      @gene_nodes.push(node) if (node)
    end

  end


  def report(out_file)
    # This function prints in a file the characteristics of the genes interacting in the net
    
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