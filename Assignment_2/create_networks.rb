# This program has been created by Ana Iglesias Molina for the subject Bioinformatics Programming Challenges.
# Given a file with a list of genes of Arabidopsis thaliana, the interactions of their proteins are searched
# to create networks with two levels of depth. This networks are then written in the file 'Report.txt'.

require 'net/http'
require 'json'
require './gene_class.rb'
require './interaction_network_class.rb'


## ----- FUNCTIONS ----- ##

def create_genes(in_file)
  # This function creates instances of the class Gene from the lines in ArabidopsisSubNetwork_GeneList.txt
  
  return false unless (File.file?(in_file))  # Check that the file exists

  kegg_pathways = access_kegg("ath")  # Obtain the data from kegg for Arabidopsis thaliana

  print "Looking for proteins associated to genes... "

  list_genes = {}

  File.open(in_file, "r").each do |line|
    
    line = line.chomp
    new_gene = Gene.new(:gene_ID => line)  # Create the object
    new_gene.get_attributes(kegg_pathways)  # Annotate the gene with its proteins, GO terms and KEGG pathways
    list_genes[line] = new_gene  # Store the object in a hash, with the ID of the gene as key
    
  end
  
  puts "Done"
  return list_genes

end



def access_kegg(species)
  # This function gets the pathways of each gene in A. thaliana (as the array called paths) and its name (hash names)

  # Path for each gene in Arabidopsis thaliana
  address = URI("http://rest.kegg.jp/link/pathway/#{species}")
  response = Net::HTTP.get_response(address)
  paths = response.body.split("\n")

  # Name of each path
  address = URI("http://rest.kegg.jp/find/pathway/#{species}")
  response = Net::HTTP.get_response(address)
  data = response.body.split("\n")

  names = {}
  data.each do |line|
    elements = line.chomp.split("\t")
    names[elements[0]] = elements[1]
  end

  return [paths, names]

end
  
  
  
def access_tab25(id)
    # This function obtains the information of the interacion of a given protein (id) and returns the content
    # of the web page in tab25 format from IntAct in an array

    address = URI("http://www.ebi.ac.uk/Tools/webservices/psicquic/intact/webservices/current/search/query/#{id}?format=tab25")
    response = Net::HTTP.get_response(address)
    data = response.body.split("\n")
    return data

end



def get_connections(prot)
  # This function finds out the interactions of a given protein (prot) and returns them in an array with de proteins IDs

  tab25 = access_tab25(prot)  # Get te interacting information from IntAct
  
  interactions = []

  if tab25
     
    tab25.each do |int|

      column = int.split("\t")

      # Filter interactions by species and method of discovery of the interaction
      if column[9]=~/taxid:3702/ && column[10]=~/taxid:3702/ && (column[6]=~/MI:(0006|0007|0047|0055|0065|0084|0096|0402|0676|1356|0071|0112|0663)/)
        ids = []
        ids.push(column[0].split(":")[1])
        ids.push(column[1].split(":")[1])

        # The ID of the interacting protein can be in the first or the second column
        if ids[0] != prot && !interactions.include?(ids[0])
          interactions.push(ids[0])
        elsif ids[1] != prot && !interactions.include?(ids[1])
          interactions.push(ids[1])
        end
            
      end  
    end          
  end
      
  return interactions

end



def get_proteins(genes)
  # This function makes a hash that contains the protein IDs as keys, and their related gene as value

  proteins = {}

  genes.each_key do |key|
    
    genes[key].proteins.each do |prot|
      proteins[prot] = genes[key]
    end
  
  end

  return proteins

end



def create_networks(genes, proteins)
  # This function creates all the posible networks of all the genes whose proteins have interactions and returns them
  # on a hash that has as keys the gene_ID of the gene origin of the network

  # First, it finds out the interactions of the proteins of all the genes and keeps them in the hash called connections
  # This is, then, the first level of interactions
  print "Connecting proteins... "
  connections = {}
    
  genes.each_key do |key|

    next if genes[key].intact == []  # If in the search in togo api there are no interations, it doesn't look in the IntAct database
  
    genes[key].proteins.each do |prot|
      interactions = get_connections(prot)
      if (interactions != [])
        connections[prot] = interactions
        break
      end
    end
    
  end
  
  puts "Done"
  
  
  print "Looking for more interactions... "

  # Now it finds out the second level interactions: the interactions of the proteins interacting with the proteins of the gene list
  total_connections = {}  # All the interactions are kept in the same level in this hash

  connections.each_key do |key|
    total_connections[key] = connections[key] unless total_connections.key?(key)
    
    connections[key].each do |prot|
      if (total_connections.key?(prot))  # If the protein is already in the hash of all interactions
        next
      elsif (connections.key?(prot))  # If is one of the proteins from the gene list
        total_connections[prot] = connections[prot]
      else 
        interactions = get_connections(prot)  # If it's a new protein
        total_connections[prot] = interactions if (interactions != [])
      end  
    end
  end
  
  puts "Done"

  # Now, with all the interactions of two levels of depths, the networks are created
  networks = {}
  
  genes.each_key do |gene_id|
    
    new_net = {}
    
    genes[gene_id].proteins.each do |first|
      
      next unless (connections.key?(first))  # Control phase, if the protein is in the connection hash
      
      new_net[first] = total_connections[first] # First level connections
      
      connections[first].each do |second|
        new_net[second] = total_connections[second]  # Second level connections
      end
      
      networks[gene_id] = InteractionNetwork.new(:connections => new_net)  # Create object network
      networks[gene_id].get_nodes(proteins)  # Attributes
      networks[gene_id].get_gnodes  # Attributes
      
    end
  end
  
  return networks
  
end



def generate_report(networks)
  # This function prints the networks in a file called 'Report.txt'. It also filters the nets, as not everyone is valid

  out_file = File.open("Report.txt", "w")

  out_file.puts("FINAL REPORT\n\n")

  count = 0  # Count of the networks

  networks.each_value do |net|

    count += 1
    out_file.print("## NETWORK #{count}: ")
    net.report(out_file)  # Prints the characteristics of the genes interacting in the net

  end

  puts "A file called Report.txt has been created to contain the found networks"

end



def filter_nets(networks)
  # This function checks if a net contains other nets or there's only one gene in it and deletes it

  networks.each_value do |net|
    next if net.gene_nodes.length <= 1  # It will be deleted in the next step

    networks.each_key do |key|

      if net != networks[key] && (networks[key].gene_nodes.all? {|e| net.gene_nodes.include?(e)} || networks[key].gene_nodes.length <= 1)
        networks.delete(key)
      end

    end

  end

  return networks

end




## ----- MAIN ----- ##

abort("File missing. Please introduce a file with the Arabidopsis genes (ArabidopsisSubNetwork_GeneList.txt)") unless ARGV[0]

puts "This will take a few minutes, be patient :)"

genes = create_genes(ARGV[0])  # Create gene objects from the list in the file given

proteins = get_proteins(genes)  # Hash that contains the protein IDs as keys, and their related gene as value

networks = create_networks(genes, proteins)  # Find out the networks of interacting proteins with two levels of depth

networks = filter_nets(networks)  # Delete all the invalid networks

generate_report(networks)  # Prints the found networks in a file
